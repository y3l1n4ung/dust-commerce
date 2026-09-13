-- Defines fulfillment behavior shared by products and delivery options.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE shipping_profile (
  id         TEXT PRIMARY KEY,
  -- Merchant-facing name identifies the profile in Admin selection controls.
  name       TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 255),
  -- Open text matches Medusa while allowing custom fulfillment integrations.
  type       TEXT NOT NULL CHECK (length(trim(type)) BETWEEN 1 AND 255),
  -- Provider-specific extension data stays valid JSON when present.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion keeps historical fulfillment relationships explainable.
  deleted_at TEXT
);

-- Medusa 2.20.1 permits one active profile for each merchant-facing name.
CREATE UNIQUE INDEX idx_shipping_profile_active_name
ON shipping_profile (name)
WHERE deleted_at IS NULL;
CREATE INDEX idx_shipping_profile_active_type
ON shipping_profile (type, name, id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER shipping_profile_touch_updated_at
AFTER UPDATE ON shipping_profile
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE shipping_profile
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;

-- Medusa assigns a default profile when a store has none.
INSERT INTO shipping_profile (id, name, type)
VALUES ('sp_default', 'Default Shipping Profile', 'default');
