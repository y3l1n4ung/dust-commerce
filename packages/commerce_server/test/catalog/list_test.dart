import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:test/test.dart';

/// The value of a successful query, or a failure naming the error.
///
/// `Result` is sealed and carries no bare `unwrap`, which is the right default
/// for production code and too ceremonious for a test that wants the value or
/// wants to stop.
T ok<T>(Result<T, SqlxError> result) => switch (result) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('query failed: $error'),
    };

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late CatalogListRepository lists;
  late CatalogReadRepository reads;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_repo');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    lists = CatalogListRepository(database.executor);
    reads = CatalogReadRepository(database.executor);
    await _seed(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  group('listPublished', () {
    test('returns only published products', () async {
      final result = await lists.listPublished(10, 0);
      final handles = ok(result).map((row) => row.handle);

      expect(handles, ['mug', 't-shirt']);
      expect(handles, isNot(contains('secret-hoodie')));
    });

    test('pages, so a large catalogue does not arrive at once', () async {
      final first = await lists.listPublished(1, 0);
      final second = await lists.listPublished(1, 1);

      expect(ok(first).single.handle, 'mug');
      expect(ok(second).single.handle, 't-shirt');
    });

    test('counts what it would page through', () async {
      expect(ok(await lists.countPublished()), 2);
    });
  });

  group('findByHandle', () {
    test('finds a published product', () async {
      final row = ok(await reads.findByHandle('t-shirt'));

      expect(row?.title, 'T-Shirt');
      expect(row?.status, 'published');
    });

    test('does not leak a draft, even to a caller who knows the handle',
        () async {
      expect(ok(await reads.findByHandle('secret-hoodie')), isNull);
    });

    test('returns null for a handle nobody has', () async {
      expect(ok(await reads.findByHandle('nothing')), isNull);
    });
  });

  group('variantsOf', () {
    test('returns the variants priced in the asked-for currency', () async {
      final rows = ok(await lists.variantsOf('prod_shirt', 'usd'));

      expect(rows, hasLength(2));
      expect(rows.map((row) => row.id), ['var_large', 'var_small']);
      expect(rows.map((row) => row.amount), [2199, 1999]);
      expect(rows.every((row) => row.currencyCode == 'usd'), isTrue);
    });

    test('drops a variant with no price in that currency', () async {
      final rows = ok(await lists.variantsOf('prod_shirt', 'eur'));

      expect(rows, hasLength(1));
      expect(rows.single.id, 'var_small');
    });

    test('returns nothing for a currency nobody is priced in', () async {
      expect(ok(await lists.variantsOf('prod_shirt', 'gbp')), isEmpty);
    });
  });

  group('findVariant', () {
    test('finds one variant with its price', () async {
      final row = ok(await reads.findVariant('var_small', 'usd'));

      expect(row?.amount, 1999);
      expect(row?.inventoryQuantity, 5);
    });

    test('returns null when the variant is not sold in that currency',
        () async {
      expect(ok(await reads.findVariant('var_large', 'eur')), isNull);
    });
  });
}

Future<void> _seed(CommerceDatabase database) async {
  Future<void> run(String sql) =>
      queryExecute(sql, []).execute(database.executor);

  await run(
    r"INSERT INTO products (id, title, handle, status) VALUES "
    r"('prod_shirt', 'T-Shirt', 't-shirt', 'published'), "
    r"('prod_mug', 'Mug', 'mug', 'published'), "
    r"('prod_secret', 'Hoodie', 'secret-hoodie', 'draft')",
  );
  await run(
    r"INSERT INTO product_variants "
    r"(id, product_id, title, inventory_quantity) VALUES "
    r"('var_small', 'prod_shirt', 'Small', 5), "
    r"('var_large', 'prod_shirt', 'Large', 2)",
  );
  await run(
    r"INSERT INTO variant_prices (variant_id, currency_code, amount) VALUES "
    r"('var_small', 'usd', 1999), "
    r"('var_large', 'usd', 2199), "
    r"('var_small', 'eur', 1799)",
  );
}
