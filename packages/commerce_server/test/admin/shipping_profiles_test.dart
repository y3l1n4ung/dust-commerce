import 'package:test/test.dart';

import 'support.dart';

void main() {
  late AdminHarness harness;

  setUp(() async => harness = await AdminHarness.start(seedStore: true));
  tearDown(() => harness.stop());

  test('shipping-profile discovery requires the Admin route guard', () async {
    final request = harness.client.get('/admin/shipping-profiles');

    (await request.send()).assertUnauthorized();
  });

  test('lists typed Medusa profile fields with search and paging', () async {
    final token = await harness.adminToken();
    final request = harness.client.get(
      '/admin/shipping-profiles?q=default&limit=1&offset=0',
    )..bearer(token);

    final response = await request.send();

    response.assertOk();
    final body = response.json! as Map<String, Object?>;
    expect(
        body.keys,
        unorderedEquals([
          'shipping_profiles',
          'count',
          'limit',
          'offset',
        ]));
    expect(body['count'], 1);
    expect(body['limit'], 1);
    expect(body['offset'], 0);
    final profile = (body['shipping_profiles']! as List<Object?>).single!
        as Map<String, Object?>;
    expect(
        profile.keys,
        unorderedEquals([
          'id',
          'name',
          'type',
          'created_at',
          'updated_at',
        ]));
    expect(profile['id'], 'sp_default');
    expect(profile['name'], 'Default Shipping Profile');
    expect(profile['type'], 'default');
    expect(DateTime.parse(profile['created_at']! as String).isUtc, isTrue);
    expect(DateTime.parse(profile['updated_at']! as String).isUtc, isTrue);
  });

  test('product detail embeds its current shipping profile', () async {
    final token = await harness.adminToken();
    final request = harness.client.get('/admin/products/prod_tshirt')
      ..bearer(token);

    final response = await request.send();

    response.assertOk();
    final body = response.json! as Map<String, Object?>;
    final profile = body['shipping_profile']! as Map<String, Object?>;
    expect(profile['id'], 'sp_default');
    expect(profile['name'], 'Default Shipping Profile');
    expect(profile['type'], 'default');
  });
}
