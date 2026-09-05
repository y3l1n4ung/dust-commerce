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
      final result = await lists.listPublished('usd', 10, 0, null, null, null);
      final handles = ok(result).map((row) => row.handle);

      expect(handles, ['mug', 't-shirt']);
      expect(handles, isNot(contains('secret-hoodie')));
    });

    test('pages, so a large catalogue does not arrive at once', () async {
      final first = await lists.listPublished('usd', 1, 0, null, null, null);
      final second = await lists.listPublished('usd', 1, 1, null, null, null);

      expect(ok(first).single.handle, 'mug');
      expect(ok(second).single.handle, 't-shirt');
    });

    test('counts what it would page through', () async {
      expect(ok(await lists.countPublished(null, null, null)), 2);
    });

    test('filters by collection, category and tag', () async {
      final byCollection =
          await lists.listPublished('usd', 10, 0, 'summer', null, null);
      final byCategory =
          await lists.listPublished('usd', 10, 0, null, 'shirts', null);
      final byTag =
          await lists.listPublished('usd', 10, 0, null, null, 'Cotton');

      expect(ok(byCollection).map((row) => row.handle), ['t-shirt']);
      expect(ok(byCategory).map((row) => row.handle), ['t-shirt']);
      expect(ok(byTag).map((row) => row.handle), ['t-shirt']);
    });
  });

  group('findByHandle', () {
    test('finds a published product', () async {
      final row = ok(await reads.findByHandle('t-shirt', 'usd'));

      expect(row?.title, 'T-Shirt');
      expect(row?.status, 'published');
      expect(row?.variants.map((variant) => variant.id), [
        'var_large',
        'var_small',
      ]);
      expect(
        row?.variants.map((variant) => variant.prices.single.amount),
        [2199, 1999],
      );
      expect(row?.images, [
        'https://example.test/front.png',
        'https://example.test/back.png',
      ]);
    });

    test('does not leak a draft, even to a caller who knows the handle',
        () async {
      expect(ok(await reads.findByHandle('secret-hoodie', 'usd')), isNull);
    });

    test('returns null for a handle nobody has', () async {
      expect(ok(await reads.findByHandle('nothing', 'usd')), isNull);
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
    r"INSERT INTO product_collections (id, title, handle) VALUES "
    r"('col_summer', 'Summer', 'summer')",
  );
  await run(
    r"INSERT INTO products (id, collection_id, title, handle, status) VALUES "
    r"('prod_shirt', 'col_summer', 'T-Shirt', 't-shirt', 'published'), "
    r"('prod_mug', NULL, 'Mug', 'mug', 'published'), "
    r"('prod_secret', NULL, 'Hoodie', 'secret-hoodie', 'draft')",
  );
  await run(
    r"INSERT INTO product_categories (id, name, handle) VALUES "
    r"('cat_shirts', 'Shirts', 'shirts')",
  );
  await run(
    r"INSERT INTO product_category_products (product_id, category_id) VALUES "
    r"('prod_shirt', 'cat_shirts')",
  );
  await run(
    r"INSERT INTO product_tags (id, value) VALUES "
    r"('tag_cotton', 'Cotton')",
  );
  await run(
    r"INSERT INTO product_tag_products (product_id, tag_id) VALUES "
    r"('prod_shirt', 'tag_cotton')",
  );
  await run(
    r"INSERT INTO product_variants "
    r"(id, product_id, title, inventory_quantity) VALUES "
    r"('var_small', 'prod_shirt', 'Small', 5), "
    r"('var_large', 'prod_shirt', 'Large', 2)",
  );
  await run(
    r"INSERT INTO product_images (id, product_id, url, rank) VALUES "
    r"('img_back', 'prod_shirt', 'https://example.test/back.png', 1), "
    r"('img_front', 'prod_shirt', 'https://example.test/front.png', 0)",
  );
  await run(
    r"INSERT INTO variant_prices (variant_id, currency_code, amount) VALUES "
    r"('var_small', 'usd', 1999), "
    r"('var_large', 'usd', 2199), "
    r"('var_small', 'eur', 1799)",
  );
}
