-- Defines reusable selectable dimensions such as Size or Color.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_options (
  id         TEXT PRIMARY KEY,
  -- Merchant-facing axis label; bounded to keep admin forms predictable.
  title      TEXT NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 255),
  -- Exclusive options disappear with their sole product; globals are reusable.
  is_exclusive INTEGER NOT NULL DEFAULT 0 CHECK (is_exclusive IN (0, 1)),
  -- Merchant-only extension data stays outside the public response allowlist.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves historical variant and order references.
  deleted_at TEXT
);

-- Global titles are unique because merchants select them by meaning.
CREATE UNIQUE INDEX idx_product_options_global_title
ON product_options (title)
WHERE deleted_at IS NULL AND is_exclusive = 0;
CREATE INDEX idx_product_options_title ON product_options (title)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_options_touch_updated_at AFTER UPDATE ON product_options
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_options
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
