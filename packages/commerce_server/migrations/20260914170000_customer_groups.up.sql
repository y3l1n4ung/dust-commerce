-- Stores merchant-defined customer segments independently from customer profiles.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE customer_groups (
  -- Opaque identity keeps names editable and safe for route ownership checks.
  id         TEXT PRIMARY KEY,
  -- Names are merchant-facing labels used by search and typed confirmation.
  name       TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 255),
  -- Creator ownership is audit context, not part of the Admin list response.
  created_by TEXT REFERENCES admin_users (id) ON DELETE SET NULL,
  -- Extension data stays valid JSON and outside explicit response allowlists.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves membership history without listing retired groups.
  deleted_at TEXT
);

CREATE UNIQUE INDEX idx_customer_groups_active_name
ON customer_groups (name)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER customer_groups_touch_updated_at AFTER UPDATE ON customer_groups
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE customer_groups
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
