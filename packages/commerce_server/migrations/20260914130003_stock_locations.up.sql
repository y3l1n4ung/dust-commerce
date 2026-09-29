-- Defines merchant stock locations used to source physical fulfillments.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE stock_locations (
  -- Opaque location identity is stored on fulfillments and inventory levels.
  id         TEXT PRIMARY KEY,
  -- Merchant-facing name is searchable in Admin fulfillment selection.
  name       TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 255),
  -- Address is optional for digital/manual operations and owned separately.
  address_id TEXT REFERENCES stock_location_addresses (id) ON DELETE SET NULL,
  -- Merchant extension data remains private and valid JSON when present.
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  -- SQLite owns the creation instant for every location writer.
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below owns mutation time; application code never supplies it.
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion hides retired locations without rewriting fulfillment history.
  deleted_at TEXT
);

CREATE INDEX idx_stock_locations_name_active
ON stock_locations (name, id)
WHERE deleted_at IS NULL;

-- One active location owns an address; retired locations release that address.
CREATE UNIQUE INDEX idx_stock_locations_address_active
ON stock_locations (address_id)
WHERE deleted_at IS NULL AND address_id IS NOT NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER stock_locations_touch_updated_at AFTER UPDATE ON stock_locations
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE stock_locations
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
