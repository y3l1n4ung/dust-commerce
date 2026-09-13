-- Freezes the single sales channel that governed a placed order's cart.
-- The link is separate because committed order history cannot be altered in place.
CREATE TABLE order_sales_channels (
  -- One row per order prevents its commercial origin from becoming ambiguous.
  order_id         TEXT PRIMARY KEY REFERENCES orders (id) ON DELETE CASCADE,
  -- Channel deletion is restricted; soft deletion retains historical meaning.
  sales_channel_id TEXT NOT NULL REFERENCES sales_channels (id)
                   ON DELETE RESTRICT,
  -- SQLite generates the immutable UTC audit instant for this snapshot.
  created_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX idx_order_sales_channels_channel
ON order_sales_channels (sales_channel_id, order_id);

-- Checkout cannot forget the channel: inserting an order snapshots its cart link
-- inside the same SQLite transaction. Channel-less carts remain valid for legacy
-- and explicitly unscoped Store traffic, matching Medusa's nullable boundary.
CREATE TRIGGER order_sales_channels_snapshot_after_insert
AFTER INSERT ON orders
WHEN EXISTS (
  SELECT 1 FROM cart_sales_channels WHERE cart_id = NEW.cart_id
)
BEGIN
  INSERT INTO order_sales_channels (order_id, sales_channel_id)
  SELECT NEW.id, sales_channel_id
  FROM cart_sales_channels
  WHERE cart_id = NEW.cart_id;
END;
