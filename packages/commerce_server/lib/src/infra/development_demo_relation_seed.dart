part of 'development_seed.dart';

/// Relational demo rows are derived from stable product ids to avoid drift.
const _demoRelationStatements = <_Statement>[
  _Statement(r'''
INSERT OR IGNORE INTO product_images (id, product_id, url, rank)
SELECT 'img_' || substr(id, 6), id, thumbnail, 0
FROM products WHERE id LIKE 'prod_demo_%'
'''),
  _Statement(r'''
INSERT OR IGNORE INTO product_variants
  (id, product_id, title, sku, inventory_quantity)
SELECT
  'var_' || substr(id, 6), id, 'Default',
  'DEMO-' || substr(id, 11),
  CASE WHEN id = 'prod_demo_16' THEN 0 ELSE 8 + CAST(substr(id, 11) AS INTEGER)
  END
FROM products WHERE id LIKE 'prod_demo_%'
'''),
  _Statement(r'''
INSERT OR IGNORE INTO variant_prices (variant_id, currency_code, amount)
SELECT variant.id, currency.code,
  CASE product.type_id
    WHEN 'ptyp_shirt' THEN currency.shirt
    WHEN 'ptyp_sweatshirt' THEN currency.sweatshirt
    WHEN 'ptyp_pants' THEN currency.pants
    ELSE currency.shorts
  END + CAST(substr(product.id, 11) AS INTEGER) * currency.step
FROM product_variants variant
JOIN products product ON product.id = variant.product_id
CROSS JOIN (
  SELECT 'usd' AS code, 1800 AS shirt, 3800 AS sweatshirt,
         3200 AS pants, 2400 AS shorts, 25 AS step
  UNION ALL
  SELECT 'eur', 1200, 2600, 2200, 1700, 20
) currency
WHERE product.id LIKE 'prod_demo_%'
'''),
  _Statement(r'''
INSERT OR IGNORE INTO product_category_products (product_id, category_id, rank)
SELECT id,
  CASE type_id
    WHEN 'ptyp_shirt' THEN 'pcat_shirts'
    WHEN 'ptyp_sweatshirt' THEN 'pcat_sweatshirts'
    WHEN 'ptyp_pants' THEN 'pcat_pants'
    ELSE 'pcat_merch'
  END,
  CAST(substr(id, 11) AS INTEGER)
FROM products WHERE id LIKE 'prod_demo_%'
'''),
  _Statement(r'''
INSERT OR IGNORE INTO product_tags (id, value)
VALUES
  ('ptag_demo_essential', 'Essential'),
  ('ptag_demo_seasonal', 'Seasonal'),
  ('ptag_demo_review', 'Needs review')
'''),
  _Statement(r'''
INSERT OR IGNORE INTO product_tag_products (product_id, tag_id)
SELECT id, CASE status
  WHEN 'published' THEN
    CASE collection_id
      WHEN 'pcol_featured' THEN 'ptag_demo_essential'
      ELSE 'ptag_demo_seasonal'
    END
  ELSE 'ptag_demo_review'
END
FROM products WHERE id LIKE 'prod_demo_%'
'''),
];

const _demoStatements = <_Statement>[
  ..._demoProductStatements,
  ..._demoRelationStatements,
];
