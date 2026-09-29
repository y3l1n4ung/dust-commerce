-- Links reusable options to products without copying the option definition.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_product_options (
  id                TEXT PRIMARY KEY,
  product_id        TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  product_option_id TEXT NOT NULL
                    REFERENCES product_options (id) ON DELETE CASCADE,
  created_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion detaches an option without erasing historical identity.
  deleted_at        TEXT
);

CREATE UNIQUE INDEX idx_product_product_options_active_pair
ON product_product_options (product_id, product_option_id)
WHERE deleted_at IS NULL;
CREATE INDEX idx_product_product_options_option
ON product_product_options (product_option_id, product_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_product_options_touch_updated_at
AFTER UPDATE ON product_product_options
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_product_options
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
