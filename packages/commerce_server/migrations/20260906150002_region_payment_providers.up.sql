-- Declares which payment providers a selling region can offer at checkout.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE region_payment_providers (
  -- Provider identifiers are public API values such as "manual".
  provider_id TEXT NOT NULL CHECK (length(trim(provider_id)) > 0),
  -- A provider is configured independently for each currency and territory.
  region_id   TEXT NOT NULL REFERENCES regions (id) ON DELETE CASCADE,
  -- Disabled rows preserve merchant configuration without advertising it.
  enabled     INTEGER NOT NULL DEFAULT 1 CHECK (enabled IN (0, 1)),
  created_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (region_id, provider_id)
);

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER region_payment_providers_touch_updated_at
AFTER UPDATE ON region_payment_providers
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE region_payment_providers
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE region_id = NEW.region_id AND provider_id = NEW.provider_id;
END;
