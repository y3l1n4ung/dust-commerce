-- Medusa separates the actor from any provider used to authenticate it.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE auth_identity (
  id           TEXT PRIMARY KEY,
  -- Trusted application links (currently customer_id); clients cannot write it.
  app_metadata TEXT CHECK (app_metadata IS NULL OR json_valid(app_metadata)),
  created_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  deleted_at   TEXT
);

CREATE INDEX idx_auth_identity_deleted_at ON auth_identity (deleted_at)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER auth_identity_touch_updated_at AFTER UPDATE ON auth_identity
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE auth_identity SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
