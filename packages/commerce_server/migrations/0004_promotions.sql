-- A code a customer types to pay less.
--
-- usage_count is on the row rather than derived from a join, because the
-- redemption limit is checked on every apply and counting orders each time
-- would make a cheap check expensive.
CREATE TABLE promotions (
  id            TEXT    PRIMARY KEY,
  code          TEXT    NOT NULL UNIQUE,
  type          TEXT    NOT NULL CHECK (type IN ('percentage', 'fixed')),
  value         INTEGER NOT NULL CHECK (value >= 0),
  currency_code TEXT,
  starts_at     TEXT,
  ends_at       TEXT,
  usage_limit   INTEGER,
  usage_count   INTEGER NOT NULL DEFAULT 0
);

-- The promotion a cart has applied. One at a time, so the cart id is the key.
CREATE TABLE cart_promotions (
  cart_id      TEXT    PRIMARY KEY REFERENCES carts (id) ON DELETE CASCADE,
  promotion_id TEXT    NOT NULL REFERENCES promotions (id),
  code         TEXT    NOT NULL,
  amount       INTEGER NOT NULL CHECK (amount >= 0)
);

ALTER TABLE orders ADD COLUMN promotion_code TEXT;
