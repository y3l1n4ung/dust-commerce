-- Tracks money collection for an order without storing provider card secrets.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE payment_collections (
  id            TEXT PRIMARY KEY,
  order_id      TEXT NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  -- Identifies the external adapter; provider-specific state belongs in metadata.
  provider      TEXT NOT NULL CHECK (length(provider) > 0),
  -- Integer minor units avoid floating-point money errors.
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  currency_code TEXT NOT NULL
                CHECK (length(currency_code) = 3
                       AND currency_code = lower(currency_code)),
  status        TEXT NOT NULL
                CHECK (status IN ('pending', 'authorized', 'captured',
                                  'cancelled', 'failed')),
  metadata      TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Set only when funds actually move; status alone is not an event timestamp.
  captured_at   TEXT,
  deleted_at    TEXT
);

CREATE INDEX idx_payment_collections_order ON payment_collections (order_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER payments_touch_updated_at AFTER UPDATE ON payment_collections
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE payment_collections
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
