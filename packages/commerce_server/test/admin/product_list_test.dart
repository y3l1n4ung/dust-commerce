import 'package:test/test.dart';

import 'support.dart';

void main() {
  late AdminHarness harness;

  setUp(() async => harness = await AdminHarness.start(seedStore: true));
  tearDown(() => harness.stop());

  test('product list requires a proven admin bearer', () async {
    (await harness.client.get('/admin/products').send()).assertUnauthorized();
  });

  test('product list exposes only table fields and active variant counts',
      () async {
    final token = await harness.adminToken();
    final request = harness.client.get('/admin/products?limit=2&offset=0')
      ..bearer(token);
    final response = await request.send();

    response.assertOk();
    final json = response.json! as Map<String, Object?>;
    expect(json['count'], 4);
    expect(json['limit'], 2);
    expect(json['offset'], 0);
    final products = json['products']! as List<Object?>;
    expect(products, hasLength(2));
    final first = products.first! as Map<String, Object?>;
    expect(first.keys, {
      'collection_title',
      'id',
      'sales_channels',
      'status',
      'thumbnail',
      'title',
      'variant_count',
    });
    expect(first['variant_count'], greaterThan(0));
    expect(first, isNot(contains('description')));
    expect(first, isNot(contains('metadata')));
  });

  test('product list searches title or handle case-insensitively', () async {
    final token = await harness.adminToken();
    final request = harness.client.get('/admin/products?q=SWEAT&limit=20')
      ..bearer(token);
    final response = await request.send();

    response.assertOk();
    final json = response.json! as Map<String, Object?>;
    expect(json['count'], 2);
    final products = json['products']! as List<Object?>;
    expect(
      products.map((value) => (value! as Map<String, Object?>)['title']),
      containsAll(['Vintage Sweatshirt', 'Relaxed Sweatpants']),
    );
  });
}
