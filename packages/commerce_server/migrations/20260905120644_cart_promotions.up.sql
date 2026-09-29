-- Snapshots the single promotion currently applied to a cart.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE cart_promotions (
  cart_id       TEXT PRIMARY KEY REFERENCES carts (id) ON DELETE CASCADE,
  promotion_id  TEXT NOT NULL REFERENCES promotions (id),
  -- Customer-facing policy fields are frozen with the calculated amount.
  code          TEXT NOT NULL,
  type          TEXT NOT NULL CHECK (type IN ('percentage', 'fixed')),
  -- Percentage values are basis points; fixed values are currency minor units.
  value         INTEGER NOT NULL CHECK (value >= 0),
  currency_code TEXT
                CHECK (currency_code IS NULL OR
                       (length(currency_code) = 3
                        AND currency_code = lower(currency_code))),
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- A percentage is currency-free; a fixed value must name its currency.
  CHECK ((type = 'percentage' AND currency_code IS NULL) OR
         (type = 'fixed' AND currency_code IS NOT NULL)),
  CHECK (type != 'percentage' OR value <= 10000)
);

-- Upserts change the applied discount in place, so updated_at must advance.
CREATE TRIGGER cart_promotions_touch_updated_at AFTER UPDATE ON cart_promotions
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE cart_promotions
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE cart_id = NEW.cart_id;
END;
