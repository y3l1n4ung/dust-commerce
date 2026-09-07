-- Defines one stable selectable value belonging to a product option.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_option_values (
  id         TEXT PRIMARY KEY,
  option_id  TEXT NOT NULL REFERENCES product_options (id) ON DELETE CASCADE,
  -- Customer-visible choice label; whitespace-only values are never valid.
  value      TEXT NOT NULL CHECK (length(trim(value)) BETWEEN 1 AND 255),
  -- Merchant-defined order keeps sizes and swatches stable in every client.
  rank       INTEGER NOT NULL DEFAULT 0 CHECK (rank >= 0),
  -- Merchant-only extension data stays outside the public response allowlist.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion lets historical variants retain their original selection.
  deleted_at TEXT,
  -- Supports the composite child reference that proves option ownership.
  UNIQUE (id, option_id)
);

CREATE INDEX idx_option_values_option
ON product_option_values (option_id, rank, id)
WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_option_values_option_value
ON product_option_values (option_id, value)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_option_values_touch_updated_at
AFTER UPDATE ON product_option_values
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_option_values
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
