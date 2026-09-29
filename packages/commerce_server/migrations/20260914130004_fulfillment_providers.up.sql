-- Registers fulfillment adapters independently from locations and options.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE fulfillment_providers (
  -- Stable provider id selects the runtime adapter and appears in Admin data.
  id         TEXT PRIMARY KEY CHECK (length(trim(id)) BETWEEN 1 AND 255),
  -- Merchant-facing name explains the adapter without exposing configuration.
  name       TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 255),
  -- Provider registration metadata stays private and valid JSON when present.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  -- SQLite owns the creation instant for every provider registration.
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below owns mutation time; application code never supplies it.
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion disables selection while retaining fulfillment history.
  deleted_at TEXT
);

CREATE INDEX idx_fulfillment_providers_name_active
ON fulfillment_providers (name, id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER fulfillment_providers_touch_updated_at
AFTER UPDATE ON fulfillment_providers
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE fulfillment_providers
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
