-- This service uses revocable opaque sessions instead of Medusa's JWT stack.
-- Only the SHA-256 fingerprint is stored, so a database read cannot replay it.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE auth_tokens (
  token_hash       TEXT PRIMARY KEY CHECK (length(token_hash) = 64),
  auth_identity_id TEXT NOT NULL REFERENCES auth_identity (id)
                   ON UPDATE CASCADE ON DELETE CASCADE,
  created_at       TEXT NOT NULL DEFAULT
                   (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Explicit expiry provides bounded sessions without relying on cleanup timing.
  expires_at       TEXT NOT NULL,
  CHECK (expires_at > created_at)
);

CREATE INDEX idx_auth_tokens_identity ON auth_tokens (auth_identity_id);
CREATE INDEX idx_auth_tokens_expiry ON auth_tokens (expires_at);
