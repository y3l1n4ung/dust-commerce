-- Stores the ordered image gallery for a product independently from variants.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_images (
  id         TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  -- Remote merchant asset rendered by the storefront.
  url        TEXT NOT NULL CHECK (length(url) > 0),
  -- Stable ordering avoids relying on insertion order in gallery responses.
  rank       INTEGER NOT NULL CHECK (rank >= 0),
  -- Optional extension data must remain valid JSON.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion removes an asset without erasing its audit history.
  deleted_at TEXT,
  UNIQUE (product_id, rank)
);

CREATE INDEX idx_product_images_product ON product_images (product_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_images_touch_updated_at AFTER UPDATE ON product_images
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_images
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
