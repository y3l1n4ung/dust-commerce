-- Removes shipping-option provider resolution and its timestamp trigger.
DROP TRIGGER IF EXISTS shipping_option_fulfillment_provider_touch_updated_at;
DROP TABLE IF EXISTS shipping_option_fulfillment_provider;
