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
  (id, title, handle, description, thumbnail, status)
VALUES
  ('prod_tshirt', 'Dust T-Shirt', 't-shirt',
   'A soft cotton essential for building typed storefronts.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/tee-black-front.png',
   'published'),
  ('prod_sweatshirt', 'Dust Sweatshirt', 'sweatshirt',
   'A heavyweight layer for long code-generation sessions.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatshirt-vintage-front.png',
   'published'),
  ('prod_sweatpants', 'Dust Sweatpants', 'sweatpants',
   'Relaxed everyday sweatpants in soft brushed cotton.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatpants-gray-front.png',
   'published'),
  ('prod_shorts', 'Dust Shorts', 'shorts',
   'Easy cotton shorts for warm days and fast builds.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/shorts-vintage-front.png',
   'published')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO product_options
  (id, product_id, title, values_csv)
VALUES
  ('opt_tshirt_size', 'prod_tshirt', 'Size', 'S,M,L,XL'),
  ('opt_sweatshirt_size', 'prod_sweatshirt', 'Size', 'S,M'),
  ('opt_sweatpants_size', 'prod_sweatpants', 'Size', 'S,M'),
  ('opt_shorts_size', 'prod_shorts', 'Size', 'S,M')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO product_variants
  (id, product_id, title, sku, inventory_quantity)
VALUES
  ('var_tshirt_s', 'prod_tshirt', 'S', 'TSHIRT-S', 20),
  ('var_tshirt_m', 'prod_tshirt', 'M', 'TSHIRT-M', 20),
  ('var_tshirt_l', 'prod_tshirt', 'L', 'TSHIRT-L', 20),
  ('var_tshirt_xl', 'prod_tshirt', 'XL', 'TSHIRT-XL', 20),
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
  ('var_tshirt_s', 'usd', 1500), ('var_tshirt_m', 'usd', 1500),
  ('var_tshirt_l', 'usd', 1500), ('var_tshirt_xl', 'usd', 1500),
  ('var_sweatshirt_s', 'usd', 3500), ('var_sweatshirt_m', 'usd', 3500),
  ('var_sweatpants_s', 'usd', 2900), ('var_sweatpants_m', 'usd', 2900),
  ('var_shorts_s', 'usd', 2200), ('var_shorts_m', 'usd', 2200)
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO variant_option_values
  (variant_id, option_id, value)
VALUES
  ('var_tshirt_s', 'opt_tshirt_size', 'S'),
  ('var_tshirt_m', 'opt_tshirt_size', 'M'),
  ('var_tshirt_l', 'opt_tshirt_size', 'L'),
  ('var_tshirt_xl', 'opt_tshirt_size', 'XL'),
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
