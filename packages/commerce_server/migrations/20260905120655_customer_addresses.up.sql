-- Stores reusable customer destinations separately from immutable order snapshots.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE customer_addresses (
  id                  TEXT PRIMARY KEY,
  customer_id         TEXT NOT NULL REFERENCES customers (id)
                      ON DELETE CASCADE,
  -- Merchant label distinguishes multiple reusable destinations.
  address_name        TEXT CHECK (address_name IS NULL
                                  OR length(trim(address_name)) > 0),
  first_name          TEXT CHECK (first_name IS NULL
                                  OR length(trim(first_name)) > 0),
  last_name           TEXT CHECK (last_name IS NULL
                                  OR length(trim(last_name)) > 0),
  company             TEXT CHECK (company IS NULL
                                  OR length(trim(company)) > 0),
  phone               TEXT CHECK (phone IS NULL OR length(trim(phone)) > 0),
  address_1           TEXT NOT NULL CHECK (length(trim(address_1)) > 0),
  address_2           TEXT CHECK (address_2 IS NULL
                                  OR length(trim(address_2)) > 0),
  city                TEXT CHECK (city IS NULL OR length(trim(city)) > 0),
  province            TEXT CHECK (province IS NULL
                                  OR length(trim(province)) > 0),
  postal_code         TEXT CHECK (postal_code IS NULL
                                  OR length(trim(postal_code)) > 0),
  -- Lowercase ISO code makes region and country comparisons deterministic.
  country_code        TEXT NOT NULL
                      CHECK (length(country_code) = 2
                             AND country_code = lower(country_code)),
  -- Each role has at most one active default per customer.
  is_default_shipping INTEGER NOT NULL DEFAULT 0
                      CHECK (is_default_shipping IN (0, 1)),
  is_default_billing  INTEGER NOT NULL DEFAULT 0
                      CHECK (is_default_billing IN (0, 1)),
  metadata            TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at          TEXT NOT NULL DEFAULT
                      (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at          TEXT NOT NULL DEFAULT
                      (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves audit history without returning stale destinations.
  deleted_at          TEXT
);

CREATE INDEX idx_customer_addresses_customer
ON customer_addresses (customer_id, created_at, id)
WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_customer_addresses_default_shipping
ON customer_addresses (customer_id)
WHERE deleted_at IS NULL AND is_default_shipping = 1;
CREATE UNIQUE INDEX idx_customer_addresses_default_billing
ON customer_addresses (customer_id)
WHERE deleted_at IS NULL AND is_default_billing = 1;

-- Selecting a new default atomically clears the previous active destination.
CREATE TRIGGER customer_addresses_default_shipping_insert
BEFORE INSERT ON customer_addresses
WHEN NEW.is_default_shipping = 1 BEGIN
  UPDATE customer_addresses SET is_default_shipping = 0
  WHERE customer_id = NEW.customer_id AND deleted_at IS NULL;
END;
CREATE TRIGGER customer_addresses_default_billing_insert
BEFORE INSERT ON customer_addresses
WHEN NEW.is_default_billing = 1 BEGIN
  UPDATE customer_addresses SET is_default_billing = 0
  WHERE customer_id = NEW.customer_id AND deleted_at IS NULL;
END;
CREATE TRIGGER customer_addresses_default_shipping_update
BEFORE UPDATE OF is_default_shipping ON customer_addresses
WHEN NEW.is_default_shipping = 1 BEGIN
  UPDATE customer_addresses SET is_default_shipping = 0
  WHERE customer_id = NEW.customer_id AND id != NEW.id
    AND deleted_at IS NULL;
END;
CREATE TRIGGER customer_addresses_default_billing_update
BEFORE UPDATE OF is_default_billing ON customer_addresses
WHEN NEW.is_default_billing = 1 BEGIN
  UPDATE customer_addresses SET is_default_billing = 0
  WHERE customer_id = NEW.customer_id AND id != NEW.id
    AND deleted_at IS NULL;
END;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER customer_addresses_touch_updated_at
AFTER UPDATE ON customer_addresses
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE customer_addresses
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
