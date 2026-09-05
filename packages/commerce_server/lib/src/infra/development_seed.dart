import 'package:dust_dart/db.dart';

/// Inserts the deterministic catalogue used for local storefront development.
///
/// Every statement ignores its known primary keys, so starting the server with
/// seeding enabled twice never duplicates merchant data. This is deliberately
/// opt-in: production startup must never invent catalogue records.
Future<void> seedDevelopmentStore(DatabaseClient database) async {
  final seeded = await database.transaction<Unit>((transaction) async {
    for (final statement in _statements) {
      final result = await transaction.execute(statement.sql, const []);
      if (result case Err(:final error)) return Err(error);
    }
    return const Ok(unit);
  });

  if (seeded case Err(:final error)) {
    throw StateError('Development seed failed: $error');
  }
}

final _statements = <_Statement>[
  const _Statement(r'''
INSERT OR IGNORE INTO regions
  (id, name, currency_code, tax_rate, countries)
VALUES ('reg_us', 'United States', 'usd', 1000, 'us')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO products
  (id, title, handle, description, thumbnail, weight, status)
VALUES
  ('prod_tshirt', 'Essential T-Shirt', 't-shirt',
   'A soft cotton essential for building typed storefronts.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/tee-black-front.png',
   400, 'published'),
  ('prod_sweatshirt', 'Vintage Sweatshirt', 'sweatshirt',
   'A heavyweight layer for long code-generation sessions.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatshirt-vintage-front.png',
   400, 'published'),
  ('prod_sweatpants', 'Relaxed Sweatpants', 'sweatpants',
   'Relaxed everyday sweatpants in soft brushed cotton.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatpants-gray-front.png',
   400, 'published'),
  ('prod_shorts', 'Everyday Shorts', 'shorts',
   'Easy cotton shorts for warm days and fast builds.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/shorts-vintage-front.png',
   400, 'published')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO product_images (id, product_id, url, rank)
VALUES
  ('img_tshirt_1', 'prod_tshirt',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/tee-black-front.png', 0),
  ('img_tshirt_2', 'prod_tshirt',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/tee-black-back.png', 1),
  ('img_tshirt_3', 'prod_tshirt',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/tee-white-front.png', 2),
  ('img_tshirt_4', 'prod_tshirt',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/tee-white-back.png', 3),
  ('img_sweatshirt_1', 'prod_sweatshirt',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatshirt-vintage-front.png', 0),
  ('img_sweatshirt_2', 'prod_sweatshirt',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatshirt-vintage-back.png', 1),
  ('img_sweatpants_1', 'prod_sweatpants',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatpants-gray-front.png', 0),
  ('img_sweatpants_2', 'prod_sweatpants',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatpants-gray-back.png', 1),
  ('img_shorts_1', 'prod_shorts',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/shorts-vintage-front.png', 0),
  ('img_shorts_2', 'prod_shorts',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/shorts-vintage-back.png', 1)
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO product_options
  (id, product_id, title, values_csv)
VALUES
  ('opt_tshirt_size', 'prod_tshirt', 'Size', 'S,M,L,XL'),
  ('opt_tshirt_color', 'prod_tshirt', 'Color', 'Black,White'),
  ('opt_sweatshirt_size', 'prod_sweatshirt', 'Size', 'S,M'),
  ('opt_sweatpants_size', 'prod_sweatpants', 'Size', 'S,M'),
  ('opt_shorts_size', 'prod_shorts', 'Size', 'S,M')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO product_variants
  (id, product_id, title, sku, inventory_quantity)
VALUES
  ('var_tshirt_s_black', 'prod_tshirt', 'S / Black', 'TSHIRT-S-BLACK', 20),
  ('var_tshirt_s_white', 'prod_tshirt', 'S / White', 'TSHIRT-S-WHITE', 20),
  ('var_tshirt_m_black', 'prod_tshirt', 'M / Black', 'TSHIRT-M-BLACK', 20),
  ('var_tshirt_m_white', 'prod_tshirt', 'M / White', 'TSHIRT-M-WHITE', 20),
  ('var_tshirt_l_black', 'prod_tshirt', 'L / Black', 'TSHIRT-L-BLACK', 20),
  ('var_tshirt_l_white', 'prod_tshirt', 'L / White', 'TSHIRT-L-WHITE', 20),
  ('var_tshirt_xl_black', 'prod_tshirt', 'XL / Black', 'TSHIRT-XL-BLACK', 20),
  ('var_tshirt_xl_white', 'prod_tshirt', 'XL / White', 'TSHIRT-XL-WHITE', 20),
  ('var_sweatshirt_s', 'prod_sweatshirt', 'S', 'SWEATSHIRT-S', 20),
  ('var_sweatshirt_m', 'prod_sweatshirt', 'M', 'SWEATSHIRT-M', 20),
  ('var_sweatpants_s', 'prod_sweatpants', 'S', 'SWEATPANTS-S', 20),
  ('var_sweatpants_m', 'prod_sweatpants', 'M', 'SWEATPANTS-M', 20),
  ('var_shorts_s', 'prod_shorts', 'S', 'SHORTS-S', 20),
  ('var_shorts_m', 'prod_shorts', 'M', 'SHORTS-M', 20)
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO variant_prices
  (variant_id, currency_code, amount)
VALUES
  ('var_tshirt_s_black', 'usd', 1500),
  ('var_tshirt_s_white', 'usd', 1500),
  ('var_tshirt_m_black', 'usd', 1500),
  ('var_tshirt_m_white', 'usd', 1500),
  ('var_tshirt_l_black', 'usd', 1500),
  ('var_tshirt_l_white', 'usd', 1500),
  ('var_tshirt_xl_black', 'usd', 1500),
  ('var_tshirt_xl_white', 'usd', 1500),
  ('var_sweatshirt_s', 'usd', 3500), ('var_sweatshirt_m', 'usd', 3500),
  ('var_sweatpants_s', 'usd', 2900), ('var_sweatpants_m', 'usd', 2900),
  ('var_shorts_s', 'usd', 2200), ('var_shorts_m', 'usd', 2200)
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO variant_option_values
  (variant_id, option_id, value)
VALUES
  ('var_tshirt_s_black', 'opt_tshirt_size', 'S'),
  ('var_tshirt_s_black', 'opt_tshirt_color', 'Black'),
  ('var_tshirt_s_white', 'opt_tshirt_size', 'S'),
  ('var_tshirt_s_white', 'opt_tshirt_color', 'White'),
  ('var_tshirt_m_black', 'opt_tshirt_size', 'M'),
  ('var_tshirt_m_black', 'opt_tshirt_color', 'Black'),
  ('var_tshirt_m_white', 'opt_tshirt_size', 'M'),
  ('var_tshirt_m_white', 'opt_tshirt_color', 'White'),
  ('var_tshirt_l_black', 'opt_tshirt_size', 'L'),
  ('var_tshirt_l_black', 'opt_tshirt_color', 'Black'),
  ('var_tshirt_l_white', 'opt_tshirt_size', 'L'),
  ('var_tshirt_l_white', 'opt_tshirt_color', 'White'),
  ('var_tshirt_xl_black', 'opt_tshirt_size', 'XL'),
  ('var_tshirt_xl_black', 'opt_tshirt_color', 'Black'),
  ('var_tshirt_xl_white', 'opt_tshirt_size', 'XL'),
  ('var_tshirt_xl_white', 'opt_tshirt_color', 'White'),
  ('var_sweatshirt_s', 'opt_sweatshirt_size', 'S'),
  ('var_sweatshirt_m', 'opt_sweatshirt_size', 'M'),
  ('var_sweatpants_s', 'opt_sweatpants_size', 'S'),
  ('var_sweatpants_m', 'opt_sweatpants_size', 'M'),
  ('var_shorts_s', 'opt_shorts_size', 'S'),
  ('var_shorts_m', 'opt_shorts_size', 'M')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO shipping_options
  (id, region_id, name, amount, currency_code)
VALUES
  ('ship_standard', 'reg_us', 'Standard shipping', 500, 'usd'),
  ('ship_express', 'reg_us', 'Express shipping', 1500, 'usd')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO promotions
  (id, code, type, value)
VALUES ('promo_welcome', 'WELCOME10', 'percentage', 1000)
'''),
];

final class _Statement {
  const _Statement(this.sql);

  final String sql;
}
