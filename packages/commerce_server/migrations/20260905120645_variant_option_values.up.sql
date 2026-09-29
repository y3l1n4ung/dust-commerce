-- Links a variant to one stable value for each of its product options.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE variant_option_values (
  variant_id     TEXT NOT NULL
                 REFERENCES product_variants (id) ON DELETE CASCADE,
  option_id      TEXT NOT NULL,
  option_value_id TEXT NOT NULL,
  created_at     TEXT NOT NULL DEFAULT
                 (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at     TEXT NOT NULL DEFAULT
                 (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- One row per pair prevents a variant selecting two values for one option.
  PRIMARY KEY (variant_id, option_id),
  -- The composite key prevents linking a value owned by another option.
  FOREIGN KEY (option_value_id, option_id)
    REFERENCES product_option_values (id, option_id) ON DELETE CASCADE
);

CREATE INDEX idx_variant_values_option_value
ON variant_option_values (option_value_id, variant_id);

-- Composite keys identify the exact selection whose timestamp must advance.
CREATE TRIGGER variant_values_touch_updated_at
AFTER UPDATE ON variant_option_values
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE variant_option_values
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE variant_id = NEW.variant_id AND option_id = NEW.option_id;
END;
