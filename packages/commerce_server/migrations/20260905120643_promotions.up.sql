-- Defines redeemable discount policy and its bounded usage window.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE promotions (
  id            TEXT PRIMARY KEY,
  code          TEXT NOT NULL COLLATE NOCASE,
  type          TEXT NOT NULL CHECK (type IN ('percentage', 'fixed')),
  -- Percentage values are basis points; fixed values are currency minor units.
  value         INTEGER NOT NULL CHECK (value >= 0),
  currency_code TEXT
                CHECK (currency_code IS NULL OR
                       (length(currency_code) = 3
                        AND currency_code = lower(currency_code))),
  starts_at     TEXT,
  ends_at       TEXT,
  usage_limit   INTEGER CHECK (usage_limit IS NULL OR usage_limit > 0),
  -- Persisted count lets checkout enforce a global redemption limit atomically.
  usage_count   INTEGER NOT NULL DEFAULT 0 CHECK (usage_count >= 0),
  metadata      TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  deleted_at    TEXT,
  -- Cross-column checks prevent internally contradictory promotion definitions.
  CHECK (type != 'percentage' OR value <= 10000),
  CHECK (type != 'fixed' OR currency_code IS NOT NULL),
  CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at),
  CHECK (usage_limit IS NULL OR usage_count <= usage_limit)
);

CREATE UNIQUE INDEX idx_promotions_code ON promotions (code)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER promotions_touch_updated_at AFTER UPDATE ON promotions
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE promotions SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
