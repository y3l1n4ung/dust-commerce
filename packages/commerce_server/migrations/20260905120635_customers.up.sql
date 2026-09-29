-- Stores guest and registered customer profiles separately from credentials.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE customers (
  id           TEXT PRIMARY KEY,
  email        TEXT COLLATE NOCASE,
  company_name TEXT,
  first_name   TEXT,
  last_name    TEXT,
  phone        TEXT,
  -- Distinguishes checkout-only guests from identities that can sign in.
  has_account  INTEGER NOT NULL DEFAULT 0 CHECK (has_account IN (0, 1)),
  metadata     TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at   TEXT NOT NULL DEFAULT
               (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion keeps orders auditable without exposing the active profile.
  deleted_at   TEXT
);

-- Like Medusa, one guest record and one account record may share an email.
CREATE UNIQUE INDEX idx_customers_email_account
ON customers (email, has_account)
WHERE email IS NOT NULL AND deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER customers_touch_updated_at AFTER UPDATE ON customers
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE customers SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
