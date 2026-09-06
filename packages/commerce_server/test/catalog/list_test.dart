import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:test/test.dart';

import 'list_support.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late CatalogCountRepository counts;
  late CatalogListRepository lists;
  late CatalogReadRepository reads;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_repo');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    counts = CatalogCountRepository(database.executor);
    lists = CatalogListRepository(database.executor);
    reads = CatalogReadRepository(database.executor);
    await seedCatalogList(database);
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  group('listPublished', () {
    test('returns only published products', () async {
      final result =
          await lists.listPublished('usd', 10, 0, null, null, null, '[]');
      final handles = ok(result).map((row) => row.handle);

      expect(handles, ['mug', 't-shirt']);
      expect(handles, isNot(contains('secret-hoodie')));
    });

    test('pages, so a large catalogue does not arrive at once', () async {
      final first =
          await lists.listPublished('usd', 1, 0, null, null, null, '[]');
      final second =
          await lists.listPublished('usd', 1, 1, null, null, null, '[]');

      expect(ok(first).single.handle, 'mug');
      expect(ok(second).single.handle, 't-shirt');
    });

    test('counts what it would page through', () async {
      expect(ok(await counts.countPublished('usd', null, null, null, '[]')), 2);
    });

    test('filters by collection, category and tag', () async {
      final byCollection =
          await lists.listPublished('usd', 10, 0, 'summer', null, null, '[]');
      final byCategory =
          await lists.listPublished('usd', 10, 0, null, 'shirts', null, '[]');
      final byTag =
          await lists.listPublished('usd', 10, 0, null, null, 'Cotton', '[]');

      expect(ok(byCollection).map((row) => row.handle), ['t-shirt']);
      expect(ok(byCategory).map((row) => row.handle), ['t-shirt']);
      expect(ok(byTag).map((row) => row.handle), ['t-shirt']);
    });

    test('filters by stable option value id', () async {
      final matching = await lists.listPublished(
        'usd',
        10,
        0,
        null,
        null,
        null,
        '["optval_large"]',
      );
      final missing = await lists.listPublished(
        'usd',
        10,
        0,
        null,
        null,
        null,
        '["not-a-value"]',
      );

      expect(ok(matching).map((row) => row.handle), ['t-shirt']);
      expect(ok(missing), isEmpty);
      expect(
        ok(await counts.countPublished(
          'usd',
          null,
          null,
          null,
          '["optval_large"]',
        )),
        1,
      );
    });

    test('excludes products and option choices unavailable in the currency',
        () async {
      final eur =
          await lists.listPublished('eur', 10, 0, null, null, null, '[]');
      final unavailableChoice = await lists.listPublished(
        'eur',
        10,
        0,
        null,
        null,
        null,
        '["optval_large"]',
      );

      expect(ok(eur).map((row) => row.handle), ['t-shirt']);
      expect(ok(eur).single.variants.map((variant) => variant.id), [
        'var_small',
      ]);
      expect(ok(unavailableChoice), isEmpty);
      expect(ok(await counts.countPublished('eur', null, null, null, '[]')), 1);
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
      expect(row?.images.map((image) => image.url), [
        'https://example.test/front.png',
        'https://example.test/back.png',
      ]);
      expect(
        row?.variants
            .singleWhere((variant) => variant.id == 'var_large')
            .images
            .map((image) => image.id),
        ['img_front'],
      );
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
