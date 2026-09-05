-- Stores the immutable commercial snapshot produced by checkout.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE orders (
  id                 TEXT PRIMARY KEY,
  region_id          TEXT NOT NULL REFERENCES regions (id),
  customer_id        TEXT REFERENCES customers (id),
  email              TEXT NOT NULL COLLATE NOCASE,
  currency_code      TEXT NOT NULL
                     CHECK (length(currency_code) = 3
                            AND currency_code = lower(currency_code)),
  -- Every monetary value is an integer in the currency's minor unit.
  subtotal           INTEGER NOT NULL CHECK (subtotal >= 0),
  shipping_total     INTEGER NOT NULL DEFAULT 0 CHECK (shipping_total >= 0),
  discount_total     INTEGER NOT NULL DEFAULT 0 CHECK (discount_total >= 0),
  tax                INTEGER NOT NULL CHECK (tax >= 0),
  total              INTEGER NOT NULL CHECK (total >= 0),
  status             TEXT NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'completed', 'cancelled')),
  payment_status     TEXT NOT NULL DEFAULT 'awaiting'
                     CHECK (payment_status IN ('awaiting', 'captured', 'refunded')),
  -- Shipping/promotion labels are copied so later catalog edits do not rewrite history.
  shipping_option_id TEXT,
  shipping_name      TEXT,
  promotion_code     TEXT,
  metadata           TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  -- Business event time is explicit; created_at remains the database insert time.
  placed_at          TEXT NOT NULL,
  created_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  deleted_at         TEXT,
  -- Database checks make a corrupted or contradictory order total impossible.
  CHECK (discount_total <= subtotal + shipping_total),
  CHECK (total = subtotal + shipping_total - discount_total + tax)
);

CREATE INDEX idx_orders_customer ON orders (customer_id)
WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_email ON orders (email)
WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_placed_at ON orders (placed_at);

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER orders_touch_updated_at AFTER UPDATE ON orders
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE orders SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
