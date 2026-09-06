import 'package:test/test.dart';

import 'support.dart';

void main() {
  late AdminHarness harness;

  setUp(() async => harness = await AdminHarness.start(seedStore: true));
  tearDown(() => harness.stop());

  test('variant update requires a proven admin bearer', () async {
    final request = harness.client.patch(
      '/admin/products/prod_sweatpants/variants/var_sweatpants_s',
    )..json(_body());

    (await request.send()).assertUnauthorized();
  });

  test('variant update returns detail and changes storefront readback',
      () async {
    await harness.raw(
      "INSERT INTO product_option_values (id, option_id, value, rank) "
      "VALUES ('optval_sweatpants_size_l', 'opt_sweatpants_size', 'L', 2)",
    );
    await harness.raw(
      "UPDATE product_variants SET updated_at = '2000-01-01T00:00:00.000Z' "
      "WHERE id = 'var_sweatpants_s'",
    );
    final token = await harness.adminToken();
    final request = harness.client.patch(
      '/admin/products/prod_sweatpants/variants/var_sweatpants_s',
    )
      ..bearer(token)
      ..json(_body(
        title: '  Large / Limited  ',
        sku: '  SWEATPANTS-LIMITED  ',
        barcode: '  0123456789012  ',
        manageInventory: false,
        allowBackorder: true,
        size: 'L',
      ));

    final response = await request.send();

    response.assertOk();
    final product = response.json! as Map<String, Object?>;
    final variant = _variant(product, 'var_sweatpants_s');
    expect(variant['title'], 'Large / Limited');
    expect(variant['sku'], 'SWEATPANTS-LIMITED');
    expect(variant['barcode'], '0123456789012');
    expect(variant['manage_inventory'], isFalse);
    expect(variant['allow_backorder'], isTrue);
    expect(variant['inventory_quantity'], 20);
    expect(variant['option_values'], {'opt_sweatpants_size': 'L'});

    final stored = await harness.raw(
      "SELECT title, sku, barcode, manage_inventory, allow_backorder, "
      "inventory_quantity, updated_at FROM product_variants "
      "WHERE id = 'var_sweatpants_s'",
    );
    expect(stored.single.readIndex<String>(0), 'Large / Limited');
    expect(stored.single.readIndex<String>(1), 'SWEATPANTS-LIMITED');
    expect(stored.single.readIndex<String>(2), '0123456789012');
    expect(stored.single.readIndex<int>(3), 0);
    expect(stored.single.readIndex<int>(4), 1);
    expect(stored.single.readIndex<int>(5), 20);
    expect(
      stored.single.readIndex<String>(6),
      isNot('2000-01-01T00:00:00.000Z'),
    );

    final storefront = await harness.client
        .get('/store/products/sweatpants?currency=usd')
        .send();
    storefront.assertOk();
    final publicVariant = _variant(
      storefront.json! as Map<String, Object?>,
      'var_sweatpants_s',
    );
    expect(publicVariant['title'], 'Large / Limited');
    expect(publicVariant['option_values'], {'opt_sweatpants_size': 'L'});
  });

  test('duplicate SKU is a conflict and leaves the variant unchanged',
      () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(
      '/admin/products/prod_sweatpants/variants/var_sweatpants_s',
    )
      ..bearer(token)
      ..json(_body(title: 'Must not persist', sku: 'SWEATPANTS-M'));

    (await request.send()).assertConflict();
    final stored = await harness.raw(
      "SELECT title, sku FROM product_variants "
      "WHERE id = 'var_sweatpants_s'",
    );
    expect(stored.single.readIndex<String>(0), 'S');
    expect(stored.single.readIndex<String>(1), 'SWEATPANTS-S');
  });

  test('duplicate option selection is rejected before persistence', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(
      '/admin/products/prod_sweatpants/variants/var_sweatpants_s',
    )
      ..bearer(token)
      ..json(_body(title: 'Must not persist', size: 'M'));

    (await request.send()).assertUnprocessable();
    final stored = await harness.raw(
      "SELECT title FROM product_variants WHERE id = 'var_sweatpants_s'",
    );
    expect(stored.single.readIndex<String>(0), 'S');
  });

  test('variant must belong to the product in the route', () async {
    final token = await harness.adminToken();
    final request = harness.client.patch(
      '/admin/products/prod_sweatpants/variants/var_tshirt_s_black',
    )
      ..bearer(token)
      ..json(_body());

    (await request.send()).assertNotFound();
  });
}

Map<String, Object?> _body({
  String title = 'S',
  String? sku = 'SWEATPANTS-S',
  String? barcode,
  bool manageInventory = true,
  bool allowBackorder = false,
  String size = 'S',
}) =>
    {
      'title': title,
      'sku': sku,
      'barcode': barcode,
      'manage_inventory': manageInventory,
      'allow_backorder': allowBackorder,
      'option_values': {'opt_sweatpants_size': size},
    };

Map<String, Object?> _variant(Map<String, Object?> product, String id) =>
    (product['variants']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .singleWhere((variant) => variant['id'] == id);
