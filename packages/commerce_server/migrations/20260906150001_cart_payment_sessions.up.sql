-- Retains the payment provider chosen while a cart moves through checkout.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE cart_payment_sessions (
  -- A cart has one active provider choice; retrying replaces that choice.
  cart_id     TEXT PRIMARY KEY REFERENCES carts (id) ON DELETE CASCADE,
  -- Public provider identifier; no card or provider secret is stored here.
  provider_id TEXT NOT NULL CHECK (length(trim(provider_id)) > 0),
  created_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER cart_payment_sessions_touch_updated_at
AFTER UPDATE ON cart_payment_sessions
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE cart_payment_sessions
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE cart_id = NEW.cart_id;
END;
