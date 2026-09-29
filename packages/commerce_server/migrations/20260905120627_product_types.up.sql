-- Defines reusable merchant product classifications, matching Medusa's model.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_types (
  id          TEXT PRIMARY KEY,
  -- Merchant-facing label selected by products and Admin filters.
  value       TEXT NOT NULL CHECK (length(trim(value)) BETWEEN 1 AND 255),
  -- Optional identifier owned by an upstream catalogue system.
  external_id TEXT CHECK (
    external_id IS NULL OR length(trim(external_id)) BETWEEN 1 AND 255
  ),
  -- Validated JSON supports integrations without widening the core schema.
  metadata    TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at  TEXT NOT NULL DEFAULT
              (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion retains historical product classification references.
  deleted_at  TEXT
);

CREATE UNIQUE INDEX idx_product_types_value_active
ON product_types (lower(value)) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_product_types_external_id_active
ON product_types (external_id)
WHERE deleted_at IS NULL AND external_id IS NOT NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_types_touch_updated_at AFTER UPDATE ON product_types
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_types
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
