-- Removes returned-item quantities and their timestamp trigger.
DROP TRIGGER IF EXISTS return_items_touch_updated_at;
DROP TABLE IF EXISTS return_items;
