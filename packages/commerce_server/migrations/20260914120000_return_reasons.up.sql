-- Defines merchant-controlled reasons customers can select for returned items.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE return_reasons (
  id                      TEXT PRIMARY KEY,
  -- Stable machine value survives label edits and is safe for analytics.
  value                   TEXT NOT NULL CHECK (length(trim(value)) BETWEEN 1 AND 255),
  -- Customer-facing copy is kept separate from the stable machine value.
  label                   TEXT NOT NULL CHECK (length(trim(label)) BETWEEN 1 AND 255),
  -- Optional guidance helps a customer choose the correct reason.
  description             TEXT CHECK (description IS NULL OR length(description) <= 1000),
  -- Parent reasons support Medusa's nested reason taxonomy without CSV fields.
  parent_return_reason_id TEXT REFERENCES return_reasons (id),
  -- Extension data is private and must remain valid JSON when present.
  metadata                TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at              TEXT NOT NULL DEFAULT
                          (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at              TEXT NOT NULL DEFAULT
                          (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves the meaning of historical return items.
  deleted_at              TEXT,
  CHECK (parent_return_reason_id IS NULL OR parent_return_reason_id <> id)
);

-- Active machine values stay unique while retired values remain historical.
CREATE UNIQUE INDEX idx_return_reasons_active_value
ON return_reasons (value)
WHERE deleted_at IS NULL;

CREATE INDEX idx_return_reasons_parent
ON return_reasons (parent_return_reason_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER return_reasons_touch_updated_at AFTER UPDATE ON return_reasons
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE return_reasons
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
