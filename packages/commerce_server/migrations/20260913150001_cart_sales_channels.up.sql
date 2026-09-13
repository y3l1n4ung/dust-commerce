-- Associates a mutable cart with at most one current selling channel.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE cart_sales_channels (
  -- Primary-key ownership prevents an ambiguous multi-channel cart.
  cart_id          TEXT PRIMARY KEY REFERENCES carts (id) ON DELETE CASCADE,
  -- Deletion is restricted so an active or completed cart keeps its origin.
  sales_channel_id TEXT NOT NULL REFERENCES sales_channels (id)
                   ON DELETE RESTRICT,
  created_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX idx_cart_sales_channels_channel
ON cart_sales_channels (sales_channel_id, cart_id);

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER cart_sales_channels_touch_updated_at
AFTER UPDATE ON cart_sales_channels
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE cart_sales_channels
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE cart_id = NEW.cart_id;
END;
