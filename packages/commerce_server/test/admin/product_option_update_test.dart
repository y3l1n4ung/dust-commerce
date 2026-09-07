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
      "SELECT value.value, value.rank "
      "FROM product_product_options link "
      "JOIN product_product_option_values availability "
      "ON availability.product_product_option_id = link.id "
      "JOIN product_option_values value "
      "ON value.id = availability.product_option_value_id "
      "WHERE link.product_id = 'prod_sweatpants' "
      "AND link.product_option_id = 'opt_size' "
      "AND availability.deleted_at IS NULL AND value.deleted_at IS NULL "
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
      'id': 'opt_size',
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
      '/admin/products/prod_tshirt/options/opt_size',
    )
      ..bearer(token)
      ..json(_body(title: 'Color', values: ['S', 'M', 'L', 'XL']));

    (await request.send()).assertConflict();
    final rows = await harness.raw(
      "SELECT title FROM product_options WHERE id = 'opt_size'",
    );
    expect(rows.single.readIndex<String>(0), 'Size');
  });

  test('option must belong to the product in the route', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(
      '/admin/products/prod_sweatpants/options/opt_color',
    )
      ..bearer(token)
      ..json(_body());

    (await request.send()).assertNotFound();
  });
}

const _path = '/admin/products/prod_sweatpants/options/opt_size';

Map<String, Object?> _body({
  String title = 'Size',
  List<String> values = const ['S', 'M'],
}) =>
    {'title': title, 'values': values};

Future<void> _expectOriginal(AdminHarness harness) async {
  final rows = await harness.raw(
    "SELECT option.title, value.value FROM product_product_options link "
    'JOIN product_options option ON option.id = link.product_option_id '
    'JOIN product_product_option_values availability '
    'ON availability.product_product_option_id = link.id '
    'JOIN product_option_values value '
    'ON value.id = availability.product_option_value_id '
    "WHERE link.product_id = 'prod_sweatpants' "
    "AND option.id = 'opt_size' AND value.deleted_at IS NULL "
    'AND availability.deleted_at IS NULL '
    'ORDER BY value.rank',
  );
  expect(rows.map((row) => row.readIndex<String>(0)).toSet(), {'Size'});
  expect(rows.map((row) => row.readIndex<String>(1)).toList(), ['S', 'M']);
}
