-- Removes mutable cart channel associations before the channel table.
DROP TRIGGER IF EXISTS cart_sales_channels_touch_updated_at;
DROP TABLE IF EXISTS cart_sales_channels;
