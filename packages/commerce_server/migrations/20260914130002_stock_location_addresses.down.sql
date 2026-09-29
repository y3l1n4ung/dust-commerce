-- Removes stock-location addresses and their timestamp trigger.
DROP TRIGGER IF EXISTS stock_location_addresses_touch_updated_at;
DROP TABLE IF EXISTS stock_location_addresses;
