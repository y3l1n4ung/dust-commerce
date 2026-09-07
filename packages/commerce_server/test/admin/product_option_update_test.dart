import 'package:test/test.dart';

import 'support.dart';

void main() {
  late AdminHarness harness;

  setUp(() async => harness = await AdminHarness.start(seedStore: true));
  tearDown(() => harness.stop());

  test('option update requires a proven admin bearer', () async {
    final request = harness.client.patch(_path)..json(_body());

    (await request.send()).assertUnauthorized();
  });

  test('option title, values, and rank update atomically', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(_path)
      ..bearer(token)
      ..json(_body(title: 'Waist size', values: ['M', 'S', 'XL']));

    final response = await request.send();
    response.assertOk();
    final product = response.json! as Map<String, Object?>;
    final option =
        (product['options']! as List<Object?>).single! as Map<String, Object?>;
    expect(option['title'], 'Waist size');
    expect(option['values'], ['M', 'S', 'XL']);

    final rows = await harness.raw(
      "SELECT value, rank FROM product_option_values "
      "WHERE option_id = 'opt_sweatpants_size' AND deleted_at IS NULL "
      'ORDER BY rank',
    );
    expect(
      rows
          .map((row) => [
                row.readIndex<String>(0),
                row.readIndex<int>(1),
              ])
          .toList(),
      [
        ['M', 0],
        ['S', 1],
        ['XL', 2],
      ],
    );
  });

  test('storefront reads the committed title and order', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(_path)
      ..bearer(token)
      ..json(_body(title: 'Waist size', values: ['M', 'S', 'XL']));
    (await request.send()).assertOk();

    final response =
        await harness.client.get('/store/products/sweatpants').send();
    response.assertOk();
    final product = response.json! as Map<String, Object?>;
    final option =
        (product['options']! as List<Object?>).single! as Map<String, Object?>;
    expect(option, {
      'id': 'opt_sweatpants_size',
      'title': 'Waist size',
      'values': ['M', 'S', 'XL'],
    });
  });

  test('removing a value selected by a variant leaves the option unchanged',
      () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(_path)
      ..bearer(token)
      ..json(_body(title: 'Must not persist', values: ['S']));

    (await request.send()).assertConflict();
    await _expectOriginal(harness);
  });

  test('duplicate values are rejected before persistence', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(_path)
      ..bearer(token)
      ..json(_body(title: 'Must not persist', values: ['S', 'S']));

    (await request.send()).assertUnprocessable();
    await _expectOriginal(harness);
  });

  test('duplicate sibling title is a conflict and changes nothing', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(
      '/admin/products/prod_tshirt/options/opt_tshirt_size',
    )
      ..bearer(token)
      ..json(_body(title: 'Color', values: ['S', 'M', 'L', 'XL']));

    (await request.send()).assertConflict();
    final rows = await harness.raw(
      "SELECT title FROM product_options WHERE id = 'opt_tshirt_size'",
    );
    expect(rows.single.readIndex<String>(0), 'Size');
  });

  test('option must belong to the product in the route', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(
      '/admin/products/prod_tshirt/options/opt_sweatpants_size',
    )
      ..bearer(token)
      ..json(_body());

    (await request.send()).assertNotFound();
  });
}

const _path = '/admin/products/prod_sweatpants/options/opt_sweatpants_size';

Map<String, Object?> _body({
  String title = 'Size',
  List<String> values = const ['S', 'M'],
}) =>
    {'title': title, 'values': values};

Future<void> _expectOriginal(AdminHarness harness) async {
  final rows = await harness.raw(
    "SELECT option.title, value.value FROM product_options option "
    'JOIN product_option_values value ON value.option_id = option.id '
    "WHERE option.id = 'opt_sweatpants_size' AND value.deleted_at IS NULL "
    'ORDER BY value.rank',
  );
  expect(rows.map((row) => row.readIndex<String>(0)).toSet(), {'Size'});
  expect(rows.map((row) => row.readIndex<String>(1)).toList(), ['S', 'M']);
}
