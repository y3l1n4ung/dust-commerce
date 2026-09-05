-- Snapshots the single shipping method currently selected for a cart.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE cart_shipping_methods (
  cart_id    TEXT PRIMARY KEY REFERENCES carts (id) ON DELETE CASCADE,
  option_id  TEXT NOT NULL REFERENCES shipping_options (id),
  -- Name and amount are copied so later shipping-option edits do not change totals.
  name       TEXT NOT NULL,
  amount     INTEGER NOT NULL CHECK (amount >= 0),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
