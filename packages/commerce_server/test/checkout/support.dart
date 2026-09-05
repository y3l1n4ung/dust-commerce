import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:dust_server/testing.dart';

/// A running API with a seeded database, torn down after the test.
///
/// Shared by the checkout suites so each one holds only the behaviour it is
/// about. Identifiers and the clock are fixed, so an assertion can name an
/// order id instead of working around one.
final class CheckoutHarness {
  CheckoutHarness._(this._directory, this.database, this.client);

  /// Opens a database, seeds it, and serves the app in process.
  static Future<CheckoutHarness> start() async {
    final directory = await Directory.systemTemp.createTemp('commerce_co');
    final database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await _seed(database);

    var counter = 0;
    final client = TestClient(
      buildApp(
        database,
        nextId: () => 'id_${++counter}',
        now: () => DateTime.utc(2026, 9, 5, 12),
      ),
    );

    return CheckoutHarness._(directory, database, client);
  }

  final Directory _directory;

  /// The open database, for assertions that read rows directly.
  final CommerceDatabase database;

  /// The API under test.
  final TestClient client;

  /// Closes everything this harness opened.
  Future<void> stop() async {
    await client.close();
    await database.close();
    await _directory.delete(recursive: true);
  }

  /// A well-formed shipping address, optionally broken in one field.
  Map<String, Object?> address({String firstName = 'Ada'}) => {
        'first_name': firstName,
        'last_name': 'Lovelace',
        'line1': '12 Analytical Way',
        'city': 'London',
        'postal_code': 'EC1A',
        'country_code': 'gb',
      };

  /// Starts a cart holding [quantity] of [variantId].
  Future<String> cartWith(String variantId, {int quantity = 1}) async {
    final created = await client.post('/store/carts').send();
    final cartId = (created.json! as Map<String, Object?>)['id']! as String;
    (await (client.post('/store/carts/$cartId/line-items')
              ..json({'variant_id': variantId, 'quantity': quantity}))
            .send())
        .assertOk();
    return cartId;
  }

  /// Places [cartId] as an order.
  Future<TestResponse> checkout(
    String cartId, {
    String email = 'ada@example.com',
    Map<String, Object?>? shipping,
  }) {
    return (client.post('/store/checkout')
          ..json({
            'cart_id': cartId,
            'email': email,
            'shipping_address': shipping ?? address(),
          }))
        .send();
  }

  /// The stock on hand for [variantId], read straight from the table.
  Future<int> stockOf(String variantId) async {
    final rows = await queryRaw(
      'SELECT inventory_quantity FROM product_variants WHERE id = ?',
      [variantId],
    ).fetch(database.connection as Executor);
    return rows.single.readIndex<int>(0);
  }
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
