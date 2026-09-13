-- Links products to every sales channel through which they may be sold.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_sales_channels (
  -- Stable link identity matches Medusa's product-sales-channel link module.
  id               TEXT PRIMARY KEY,
  -- Product deletion removes only its availability links and owned graph.
  product_id       TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  -- Channel deletion is restricted so active product availability stays explicit.
  sales_channel_id TEXT NOT NULL REFERENCES sales_channels (id)
                   ON DELETE RESTRICT,
  created_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion supports detaching a product without erasing link history.
  deleted_at       TEXT
);

CREATE UNIQUE INDEX idx_product_sales_channels_active_pair
ON product_sales_channels (product_id, sales_channel_id)
WHERE deleted_at IS NULL;
CREATE INDEX idx_product_sales_channels_channel
ON product_sales_channels (sales_channel_id, product_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_sales_channels_touch_updated_at
AFTER UPDATE ON product_sales_channels
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_sales_channels
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;

-- New products default to the first active channel until Admin supports selection.
CREATE TRIGGER product_sales_channels_attach_product_after_insert
AFTER INSERT ON products
WHEN NEW.deleted_at IS NULL AND EXISTS (
  SELECT 1 FROM sales_channels
  WHERE is_disabled = 0 AND deleted_at IS NULL
)
BEGIN
  INSERT INTO product_sales_channels (id, product_id, sales_channel_id)
  SELECT 'prodsc_' || lower(hex(randomblob(16))), NEW.id, channel.id
  FROM sales_channels channel
  WHERE channel.is_disabled = 0 AND channel.deleted_at IS NULL
  ORDER BY channel.created_at, channel.id
  LIMIT 1;
END;

-- Existing active products receive the same default when this migration lands.
INSERT INTO product_sales_channels (id, product_id, sales_channel_id)
SELECT 'prodsc_' || lower(hex(randomblob(16))), product.id, channel.id
FROM products product
JOIN (
  SELECT id FROM sales_channels
  WHERE is_disabled = 0 AND deleted_at IS NULL
  ORDER BY created_at, id
  LIMIT 1
) channel
WHERE product.deleted_at IS NULL;
