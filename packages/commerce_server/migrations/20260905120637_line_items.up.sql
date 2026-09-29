-- Stores cart-item snapshots so titles and prices stay stable during checkout.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE line_items (
  id            TEXT PRIMARY KEY,
  cart_id       TEXT NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
  variant_id    TEXT NOT NULL REFERENCES product_variants (id),
  product_id    TEXT NOT NULL REFERENCES products (id),
  -- Handle and thumbnail keep historical cart lines navigable and recognisable.
  product_handle TEXT NOT NULL,
  thumbnail      TEXT,
  title         TEXT NOT NULL,
  variant_title TEXT,
  -- Integer minor units snapshot the selected price without float errors.
  unit_amount   INTEGER NOT NULL CHECK (unit_amount >= 0),
  currency_code TEXT NOT NULL
                CHECK (length(currency_code) = 3
                       AND currency_code = lower(currency_code)),
  quantity      INTEGER NOT NULL CHECK (quantity > 0),
  metadata      TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion supports removing an item while retaining audit context.
  deleted_at    TEXT
);

CREATE INDEX idx_line_items_cart ON line_items (cart_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER line_items_touch_updated_at AFTER UPDATE ON line_items
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE line_items SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
