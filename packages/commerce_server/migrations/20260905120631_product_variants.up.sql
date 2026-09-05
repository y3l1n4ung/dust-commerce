-- Stores purchasable product choices with independent inventory behavior.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_variants (
  id                 TEXT PRIMARY KEY,
  product_id         TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  title              TEXT NOT NULL CHECK (length(title) > 0),
  sku                TEXT,
  barcode            TEXT,
  -- Signed stock permits reservations/backorders while policy flags control sale.
  inventory_quantity INTEGER NOT NULL DEFAULT 0,
  manage_inventory   INTEGER NOT NULL DEFAULT 1
                     CHECK (manage_inventory IN (0, 1)),
  allow_backorder    INTEGER NOT NULL DEFAULT 0
                     CHECK (allow_backorder IN (0, 1)),
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
