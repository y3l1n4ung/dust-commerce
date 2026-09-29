-- Removes fulfillment profiles after dependent product links are reverted.
DROP TRIGGER IF EXISTS shipping_profile_touch_updated_at;
DROP TABLE IF EXISTS shipping_profile;
