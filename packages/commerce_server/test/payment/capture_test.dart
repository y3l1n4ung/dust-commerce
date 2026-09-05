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
              'country_code': 'gb',
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

    test('refuses a second payment on the same order', () async {
      final orderId = await placedOrder();
      (await authorize(orderId)).assertCreated();

      (await authorize(orderId)).assertConflict();
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

    test('the order stays captured when read back', () async {
      final orderId = await placedOrder();
      await authorize(orderId);
      await capture(orderId);

      final read = await client
          .get('/store/orders/$orderId?email=ada@example.com')
          .send();
      final order = Order.fromJson(read.json! as Map<String, Object?>);

      expect(order.isPaid, isTrue);
      expect(order.status, OrderStatus.completed);
    });

    test('refuses to capture twice, rather than charging twice', () async {
      final orderId = await placedOrder();
      await authorize(orderId);
      (await capture(orderId)).assertOk();

      (await capture(orderId)).assertConflict();
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
