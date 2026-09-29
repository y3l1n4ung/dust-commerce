-- Defines curated product groups used by home rails and collection routes.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_collections (
  id         TEXT PRIMARY KEY,
  -- Customer-facing collection name.
  title      TEXT NOT NULL CHECK (length(trim(title)) > 0),
  -- Stable human-readable lookup key used by storefront URLs.
  handle     TEXT NOT NULL CHECK (length(trim(handle)) > 0),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion prevents retired collections from appearing publicly.
  deleted_at TEXT
);

CREATE UNIQUE INDEX idx_product_collections_handle
ON product_collections (handle) WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_collections_touch_updated_at
AFTER UPDATE ON product_collections
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_collections
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
