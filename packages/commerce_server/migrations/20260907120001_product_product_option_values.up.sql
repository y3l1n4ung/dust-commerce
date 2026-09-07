-- Limits a product-option link to the global values offered by that product.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_product_option_values (
  id                        TEXT PRIMARY KEY,
  product_product_option_id TEXT NOT NULL
                            REFERENCES product_product_options (id)
                            ON DELETE CASCADE,
  product_option_value_id   TEXT NOT NULL
                            REFERENCES product_option_values (id)
                            ON DELETE CASCADE,
  created_at                TEXT NOT NULL DEFAULT
                            (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at                TEXT NOT NULL DEFAULT
                            (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion removes availability without rewriting old variants.
  deleted_at                TEXT
);

CREATE UNIQUE INDEX idx_product_product_option_values_active_pair
ON product_product_option_values
  (product_product_option_id, product_option_value_id)
WHERE deleted_at IS NULL;
CREATE INDEX idx_product_product_option_values_value
ON product_product_option_values (product_option_value_id)
WHERE deleted_at IS NULL;

-- A product can only expose values owned by its linked option.
CREATE TRIGGER product_product_option_values_validate_insert
BEFORE INSERT ON product_product_option_values
WHEN NOT EXISTS (
  SELECT 1
  FROM product_product_options link
  JOIN product_option_values value
    ON value.option_id = link.product_option_id
  WHERE link.id = NEW.product_product_option_id
    AND value.id = NEW.product_option_value_id
    AND link.deleted_at IS NULL
    AND value.deleted_at IS NULL
) BEGIN
  SELECT raise(ABORT, 'option value does not belong to product option');
END;

CREATE TRIGGER product_product_option_values_validate_update
BEFORE UPDATE OF product_product_option_id, product_option_value_id
ON product_product_option_values
WHEN NOT EXISTS (
  SELECT 1
  FROM product_product_options link
  JOIN product_option_values value
    ON value.option_id = link.product_option_id
  WHERE link.id = NEW.product_product_option_id
    AND value.id = NEW.product_option_value_id
    AND link.deleted_at IS NULL
    AND value.deleted_at IS NULL
) BEGIN
  SELECT raise(ABORT, 'option value does not belong to product option');
END;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_product_option_values_touch_updated_at
AFTER UPDATE ON product_product_option_values
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_product_option_values
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
