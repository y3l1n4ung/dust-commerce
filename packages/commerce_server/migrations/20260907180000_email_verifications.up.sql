-- Stores the current single-use email capability for one authentication identity.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE email_verifications (
  auth_identity_id TEXT PRIMARY KEY REFERENCES auth_identity (id)
                   ON UPDATE CASCADE ON DELETE CASCADE,
  -- Only a SHA-256 fingerprint is retained; a database read cannot verify email.
  token_hash       TEXT UNIQUE CHECK
                   (token_hash IS NULL OR length(token_hash) = 64),
  -- Explicit expiry bounds an emailed capability independently of cleanup.
  expires_at       TEXT NOT NULL,
  -- A value proves completion; NULL means sign-in must remain unavailable.
  verified_at      TEXT,
  created_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  CHECK (verified_at IS NOT NULL OR token_hash IS NOT NULL)
);

CREATE INDEX idx_email_verifications_expiry
ON email_verifications (expires_at)
WHERE verified_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER email_verifications_touch_updated_at
AFTER UPDATE ON email_verifications
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE email_verifications
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE auth_identity_id = NEW.auth_identity_id;
END;
