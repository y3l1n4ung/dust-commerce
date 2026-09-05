-- What is owed on an order, and how far it has got.
--
-- Separate from the order rather than columns on it, because an order can be
-- paid by more than one attempt over time: a failed authorisation followed by
-- a successful one is two rows and one order.
CREATE TABLE payment_collections (
  id            TEXT    PRIMARY KEY,
  order_id      TEXT    NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  provider      TEXT    NOT NULL,
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  currency_code TEXT    NOT NULL,
  status        TEXT    NOT NULL
                CHECK (status IN ('pending', 'authorized', 'captured')),
  created_at    TEXT    NOT NULL,
  captured_at   TEXT
);

CREATE INDEX idx_payment_collections_order ON payment_collections (order_id);
