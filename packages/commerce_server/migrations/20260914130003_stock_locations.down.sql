-- Removes stock locations and their timestamp trigger.
DROP TRIGGER IF EXISTS stock_locations_touch_updated_at;
DROP TABLE IF EXISTS stock_locations;
