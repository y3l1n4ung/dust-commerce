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
    directory = await Directory.systemTemp.createTemp('commerce_checkout');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await _seed(database);
    client = TestClient(
      buildApp(
        database,
        nextId: () => 'id_${++counter}',
        now: () => DateTime.utc(2026, 9, 5, 12),
      ),
    );
  });

  tearDown(() async {
    await client.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  Map<String, Object?> address({String firstName = 'Ada'}) => {
        'first_name': firstName,
        'last_name': 'Lovelace',
        'line1': '12 Analytical Way',
        'city': 'London',
        'postal_code': 'EC1A',
        'country_code': 'gb',
      };

  Future<String> cartWith(String variantId, {int quantity = 1}) async {
    final created = await client.post('/store/carts').send();
    final cartId = (created.json! as Map<String, Object?>)['id']! as String;
    (await (client.post('/store/carts/$cartId/line-items')
              ..json({'variant_id': variantId, 'quantity': quantity}))
            .send())
        .assertOk();
    return cartId;
  }

  Future<TestResponse> checkout(
    String cartId, {
    String email = 'ada@example.com',
    Map<String, Object?>? shipping,
  }) async {
    return (client.post('/store/checkout')
          ..json({
            'cart_id': cartId,
            'email': email,
            'shipping_address': shipping ?? address(),
          }))
        .send();
  }

  group('POST /store/checkout', () {
    test('turns a cart into an order with frozen totals', () async {
      final cartId = await cartWith('var_small', quantity: 2);

      final response = await checkout(cartId);

      response.assertCreated();
      final order = Order.fromJson(response.json! as Map<String, Object?>);

      expect(order.items, hasLength(1));
      expect(order.subtotal, Money.of(3998, 'usd'));
      expect(order.tax, Money.of(400, 'usd'));
      expect(order.total, Money.of(4398, 'usd'));
      expect(order.status, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.awaiting);
    });

    test('takes the stock it sold', () async {
      final cartId = await cartWith('var_large', quantity: 2);

      (await checkout(cartId)).assertCreated();

      final rows = await queryRaw(
        r"SELECT inventory_quantity FROM product_variants WHERE id = 'var_large'",
        [],
      ).fetch(database.connection as Executor);

      expect(rows.single.readIndex<int>(0), 0);
    });

    test('empties the cart it ordered', () async {
      final cartId = await cartWith('var_small');

      (await checkout(cartId)).assertCreated();

      final response = await client.get('/store/carts/$cartId').send();
      final cart = Cart.fromJson(response.json! as Map<String, Object?>);

      expect(cart.isEmpty, isTrue);
    });

    test('answers 409 when something sold out first, and takes no stock',
        () async {
      final mine = await cartWith('var_large', quantity: 2);
      final theirs = await cartWith('var_large', quantity: 2);

      (await checkout(theirs)).assertCreated();
      (await checkout(mine)).assertConflict();

      final rows = await queryRaw(
        r"SELECT inventory_quantity FROM product_variants WHERE id = 'var_large'",
        [],
      ).fetch(database.connection as Executor);

      expect(rows.single.readIndex<int>(0), 0);
    });

    test('leaves no order behind when it refuses', () async {
      final mine = await cartWith('var_large', quantity: 2);
      final theirs = await cartWith('var_large', quantity: 2);

      (await checkout(theirs)).assertCreated();
      (await checkout(mine, email: 'loser@example.com')).assertConflict();

      final response =
          await client.get('/store/orders?email=loser@example.com').send();

      response
        ..assertOk()
        ..assertJsonContains({'count': 0});
    });

    test('answers 404 for a cart nobody started', () async {
      (await checkout('nope')).assertNotFound();
    });

    test('answers 422 for an empty cart', () async {
      final created = await client.post('/store/carts').send();
      final cartId = (created.json! as Map<String, Object?>)['id']! as String;

      (await checkout(cartId)).assertUnprocessable();
    });

    test('rejects an invalid email with the field that failed', () async {
      final cartId = await cartWith('var_small');

      final response = await checkout(cartId, email: 'not-an-email');

      response
        ..assertUnprocessable()
        ..assertTextContains('validation_failed')
        ..assertTextContains('email');
    });

    test('rejects an address missing its recipient', () async {
      final cartId = await cartWith('var_small');

      final response = await checkout(cartId, shipping: address(firstName: ''));

      response.assertUnprocessable();
    });
  });

  group('GET /store/orders', () {
    test('lists only the orders of the email that asks', () async {
      final mine = await cartWith('var_small');
      (await checkout(mine, email: 'ada@example.com')).assertCreated();

      final theirs = await cartWith('var_small');
      (await checkout(theirs, email: 'grace@example.com')).assertCreated();

      (await client.get('/store/orders?email=ada@example.com').send())
        ..assertOk()
        ..assertJsonContains({'count': 1});
    });

    test('requires an email rather than listing everything', () async {
      (await client.get('/store/orders').send()).assertBadRequest();
    });
  });

  group('GET /store/orders/{id}', () {
    test('returns the order to the address that placed it', () async {
      final cartId = await cartWith('var_small');
      final placed = await checkout(cartId);
      final id = (placed.json! as Map<String, Object?>)['id']! as String;

      final response =
          await client.get('/store/orders/$id?email=ada@example.com').send();

      response.assertOk();
      final order = Order.fromJson(response.json! as Map<String, Object?>);

      expect(order.id, id);
      expect(order.shippingAddress.city, 'London');
      expect(order.billingAddress, order.shippingAddress);
    });

    test('will not hand an order to somebody else who knows the id', () async {
      final cartId = await cartWith('var_small');
      final placed = await checkout(cartId);
      final id = (placed.json! as Map<String, Object?>)['id']! as String;

      (await client.get('/store/orders/$id?email=grace@example.com').send())
          .assertNotFound();
    });

    test('requires an email at all', () async {
      final cartId = await cartWith('var_small');
      final placed = await checkout(cartId);
      final id = (placed.json! as Map<String, Object?>)['id']! as String;

      (await client.get('/store/orders/$id').send()).assertBadRequest();
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
    r"('var_small', 'prod_shirt', 'Small', 50), "
    r"('var_large', 'prod_shirt', 'Large', 2)",
  );
  await run(
    r"INSERT INTO variant_prices (variant_id, currency_code, amount) VALUES "
    r"('var_small', 'usd', 1999), "
    r"('var_large', 'usd', 2199)",
  );
}
