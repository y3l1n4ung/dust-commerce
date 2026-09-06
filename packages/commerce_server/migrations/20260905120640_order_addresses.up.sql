-- Stores shipping and billing snapshots as they were when the order was placed.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE order_addresses (
  order_id     TEXT NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  -- Composite key permits at most one address of each role per order.
  kind         TEXT NOT NULL CHECK (kind IN ('shipping', 'billing')),
  first_name   TEXT NOT NULL,
  last_name    TEXT NOT NULL,
  -- Optional organization is distinct from the secondary street line.
  company      TEXT,
  line1        TEXT NOT NULL,
  line2        TEXT,
  city         TEXT NOT NULL,
  province     TEXT,
  postal_code  TEXT NOT NULL,
  -- Lowercase ISO 3166-1 alpha-2 code keeps region comparisons deterministic.
  country_code TEXT NOT NULL
               CHECK (length(country_code) = 2
                      AND country_code = lower(country_code)),
  phone        TEXT,
  created_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (order_id, kind)
);

-- Composite keys identify the exact address whose timestamp must advance.
CREATE TRIGGER order_addresses_touch_updated_at AFTER UPDATE ON order_addresses
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE order_addresses
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE order_id = NEW.order_id AND kind = NEW.kind;
END;
