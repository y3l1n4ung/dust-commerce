-- Stores order-time item snapshots independent of mutable catalog records.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE order_items (
  id            TEXT PRIMARY KEY,
  order_id      TEXT NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
  -- IDs intentionally have no FK so deleting catalog data cannot erase history.
  variant_id    TEXT NOT NULL,
  product_id    TEXT NOT NULL,
  title         TEXT NOT NULL,
  variant_title TEXT,
  -- Integer minor units preserve exact historical pricing.
  unit_amount   INTEGER NOT NULL CHECK (unit_amount >= 0),
  currency_code TEXT NOT NULL
                CHECK (length(currency_code) = 3
                       AND currency_code = lower(currency_code)),
  quantity      INTEGER NOT NULL CHECK (quantity > 0),
  metadata      TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX idx_order_items_order ON order_items (order_id);
