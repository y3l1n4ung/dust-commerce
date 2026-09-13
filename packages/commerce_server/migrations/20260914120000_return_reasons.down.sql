-- Removes the return-reason taxonomy and its timestamp trigger.
DROP TRIGGER IF EXISTS return_reasons_touch_updated_at;
DROP TABLE IF EXISTS return_reasons;
