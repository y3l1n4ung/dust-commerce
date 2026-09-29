-- Removes immutable order channel snapshots and their checkout trigger.
DROP TRIGGER IF EXISTS order_sales_channels_snapshot_after_insert;
DROP TABLE IF EXISTS order_sales_channels;
