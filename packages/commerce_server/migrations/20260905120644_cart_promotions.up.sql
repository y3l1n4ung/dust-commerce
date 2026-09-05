-- Snapshots the single promotion currently applied to a cart.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE cart_promotions (
  cart_id      TEXT PRIMARY KEY REFERENCES carts (id) ON DELETE CASCADE,
  promotion_id TEXT NOT NULL REFERENCES promotions (id),
  -- Code and amount are copied so policy edits cannot silently change the cart.
  code         TEXT NOT NULL,
  amount       INTEGER NOT NULL CHECK (amount >= 0),
  created_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
