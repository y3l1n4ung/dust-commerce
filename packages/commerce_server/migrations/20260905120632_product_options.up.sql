-- Defines selectable dimensions such as Size or Color for one product.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_options (
  id         TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  title      TEXT NOT NULL CHECK (length(title) > 0),
  -- Merchant-only extension data stays outside the public response allowlist.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves existing variant and order history.
  deleted_at TEXT
);

CREATE INDEX idx_options_product ON product_options (product_id)
WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_options_product_title
ON product_options (product_id, title)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_options_touch_updated_at AFTER UPDATE ON product_options
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_options
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
