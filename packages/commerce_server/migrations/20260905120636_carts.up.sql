-- Stores a mutable shopping session before it becomes an immutable order.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE carts (
  id           TEXT PRIMARY KEY,
  region_id    TEXT NOT NULL REFERENCES regions (id),
  -- Nullable because guest checkout must work before account association.
  customer_id  TEXT REFERENCES customers (id),
  email        TEXT COLLATE NOCASE,
  metadata     TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  -- Set once checkout succeeds so completed carts cannot be treated as active.
  completed_at TEXT,
  created_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion retains recovery/audit context.
  deleted_at   TEXT
);

CREATE INDEX idx_carts_customer ON carts (customer_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER carts_touch_updated_at AFTER UPDATE ON carts
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE carts SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
