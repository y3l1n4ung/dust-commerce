-- Links each stock location to the fulfillment adapters it may use.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE stock_location_fulfillment_providers (
  -- Location removal deletes only its owned provider assignments.
  stock_location_id       TEXT NOT NULL REFERENCES stock_locations (id)
                          ON DELETE CASCADE,
  -- Provider removal deletes selection links but not fulfillment history.
  fulfillment_provider_id TEXT NOT NULL REFERENCES fulfillment_providers (id)
                          ON DELETE CASCADE,
  -- SQLite owns the creation instant for every assignment writer.
  created_at              TEXT NOT NULL DEFAULT
                          (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below owns mutation time; application code never supplies it.
  updated_at              TEXT NOT NULL DEFAULT
                          (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion records detachment and allows explicit reactivation.
  deleted_at              TEXT,
  PRIMARY KEY (stock_location_id, fulfillment_provider_id)
);

CREATE INDEX idx_location_fulfillment_providers_provider_active
ON stock_location_fulfillment_providers (
  fulfillment_provider_id, stock_location_id
)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER stock_location_fulfillment_providers_touch_updated_at
AFTER UPDATE ON stock_location_fulfillment_providers
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE stock_location_fulfillment_providers
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE stock_location_id = NEW.stock_location_id
    AND fulfillment_provider_id = NEW.fulfillment_provider_id;
END;
