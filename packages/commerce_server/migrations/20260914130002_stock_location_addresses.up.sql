-- Stores reusable warehouse addresses separately from stock-location identity.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE stock_location_addresses (
  -- Opaque address identity lets a location replace its address explicitly.
  id           TEXT PRIMARY KEY,
  -- Provider origin must contain a usable first street line.
  address_1    TEXT NOT NULL
               CHECK (length(trim(address_1)) BETWEEN 1 AND 255),
  -- Optional second line remains distinct from company or delivery notes.
  address_2    TEXT CHECK (
    address_2 IS NULL OR length(trim(address_2)) BETWEEN 1 AND 255
  ),
  -- Optional legal or operational warehouse company name.
  company      TEXT CHECK (
    company IS NULL OR length(trim(company)) BETWEEN 1 AND 255
  ),
  -- City is optional in Medusa because not every postal system requires it.
  city         TEXT CHECK (
    city IS NULL OR length(trim(city)) BETWEEN 1 AND 255
  ),
  -- Lowercase ISO 3166-1 alpha-2 keeps country comparisons deterministic.
  country_code TEXT NOT NULL CHECK (
    length(country_code) = 2 AND country_code = lower(country_code)
  ),
  -- Provider contact number remains optional and bounded for transport APIs.
  phone        TEXT CHECK (
    phone IS NULL OR length(trim(phone)) BETWEEN 1 AND 64
  ),
  -- Postal code is optional because not every supported country uses one.
  postal_code  TEXT CHECK (
    postal_code IS NULL OR length(trim(postal_code)) BETWEEN 1 AND 32
  ),
  -- Lowercase ISO 3166-2 is preferred but custom provider values stay valid.
  province     TEXT CHECK (
    province IS NULL OR length(trim(province)) BETWEEN 1 AND 255
  ),
  -- Merchant extension data remains private and valid JSON when present.
  metadata     TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  -- SQLite owns the creation instant for every address writer.
  created_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below owns mutation time; application code never supplies it.
  updated_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion retains the origin used by historical fulfillments.
  deleted_at   TEXT
);

CREATE INDEX idx_stock_location_addresses_country_active
ON stock_location_addresses (country_code, created_at, id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER stock_location_addresses_touch_updated_at
AFTER UPDATE ON stock_location_addresses
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE stock_location_addresses
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
