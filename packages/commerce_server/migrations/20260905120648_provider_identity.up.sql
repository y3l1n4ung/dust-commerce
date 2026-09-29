-- Email/password is one provider. Its provider_metadata holds a self-describing
-- Argon2id PHC string; the password itself is never stored.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE provider_identity (
  id                TEXT PRIMARY KEY,
  -- Provider-scoped login identifier; emailpass stores normalized email here.
  entity_id         TEXT NOT NULL CHECK (length(entity_id) > 0),
  provider          TEXT NOT NULL CHECK (length(provider) > 0),
  auth_identity_id  TEXT NOT NULL REFERENCES auth_identity (id)
                    ON UPDATE CASCADE ON DELETE CASCADE,
  -- Untrusted provider profile data is kept apart from trusted app metadata.
  user_metadata     TEXT
                    CHECK (user_metadata IS NULL OR json_valid(user_metadata)),
  provider_metadata TEXT
                    CHECK (provider_metadata IS NULL OR json_valid(provider_metadata)),
  created_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  deleted_at        TEXT
);

CREATE INDEX idx_provider_identity_auth ON provider_identity (auth_identity_id)
WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_provider_identity_entity_provider
ON provider_identity (entity_id COLLATE NOCASE, provider)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER provider_identity_touch_updated_at AFTER UPDATE ON provider_identity
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE provider_identity
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
