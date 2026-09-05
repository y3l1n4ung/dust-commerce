import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/testing.dart';
import 'package:test/test.dart';

import 'read_support.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient client;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_taxonomy');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await seedCatalogRead(database);
    client = TestClient(buildApp(database));
  });

  tearDown(() async {
    await client.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  test('lists and filters public collections', () async {
    final response =
        await client.get('/store/collections?handle=summer').send();

    response.assertOk();
    final view = ProductCollectionListView.fromJson(
      response.json! as Map<String, Object?>,
    );
    expect(view.count, 1);
    expect(view.collections.single.handle, 'summer');
  });

  test('lists active category hierarchy nodes', () async {
    final response = await client
        .get('/store/product-categories?handle=clothing%2Fshirts')
        .send();

    response.assertOk();
    final view = ProductCategoryListView.fromJson(
      response.json! as Map<String, Object?>,
    );
    expect(view.count, 1);
    expect(view.categories.single.name, 'Shirts');
    expect(view.categories.single.parentId, 'cat_clothing');
  });

  test('filters product pages by collection, category and tag', () async {
    for (final query in [
      'collection=summer',
      'category=clothing%2Fshirts',
      'tag=cotton',
    ]) {
      final response = await client.get('/store/products?$query').send();
      response.assertOk();
      final view = ProductPageView.fromJson(
        response.json! as Map<String, Object?>,
      );
      expect(view.products.map((product) => product.handle), ['t-shirt']);
      expect(view.total, 1);
    }
  });

  test('unknown filters return an empty page without leaking drafts', () async {
    final response =
        await client.get('/store/products?category=unknown').send();

    response.assertOk();
    final view = ProductPageView.fromJson(
      response.json! as Map<String, Object?>,
    );
    expect(view.products, isEmpty);
    expect(view.total, 0);
  });
}
