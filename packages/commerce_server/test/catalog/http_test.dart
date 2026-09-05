import 'dart:io';

import 'package:commerce_server/commerce_server.dart';
import 'package:commerce_shared/commerce_shared.dart';
import 'package:dust_server/testing.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CommerceDatabase database;
  late TestClient client;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('commerce_http');
    database = CommerceDatabase.open(
      '${directory.path}/commerce.db',
      options: commerceOptions,
    );
    await _seed(database);
    client = TestClient(buildApp(database));
  });

  tearDown(() async {
    await client.close();
    await database.close();
    await directory.delete(recursive: true);
  });

  group('GET /health', () {
    test('answers ok', () async {
      (await client.get('/health').send())
        ..assertOk()
        ..assertJson({'status': 'ok'});
    });
  });

  group('GET /store/products', () {
    test('lists published products with their totals', () async {
      final response = await client.get('/store/products').send();

      response
        ..assertOk()
        ..assertJsonContains({'total': 2, 'count': 2, 'offset': 0});
    });

    test('never lists a draft', () async {
      final response = await client.get('/store/products').send();
      final body = response.json! as Map<String, Object?>;
      final products = body['products']! as List<Object?>;
      final handles = products
          .map((it) => (it! as Map<String, Object?>)['handle'])
          .toList();

      expect(handles, ['mug', 't-shirt']);
      expect(handles, isNot(contains('secret-hoodie')));
    });

    test('pages when asked', () async {
      final response =
          await client.get('/store/products?limit=1&offset=1').send();

      response
        ..assertOk()
        ..assertJsonContains({'count': 1, 'limit': 1, 'offset': 1, 'total': 2});
    });

    test('caps a limit nobody should be allowed to ask for', () async {
      final response = await client.get('/store/products?limit=1000000').send();

      response
        ..assertOk()
        ..assertJsonContains({'limit': maxLimit});
    });

    test('falls back rather than failing on a nonsense limit', () async {
      final response = await client.get('/store/products?limit=abc').send();

      response
        ..assertOk()
        ..assertJsonContains({'limit': defaultLimit});
    });

    test('prices in the currency asked for', () async {
      final response = await client.get('/store/products?currency=eur').send();
      final body = response.json! as Map<String, Object?>;
      final products = body['products']! as List<Object?>;
      final shirt = products
          .map((it) => Product.fromJson(it! as Map<String, Object?>))
          .firstWhere((product) => product.handle == 't-shirt');

      expect(shirt.cheapestIn('eur'), Money.of(1799, 'eur'));
      expect(shirt.cheapestIn('usd'), isNull);
    });
  });

  group('GET /store/products/{handle}', () {
    test('returns one product, decodable by the shared model', () async {
      final response = await client.get('/store/products/t-shirt').send();

      response.assertOk();
      final product = Product.fromJson(response.json! as Map<String, Object?>);

      expect(product.title, 'T-Shirt');
      expect(product.variants, hasLength(2));
      expect(product.cheapestIn('usd'), Money.of(1999, 'usd'));
      expect(product.isPurchasable, isTrue);
    });

    test('answers 404 for a draft, not 403, so nothing leaks', () async {
      (await client.get('/store/products/secret-hoodie').send())
        ..assertNotFound()
        ..assertJsonContains({
          'error': {
            'code': 'not_found',
            'message': 'Product "secret-hoodie" was not found',
          },
        });
    });

    test('answers 404 for a handle nobody has', () async {
      (await client.get('/store/products/nothing').send()).assertNotFound();
    });
  });

  group('over real HTTP', () {
    test('answers the same as it does in process', () async {
      final served = await TestClient.serve(buildApp(database));
      addTearDown(served.close);

      (await served.get('/store/products/t-shirt').send())
        ..assertOk()
        ..assertHeader('content-type', 'application/json');
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
