import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/testing.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient client;
  var counter = 0;

  setUp(() async {
    counter = 0;
    directory = await Directory.systemTemp.createTemp('commerce_pay');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await _seed(database);
    client = TestClient(
      buildApp(
        database,
        nextId: () => 'id_${++counter}',
        now: () => DateTime.utc(2026, 9, 5),
      ),
    );
  });

  tearDown(() async {
    await client.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<String> placedOrder() async {
    final created = await client.post('/store/carts').send();
    final cartId =
        CartView.fromJson(created.json! as Map<String, Object?>).cart.id;
    (await (client.post('/store/carts/$cartId/line-items')
              ..json({'variant_id': 'var_small', 'quantity': 1}))
            .send())
        .assertOk();
    (await (client.post('/store/carts/$cartId/shipping-method')
              ..json({'option_id': 'ship_standard'}))
            .send())
        .assertOk();
    (await (client.post('/store/carts/$cartId/payment-sessions')
              ..json({'provider_id': 'manual'}))
            .send())
        .assertOk();

    final placed = await (client.post('/store/checkout')
          ..json({
            'cart_id': cartId,
            'email': 'ada@example.com',
            'shipping_address': {
              'first_name': 'Ada',
              'last_name': 'Lovelace',
              'line1': '12 Analytical Way',
              'city': 'London',
              'postal_code': 'EC1A',
              'country_code': 'us',
            },
          }))
        .send();
    placed.assertCreated();
    return Order.fromJson(placed.json! as Map<String, Object?>).id;
  }

  Future<TestResponse> authorize(String orderId, {String? email}) => client
      .post(
        '/store/orders/$orderId/payments'
        '?email=${email ?? 'ada@example.com'}',
      )
      .send();

  Future<TestResponse> capture(String orderId, {String? email}) => client
      .post(
        '/store/orders/$orderId/payments/capture'
        '?email=${email ?? 'ada@example.com'}',
      )
      .send();

  group('POST /store/orders/{id}/payments', () {
    test('starts a payment for what the order says it owes', () async {
      final orderId = await placedOrder();

      (await authorize(orderId)).assertCreated();

      final rows = await queryRaw(
        'SELECT amount, status FROM payment_collections WHERE order_id = ?',
        [orderId],
      ).fetch(database.connection as Executor);

      expect(rows.single.readIndex<int>(0), 2199);
      expect(rows.single.readIndex<String>(1), 'authorized');
    });

    test('reuses a payment when authorization is retried', () async {
      final orderId = await placedOrder();
      (await authorize(orderId)).assertCreated();

      (await authorize(orderId)).assertCreated();
      final rows = await queryRaw(
        'SELECT COUNT(*) FROM payment_collections WHERE order_id = ?',
        [orderId],
      ).fetch(database.connection as Executor);
      expect(rows.single.readIndex<int>(0), 1);
    });

    test('will not let somebody else pay for an order they know the id of',
        () async {
      final orderId = await placedOrder();

      (await authorize(orderId, email: 'grace@example.com')).assertNotFound();
    });

    test('requires an email at all', () async {
      final orderId = await placedOrder();

      (await client.post('/store/orders/$orderId/payments').send())
          .assertBadRequest();
    });
  });

  group('POST /store/orders/{id}/payments/capture', () {
    test('captures, and completes the order', () async {
      final orderId = await placedOrder();
      (await authorize(orderId)).assertCreated();

      final response = await capture(orderId);

      response.assertOk();
      final order = Order.fromJson(response.json! as Map<String, Object?>);

      expect(order.paymentStatus, PaymentStatus.captured);
      expect(order.status, OrderStatus.completed);
      expect(order.isPaid, isTrue);
    });

    test('the completed state is persisted', () async {
      final orderId = await placedOrder();
      await authorize(orderId);
      await capture(orderId);

      final rows = await queryRaw(
        'SELECT status, payment_status FROM orders WHERE id = ?',
        [orderId],
      ).fetch(database.connection as Executor);
      expect(rows.single.readIndex<String>(0), 'completed');
      expect(rows.single.readIndex<String>(1), 'captured');
    });

    test('returns the completed order when capture is retried', () async {
      final orderId = await placedOrder();
      await authorize(orderId);
      (await capture(orderId)).assertOk();

      final retried = await capture(orderId);
      retried.assertOk();
      final order = Order.fromJson(retried.json! as Map<String, Object?>);
      expect(order.paymentStatus, PaymentStatus.captured);
      expect(order.status, OrderStatus.completed);
    });

    test('refuses to capture what was never authorised', () async {
      final orderId = await placedOrder();

      (await capture(orderId)).assertConflict();
    });

    test("will not capture somebody else's order", () async {
      final orderId = await placedOrder();
      await authorize(orderId);

      (await capture(orderId, email: 'grace@example.com')).assertNotFound();
    });
  });
}

Future<void> _seed(CommerceDatabase database) async {
  Future<void> run(String sql) =>
      queryExecute(sql, []).execute(database.executor);

  await run(
    r"INSERT INTO regions (id, name, currency_code, tax_rate, countries) "
    r"VALUES ('reg_us', 'United States', 'usd', 1000, 'us')",
  );
  await run(
    r"INSERT INTO region_payment_providers (region_id, provider_id) "
    r"VALUES ('reg_us', 'manual')",
  );
  await run(
    r"INSERT INTO shipping_options (id, region_id, name, amount, currency_code) "
    r"VALUES ('ship_standard', 'reg_us', 'Standard', 0, 'usd')",
  );
  await run(
    r"INSERT INTO products (id, title, handle, status) VALUES "
    r"('prod_shirt', 'T-Shirt', 't-shirt', 'published')",
  );
  await run(
    r"INSERT INTO product_variants "
    r"(id, product_id, title, inventory_quantity) VALUES "
    r"('var_small', 'prod_shirt', 'Small', 50)",
  );
  await run(
    r"INSERT INTO variant_prices (variant_id, currency_code, amount) VALUES "
    r"('var_small', 'usd', 1999)",
  );
}
