-- Defines a region-specific delivery choice and its exact checkout charge.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE shipping_options (
  id            TEXT PRIMARY KEY,
  region_id     TEXT NOT NULL REFERENCES regions (id) ON DELETE CASCADE,
  name          TEXT NOT NULL CHECK (length(name) > 0),
  -- Integer minor units avoid floating-point money errors.
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  currency_code TEXT NOT NULL
                CHECK (length(currency_code) = 3
                       AND currency_code = lower(currency_code)),
  metadata      TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion hides the option without invalidating existing orders.
  deleted_at    TEXT
);

CREATE INDEX idx_shipping_options_region ON shipping_options (region_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER shipping_options_touch_updated_at AFTER UPDATE ON shipping_options
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE shipping_options
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
