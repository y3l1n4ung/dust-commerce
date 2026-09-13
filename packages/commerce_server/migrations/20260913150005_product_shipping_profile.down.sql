-- Removes product fulfillment links and their database-owned maintenance.
DROP TRIGGER IF EXISTS product_shipping_profile_attach_product_after_insert;
DROP TRIGGER IF EXISTS product_shipping_profile_touch_updated_at;
DROP TABLE IF EXISTS product_shipping_profile;
