-- Defines merchant-managed reasons that explain independent payment refunds.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE refund_reasons (
  id          TEXT PRIMARY KEY,
  -- Merchant-facing label is shown in the refund decision form and history.
  label       TEXT NOT NULL CHECK (length(trim(label)) BETWEEN 1 AND 255),
  -- Stable code survives label edits and supports provider reconciliation.
  code        TEXT NOT NULL CHECK (length(trim(code)) BETWEEN 1 AND 255),
  -- Optional guidance keeps operational policy separate from the short label.
  description TEXT CHECK (description IS NULL OR length(description) <= 1000),
  -- Extension data remains private and valid JSON when integrations need it.
  metadata    TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves the meaning of historical refund decisions.
  deleted_at  TEXT
);

CREATE UNIQUE INDEX idx_refund_reasons_active_code
ON refund_reasons (code)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER refund_reasons_touch_updated_at AFTER UPDATE ON refund_reasons
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE refund_reasons
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
