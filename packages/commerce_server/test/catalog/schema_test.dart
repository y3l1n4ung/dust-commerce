import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:test/test.dart';

/// Raw SQL access, which `fetch` needs and `DatabaseClient.executor` is not.
///
/// `DatabaseConnection` implements `DatabaseExecutor`; a raw query wants the
/// wider `Executor`, which the driver behind it does provide.
extension on CommerceDatabase {
  Executor get raw => connection as Executor;
}

void main() {
  late Directory directory;
  late CommerceDatabase database;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_schema');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<List<String>> columnsOf(String table) async {
    final rows =
        await queryRaw('PRAGMA table_info($table)', []).fetch(database.raw);
    return rows.map((row) => row.readIndex<String>(1)).toList();
  }

  group('migrations', () {
    test('create every table the slice needs', () async {
      final rows = await queryRaw(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
        [],
      ).fetch(database.raw);
      final tables = rows.map((row) => row.readIndex<String>(0)).toSet();

      expect(
        tables,
        containsAll(<String>[
          'carts',
          'customers',
          'line_items',
          'order_addresses',
          'order_items',
          'orders',
          'product_options',
          'product_variants',
          'products',
          'regions',
          'variant_option_values',
          'variant_prices',
        ]),
      );
    });

    test('are idempotent, so a second open does not reapply them', () async {
      await database.close();

      final reopened = CommerceDatabase.open(
        '${directory.path}/commerce.db',
        options: commerceOptions,
      );
      addTearDown(reopened.close);

      final rows = await queryRaw('SELECT COUNT(*) FROM products', [])
          .fetch(reopened.raw);

      expect(rows.single.readIndex<int>(0), 0);
    });
  });

  group('the shape money is stored in', () {
    test('prices are integer minor units, keyed by variant and currency',
        () async {
      final columns = await columnsOf('variant_prices');

      expect(columns, containsAll(<String>['variant_id', 'currency_code']));
      expect(columns, contains('amount'));
    });

    test('an order stores its totals rather than deriving them', () async {
      final columns = await columnsOf('orders');

      expect(columns, containsAll(<String>['subtotal', 'tax', 'total']));
    });
  });

  group('the constraints that protect the domain', () {
    test('a variant cannot hold two prices in one currency', () async {
      await _seedVariant(database);
      await queryExecute(
        'INSERT INTO variant_prices (variant_id, currency_code, amount) '
        r"VALUES ('var_1', 'usd', 1999)",
        [],
      ).execute(database.executor);

      Future<void> duplicate() => queryExecute(
            'INSERT INTO variant_prices (variant_id, currency_code, amount) '
            r"VALUES ('var_1', 'usd', 2999)",
            [],
          ).execute(database.executor);

      await expectLater(duplicate, throwsStateError);
    });

    test('a line cannot be ordered at a quantity of zero', () async {
      await _seedVariant(database);
      await queryExecute(
        r"INSERT INTO regions (id, name, currency_code, tax_rate, countries) "
        r"VALUES ('reg_1', 'US', 'usd', 0, 'us')",
        [],
      ).execute(database.executor);
      await queryExecute(
        r"INSERT INTO carts (id, region_id, created_at) "
        r"VALUES ('cart_1', 'reg_1', '2026-09-05')",
        [],
      ).execute(database.executor);

      Future<void> zeroQuantity() => queryExecute(
            'INSERT INTO line_items (id, cart_id, variant_id, product_id, '
            'title, unit_amount, currency_code, quantity) '
            r"VALUES ('li_1', 'cart_1', 'var_1', 'prod_1', 'T', 1999, 'usd', 0)",
            [],
          ).execute(database.executor);

      await expectLater(zeroQuantity, throwsStateError);
    });

    test('a handle cannot be reused, because the storefront routes on it',
        () async {
      await _seedVariant(database);

      Future<void> reusedHandle() => queryExecute(
            r"INSERT INTO products (id, title, handle) "
            r"VALUES ('prod_2', 'Other', 't-shirt')",
            [],
          ).execute(database.executor);

      await expectLater(reusedHandle, throwsStateError);
    });
  });
}

Future<void> _seedVariant(CommerceDatabase database) async {
  await queryExecute(
    r"INSERT INTO products (id, title, handle, status) "
    r"VALUES ('prod_1', 'T-Shirt', 't-shirt', 'published')",
    [],
  ).execute(database.executor);
  await queryExecute(
    r"INSERT INTO product_variants (id, product_id, title, inventory_quantity) "
    r"VALUES ('var_1', 'prod_1', 'Small', 5)",
    [],
  ).execute(database.executor);
}
