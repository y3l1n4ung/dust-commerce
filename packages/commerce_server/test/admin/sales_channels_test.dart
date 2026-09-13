import 'package:test/test.dart';

import 'support.dart';

void main() {
  late AdminHarness harness;

  setUp(() async {
    harness = await AdminHarness.start(seedStore: true);
    await harness.raw(r'''
UPDATE sales_channels SET is_disabled = 1 WHERE id = 'sc_wholesale'
''');
  });
  tearDown(() => harness.stop());

  test('sales channel discovery requires a proven admin bearer', () async {
    (await harness.client.get('/admin/sales-channels').send())
        .assertUnauthorized();
  });

  test('sales channel discovery returns only ordered filter fields', () async {
    final token = await harness.adminToken();
    final response =
        await (harness.client.get('/admin/sales-channels?limit=1000&offset=0')
              ..bearer(token))
            .send();

    response.assertOk();
    final body = response.json! as Map<String, Object?>;
    expect(body, containsPair('count', 2));
    expect(body, containsPair('limit', 1000));
    expect(body, containsPair('offset', 0));
    expect(body['sales_channels'], [
      {'id': 'sc_web', 'name': 'Online Store'},
      {'id': 'sc_wholesale', 'name': 'Wholesale'},
    ]);
  });

  test('sales channel discovery searches before bounded paging', () async {
    final token = await harness.adminToken();
    final response =
        await (harness.client.get('/admin/sales-channels?q=WHOLE&limit=5000')
              ..bearer(token))
            .send();

    response.assertOk();
    final body = response.json! as Map<String, Object?>;
    expect(body, containsPair('count', 1));
    expect(body, containsPair('limit', 1000));
    expect(body['sales_channels'], [
      {'id': 'sc_wholesale', 'name': 'Wholesale'},
    ]);
  });
}
