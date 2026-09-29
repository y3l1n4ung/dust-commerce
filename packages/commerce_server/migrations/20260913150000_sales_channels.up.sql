-- Defines where products are offered and where carts and orders originate.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE sales_channels (
  id          TEXT PRIMARY KEY,
  -- Merchant-facing name is searchable in Admin and copied by response queries.
  name        TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 255),
  -- Optional context explains the channel without affecting checkout behavior.
  description TEXT CHECK (description IS NULL OR length(description) <= 1000),
  -- Disabled channels remain queryable for historical orders but reject new carts.
  is_disabled INTEGER NOT NULL DEFAULT 0 CHECK (is_disabled IN (0, 1)),
  -- Extension data remains optional and valid JSON when present.
  metadata    TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves the meaning of linked historical orders.
  deleted_at  TEXT
);

CREATE INDEX idx_sales_channels_active_name
ON sales_channels (name, id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER sales_channels_touch_updated_at AFTER UPDATE ON sales_channels
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE sales_channels
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
