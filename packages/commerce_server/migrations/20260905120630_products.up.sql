-- Stores the sellable product shell; variants own stock and regional prices.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE products (
  id          TEXT PRIMARY KEY,
  title       TEXT NOT NULL CHECK (length(title) > 0),
  -- Stable human-readable lookup key used by storefront URLs.
  handle      TEXT NOT NULL CHECK (length(handle) > 0),
  description TEXT,
  thumbnail   TEXT,
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
