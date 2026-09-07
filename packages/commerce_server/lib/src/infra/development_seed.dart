import 'package:dust_dart/db.dart';

part 'development_taxonomy_seed.dart';
part 'development_pricing_seed.dart';

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
VALUES
  ('reg_eu', 'Europe', 'eur', 0, 'gb,de,dk,se,fr,es,it'),
  ('reg_us', 'United States', 'usd', 1000, 'us')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO region_payment_providers (region_id, provider_id)
VALUES
  ('reg_eu', 'manual'),
  ('reg_us', 'manual')
'''),
  ..._taxonomyBeforeProducts,
  const _Statement(r'''
INSERT OR IGNORE INTO products
  (id, collection_id, title, handle, description, thumbnail, weight, status)
VALUES
  ('prod_tshirt', 'pcol_featured', 'Essential T-Shirt', 't-shirt',
   'A soft cotton essential for building typed storefronts.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/tee-black-front.png',
   400, 'published'),
  ('prod_sweatshirt', 'pcol_featured', 'Vintage Sweatshirt', 'sweatshirt',
   'A heavyweight layer for long code-generation sessions.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatshirt-vintage-front.png',
   400, 'published'),
  ('prod_sweatpants', 'pcol_featured', 'Relaxed Sweatpants', 'sweatpants',
   'Relaxed everyday sweatpants in soft brushed cotton.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/sweatpants-gray-front.png',
   400, 'published'),
  ('prod_shorts', 'pcol_featured', 'Everyday Shorts', 'shorts',
   'Easy cotton shorts for warm days and fast builds.',
   'https://medusa-public-images.s3.eu-west-1.amazonaws.com/shorts-vintage-front.png',
   400, 'published')
'''),
  ..._taxonomyAfterProducts,
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
  (id, product_id, title, rank)
VALUES
  ('opt_tshirt_size', 'prod_tshirt', 'Size', 0),
  ('opt_tshirt_color', 'prod_tshirt', 'Color', 1),
  ('opt_sweatshirt_size', 'prod_sweatshirt', 'Size', 0),
  ('opt_sweatpants_size', 'prod_sweatpants', 'Size', 0),
  ('opt_shorts_size', 'prod_shorts', 'Size', 0)
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO product_option_values
  (id, option_id, value, rank)
VALUES
  ('optval_tshirt_size_s', 'opt_tshirt_size', 'S', 0),
  ('optval_tshirt_size_m', 'opt_tshirt_size', 'M', 1),
  ('optval_tshirt_size_l', 'opt_tshirt_size', 'L', 2),
  ('optval_tshirt_size_xl', 'opt_tshirt_size', 'XL', 3),
  ('optval_tshirt_color_black', 'opt_tshirt_color', 'Black', 0),
  ('optval_tshirt_color_white', 'opt_tshirt_color', 'White', 1),
  ('optval_sweatshirt_size_s', 'opt_sweatshirt_size', 'S', 0),
  ('optval_sweatshirt_size_m', 'opt_sweatshirt_size', 'M', 1),
  ('optval_sweatpants_size_s', 'opt_sweatpants_size', 'S', 0),
  ('optval_sweatpants_size_m', 'opt_sweatpants_size', 'M', 1),
  ('optval_shorts_size_s', 'opt_shorts_size', 'S', 0),
  ('optval_shorts_size_m', 'opt_shorts_size', 'M', 1)
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
  ..._variantPriceStatements,
  const _Statement(r'''
INSERT OR IGNORE INTO variant_option_values
  (variant_id, option_id, option_value_id)
VALUES
  ('var_tshirt_s_black', 'opt_tshirt_size', 'optval_tshirt_size_s'),
  ('var_tshirt_s_black', 'opt_tshirt_color', 'optval_tshirt_color_black'),
  ('var_tshirt_s_white', 'opt_tshirt_size', 'optval_tshirt_size_s'),
  ('var_tshirt_s_white', 'opt_tshirt_color', 'optval_tshirt_color_white'),
  ('var_tshirt_m_black', 'opt_tshirt_size', 'optval_tshirt_size_m'),
  ('var_tshirt_m_black', 'opt_tshirt_color', 'optval_tshirt_color_black'),
  ('var_tshirt_m_white', 'opt_tshirt_size', 'optval_tshirt_size_m'),
  ('var_tshirt_m_white', 'opt_tshirt_color', 'optval_tshirt_color_white'),
  ('var_tshirt_l_black', 'opt_tshirt_size', 'optval_tshirt_size_l'),
  ('var_tshirt_l_black', 'opt_tshirt_color', 'optval_tshirt_color_black'),
  ('var_tshirt_l_white', 'opt_tshirt_size', 'optval_tshirt_size_l'),
  ('var_tshirt_l_white', 'opt_tshirt_color', 'optval_tshirt_color_white'),
  ('var_tshirt_xl_black', 'opt_tshirt_size', 'optval_tshirt_size_xl'),
  ('var_tshirt_xl_black', 'opt_tshirt_color', 'optval_tshirt_color_black'),
  ('var_tshirt_xl_white', 'opt_tshirt_size', 'optval_tshirt_size_xl'),
  ('var_tshirt_xl_white', 'opt_tshirt_color', 'optval_tshirt_color_white'),
  ('var_sweatshirt_s', 'opt_sweatshirt_size', 'optval_sweatshirt_size_s'),
  ('var_sweatshirt_m', 'opt_sweatshirt_size', 'optval_sweatshirt_size_m'),
  ('var_sweatpants_s', 'opt_sweatpants_size', 'optval_sweatpants_size_s'),
  ('var_sweatpants_m', 'opt_sweatpants_size', 'optval_sweatpants_size_m'),
  ('var_shorts_s', 'opt_shorts_size', 'optval_shorts_size_s'),
  ('var_shorts_m', 'opt_shorts_size', 'optval_shorts_size_m')
'''),
  const _Statement(r'''
INSERT OR IGNORE INTO product_image_variants (image_id, variant_id)
SELECT image.id, variant.id
FROM product_images image
JOIN product_variants variant ON variant.product_id = image.product_id
WHERE image.product_id = 'prod_tshirt'
  AND (
    (image.id IN ('img_tshirt_1', 'img_tshirt_2') AND variant.id IN (
      'var_tshirt_s_black', 'var_tshirt_m_black',
      'var_tshirt_l_black', 'var_tshirt_xl_black'
    ))
    OR
    (image.id IN ('img_tshirt_3', 'img_tshirt_4') AND variant.id IN (
      'var_tshirt_s_white', 'var_tshirt_m_white',
      'var_tshirt_l_white', 'var_tshirt_xl_white'
    ))
  )
'''),
  ..._shippingPriceStatements,
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
