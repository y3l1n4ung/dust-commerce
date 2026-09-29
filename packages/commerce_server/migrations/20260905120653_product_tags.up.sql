-- Defines public discovery labels that can be shared by many products.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_tags (
  id         TEXT PRIMARY KEY,
  -- Customer-facing label; uniqueness is case-insensitive while active.
  value      TEXT NOT NULL CHECK (length(trim(value)) > 0),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  deleted_at TEXT
);

CREATE UNIQUE INDEX idx_product_tags_value
ON product_tags (lower(value)) WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_tags_touch_updated_at AFTER UPDATE ON product_tags
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_tags
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
