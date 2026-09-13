-- Removes fulfillment item snapshots and their relationship guards.
DROP TRIGGER IF EXISTS fulfillment_items_touch_updated_at;
DROP TRIGGER IF EXISTS fulfillment_items_guard_order_update;
DROP TRIGGER IF EXISTS fulfillment_items_validate_update;
DROP TRIGGER IF EXISTS fulfillment_items_validate_insert;
DROP TABLE IF EXISTS fulfillment_items;
