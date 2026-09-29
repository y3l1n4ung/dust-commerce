-- Removes fulfillment providers and their timestamp trigger.
DROP TRIGGER IF EXISTS fulfillment_providers_touch_updated_at;
DROP TABLE IF EXISTS fulfillment_providers;
