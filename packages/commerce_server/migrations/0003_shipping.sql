-- What a region offers as a way of getting goods to a customer.
CREATE TABLE shipping_options (
  id            TEXT    PRIMARY KEY,
  region_id     TEXT    NOT NULL REFERENCES regions (id) ON DELETE CASCADE,
  name          TEXT    NOT NULL,
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  currency_code TEXT    NOT NULL
);

CREATE INDEX idx_shipping_options_region ON shipping_options (region_id);

-- The method a cart chose, with the price and name snapshotted. A cart has at
-- most one, which is why the cart id is the key rather than a foreign key on a
-- list table.
CREATE TABLE cart_shipping_methods (
  cart_id     TEXT    PRIMARY KEY REFERENCES carts (id) ON DELETE CASCADE,
  option_id   TEXT    NOT NULL REFERENCES shipping_options (id),
  name        TEXT    NOT NULL,
  amount      INTEGER NOT NULL CHECK (amount >= 0)
);

-- Orders freeze the method the same way they freeze everything else.
ALTER TABLE orders ADD COLUMN shipping_total INTEGER NOT NULL DEFAULT 0;
ALTER TABLE orders ADD COLUMN discount_total INTEGER NOT NULL DEFAULT 0;
ALTER TABLE orders ADD COLUMN shipping_option_id TEXT;
ALTER TABLE orders ADD COLUMN shipping_name TEXT;
