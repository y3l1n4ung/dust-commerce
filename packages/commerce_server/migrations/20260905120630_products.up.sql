-- Stores the sellable product shell; variants own stock and regional prices.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE products (
  id          TEXT PRIMARY KEY,
  title       TEXT NOT NULL CHECK (length(title) > 0),
  -- Stable human-readable lookup key used by storefront URLs.
  handle      TEXT NOT NULL CHECK (length(handle) > 0),
  description TEXT,
  thumbnail   TEXT,
  -- Merchant-facing composition shown in product information.
  material    TEXT,
  -- ISO 3166-1 alpha-2 country where the product was made.
  origin_country TEXT CHECK (
    origin_country IS NULL OR
    (length(origin_country) = 2 AND origin_country = lower(origin_country))
  ),
  -- Simple storefront classification; category hierarchy is separate.
  product_type TEXT,
  -- Physical values use the units configured for this store.
  weight      INTEGER CHECK (weight IS NULL OR weight >= 0),
  length      INTEGER CHECK (length IS NULL OR length >= 0),
  width       INTEGER CHECK (width IS NULL OR width >= 0),
  height      INTEGER CHECK (height IS NULL OR height >= 0),
  status      TEXT NOT NULL DEFAULT 'draft'
              CHECK (status IN ('draft', 'published', 'rejected', 'proposed')),
  -- Validated JSON supports merchant extensions without schema-free core data.
  metadata    TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion keeps old order references meaningful.
  deleted_at  TEXT
);

CREATE UNIQUE INDEX idx_products_handle ON products (handle)
WHERE deleted_at IS NULL;
CREATE INDEX idx_products_status ON products (status)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER products_touch_updated_at AFTER UPDATE ON products
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE products SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
