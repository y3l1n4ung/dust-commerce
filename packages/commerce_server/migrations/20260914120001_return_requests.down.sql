-- Removes return request lifecycle records and their timestamp trigger.
DROP TRIGGER IF EXISTS return_requests_touch_updated_at;
DROP TABLE IF EXISTS return_requests;
