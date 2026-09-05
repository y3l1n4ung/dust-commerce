-- Buyers. A guest checkout has none of these, only an email on the cart.
CREATE TABLE customers (
  id         TEXT PRIMARY KEY,
  email      TEXT NOT NULL UNIQUE,
  first_name TEXT,
  last_name  TEXT,
  phone      TEXT
);

-- Carts belong to a region, which fixes their currency and tax rule.
CREATE TABLE carts (
  id          TEXT NOT NULL PRIMARY KEY,
  region_id   TEXT NOT NULL REFERENCES regions (id),
  customer_id TEXT REFERENCES customers (id),
  email       TEXT,
  created_at  TEXT NOT NULL
);

-- A line snapshots the price and the titles it was added under, so it is
-- deliberately not a join away from the variant it came from.
CREATE TABLE line_items (
  id            TEXT    PRIMARY KEY,
  cart_id       TEXT    NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
  variant_id    TEXT    NOT NULL REFERENCES product_variants (id),
  product_id    TEXT    NOT NULL REFERENCES products (id),
  title         TEXT    NOT NULL,
  variant_title TEXT,
  unit_amount   INTEGER NOT NULL,
  currency_code TEXT    NOT NULL,
  quantity      INTEGER NOT NULL CHECK (quantity > 0)
);

-- A placed order. Totals are stored, never recomputed.
CREATE TABLE orders (
  id             TEXT    PRIMARY KEY,
  region_id      TEXT    NOT NULL REFERENCES regions (id),
  customer_id    TEXT    REFERENCES customers (id),
  email          TEXT    NOT NULL,
  currency_code  TEXT    NOT NULL,
  subtotal       INTEGER NOT NULL,
  tax            INTEGER NOT NULL,
  total          INTEGER NOT NULL,
  status         TEXT    NOT NULL DEFAULT 'pending',
  payment_status TEXT    NOT NULL DEFAULT 'awaiting',
  placed_at      TEXT    NOT NULL
);

-- Order lines are copied from the cart, not shared with it.
CREATE TABLE order_items (
  id            TEXT    PRIMARY KEY,
  order_id      TEXT    NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  variant_id    TEXT    NOT NULL,
  product_id    TEXT    NOT NULL,
  title         TEXT    NOT NULL,
  variant_title TEXT,
  unit_amount   INTEGER NOT NULL,
  currency_code TEXT    NOT NULL,
  quantity      INTEGER NOT NULL CHECK (quantity > 0)
);

-- Addresses are owned by the order they were used for, so editing an
-- account's address later cannot rewrite where something was shipped.
CREATE TABLE order_addresses (
  order_id     TEXT NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  kind         TEXT NOT NULL CHECK (kind IN ('shipping', 'billing')),
  first_name   TEXT NOT NULL,
  last_name    TEXT NOT NULL,
  line1        TEXT NOT NULL,
  line2        TEXT,
  city         TEXT NOT NULL,
  province     TEXT,
  postal_code  TEXT NOT NULL,
  country_code TEXT NOT NULL,
  phone        TEXT,
  PRIMARY KEY (order_id, kind)
);

CREATE INDEX idx_line_items_cart ON line_items (cart_id);
CREATE INDEX idx_order_items_order ON order_items (order_id);
CREATE INDEX idx_orders_customer ON orders (customer_id);
CREATE INDEX idx_orders_email ON orders (email);
