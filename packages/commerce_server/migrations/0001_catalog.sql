-- Selling territories. Currency and tax live here, not on the product.
CREATE TABLE regions (
  id            TEXT    PRIMARY KEY,
  name          TEXT    NOT NULL,
  currency_code TEXT    NOT NULL,
  tax_rate      INTEGER NOT NULL,
  tax_inclusive INTEGER NOT NULL DEFAULT 0,
  countries     TEXT    NOT NULL
);

-- Sellable items. Not buyable themselves; their variants are.
CREATE TABLE products (
  id          TEXT PRIMARY KEY,
  title       TEXT NOT NULL,
  handle      TEXT NOT NULL UNIQUE,
  description TEXT,
  thumbnail   TEXT,
  status      TEXT NOT NULL DEFAULT 'draft'
);

-- The axes a product's variants vary along, such as Size.
CREATE TABLE product_options (
  id         TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  values_csv TEXT NOT NULL
);

-- The buyable configurations. Stock lives here.
CREATE TABLE product_variants (
  id                 TEXT    PRIMARY KEY,
  product_id         TEXT    NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  title              TEXT    NOT NULL,
  sku                TEXT,
  inventory_quantity INTEGER NOT NULL DEFAULT 0,
  manage_inventory   INTEGER NOT NULL DEFAULT 1,
  allow_backorder    INTEGER NOT NULL DEFAULT 0
);

-- One price per variant per currency. The pair is the key, so a second
-- price in the same currency cannot be inserted at all.
CREATE TABLE variant_prices (
  variant_id    TEXT    NOT NULL REFERENCES product_variants (id) ON DELETE CASCADE,
  currency_code TEXT    NOT NULL,
  amount        INTEGER NOT NULL,
  PRIMARY KEY (variant_id, currency_code)
);

-- The option values a variant was built from.
CREATE TABLE variant_option_values (
  variant_id TEXT NOT NULL REFERENCES product_variants (id) ON DELETE CASCADE,
  option_id  TEXT NOT NULL REFERENCES product_options (id) ON DELETE CASCADE,
  value      TEXT NOT NULL,
  PRIMARY KEY (variant_id, option_id)
);

CREATE INDEX idx_variants_product ON product_variants (product_id);
CREATE INDEX idx_options_product ON product_options (product_id);
