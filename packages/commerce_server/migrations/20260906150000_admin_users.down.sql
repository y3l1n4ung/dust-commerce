-- Reverts the complete admin profile table owned by this migration pair.
DROP TRIGGER IF EXISTS admin_users_touch_updated_at;
DROP INDEX IF EXISTS idx_admin_users_email_active;
DROP TABLE IF EXISTS admin_users;
