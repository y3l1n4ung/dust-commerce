-- Retains checkout destinations on the mutable cart across reloads and retries.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE cart_addresses (
  cart_id      TEXT NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
  -- One shipping row and at most one separate billing row belong to a cart.
  kind         TEXT NOT NULL CHECK (kind IN ('shipping', 'billing')),
  first_name   TEXT NOT NULL,
  last_name    TEXT NOT NULL,
  -- Organization stays distinct from apartment, suite, or secondary street.
  company      TEXT,
  line1        TEXT NOT NULL,
  line2        TEXT,
  city         TEXT NOT NULL,
  province     TEXT,
  postal_code  TEXT NOT NULL,
  -- Lowercase ISO 3166-1 alpha-2 code validated against the cart region.
  country_code TEXT NOT NULL CHECK (
    length(country_code) = 2 AND country_code = lower(country_code)
  ),
  phone        TEXT,
  created_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (cart_id, kind)
);

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER cart_addresses_touch_updated_at
AFTER UPDATE ON cart_addresses
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE cart_addresses
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE cart_id = NEW.cart_id AND kind = NEW.kind;
END;
