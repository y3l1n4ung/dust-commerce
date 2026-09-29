-- Stores purchasable product choices with independent inventory behavior.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_variants (
  id                 TEXT PRIMARY KEY,
  product_id         TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  title              TEXT NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 255),
  -- Material belongs to the sellable choice when variants differ by fabric.
  material           TEXT CHECK (material IS NULL OR
                                  length(trim(material)) BETWEEN 1 AND 255),
  -- External merchant identifiers remain optional but bounded for integrations.
  sku                TEXT CHECK (sku IS NULL OR
                                  length(trim(sku)) BETWEEN 1 AND 255),
  ean                TEXT CHECK (ean IS NULL OR
                                  length(trim(ean)) BETWEEN 1 AND 255),
  upc                TEXT CHECK (upc IS NULL OR
                                  length(trim(upc)) BETWEEN 1 AND 255),
  barcode            TEXT CHECK (barcode IS NULL OR
                                  length(trim(barcode)) BETWEEN 1 AND 255),
  -- Signed stock permits reservations/backorders while policy flags control sale.
  inventory_quantity INTEGER NOT NULL DEFAULT 0,
  manage_inventory   INTEGER NOT NULL DEFAULT 1
                     CHECK (manage_inventory IN (0, 1)),
  allow_backorder    INTEGER NOT NULL DEFAULT 0
                     CHECK (allow_backorder IN (0, 1)),
  -- Physical attributes stay nullable until the merchant supplies fulfillment data.
  weight             REAL CHECK (weight IS NULL OR weight >= 0),
  width              REAL CHECK (width IS NULL OR width >= 0),
  length             REAL CHECK (length IS NULL OR length >= 0),
  height             REAL CHECK (height IS NULL OR height >= 0),
  -- Customs identifiers are variant-specific and optional.
  mid_code           TEXT CHECK (mid_code IS NULL OR
                                  length(trim(mid_code)) BETWEEN 1 AND 255),
  hs_code            TEXT CHECK (hs_code IS NULL OR
                                  length(trim(hs_code)) BETWEEN 1 AND 255),
  -- Canonical lowercase ISO 3166-1 alpha-2 code supports deterministic filters.
  origin_country     TEXT CHECK (origin_country IS NULL OR
                                  origin_country GLOB '[a-z][a-z]'),
  -- Optional extension data must remain valid JSON.
  metadata           TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion hides a variant without breaking historical items.
  deleted_at         TEXT
);

CREATE INDEX idx_variants_product ON product_variants (product_id)
WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_variants_sku ON product_variants (sku)
WHERE sku IS NOT NULL AND deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER variants_touch_updated_at AFTER UPDATE ON product_variants
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_variants
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
