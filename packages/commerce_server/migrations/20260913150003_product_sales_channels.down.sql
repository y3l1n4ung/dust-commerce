-- Removes product availability links and their database-owned maintenance.
DROP TRIGGER IF EXISTS product_sales_channels_attach_product_after_insert;
DROP TRIGGER IF EXISTS product_sales_channels_touch_updated_at;
DROP TABLE IF EXISTS product_sales_channels;
