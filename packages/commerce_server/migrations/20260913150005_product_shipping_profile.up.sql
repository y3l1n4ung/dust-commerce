-- Links each product to the fulfillment behavior that governs its variants.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_shipping_profile (
  -- Stable link identity matches Medusa's ProductShippingProfile link module.
  id                  TEXT PRIMARY KEY,
  product_id          TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  shipping_profile_id TEXT NOT NULL REFERENCES shipping_profile (id)
                      ON DELETE RESTRICT,
  created_at          TEXT NOT NULL DEFAULT
                      (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at          TEXT NOT NULL DEFAULT
                      (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion records reassignment without keeping two profiles active.
  deleted_at          TEXT
);

-- Medusa exposes shipping_profile as a scalar product relation, never a list.
CREATE UNIQUE INDEX idx_product_shipping_profile_active_product
ON product_shipping_profile (product_id)
WHERE deleted_at IS NULL;
CREATE INDEX idx_product_shipping_profile_active_profile
ON product_shipping_profile (shipping_profile_id, product_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_shipping_profile_touch_updated_at
AFTER UPDATE ON product_shipping_profile
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_shipping_profile
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;

-- New products receive the active default unless Admin later replaces it.
CREATE TRIGGER product_shipping_profile_attach_product_after_insert
AFTER INSERT ON products
WHEN NEW.deleted_at IS NULL AND EXISTS (
  SELECT 1 FROM shipping_profile
  WHERE deleted_at IS NULL
)
BEGIN
  INSERT INTO product_shipping_profile (id, product_id, shipping_profile_id)
  SELECT 'prodsp_' || lower(hex(randomblob(16))), NEW.id, profile.id
  FROM shipping_profile profile
  WHERE profile.deleted_at IS NULL
  ORDER BY CASE profile.type WHEN 'default' THEN 0 ELSE 1 END,
           profile.created_at, profile.id
  LIMIT 1;
END;

-- Existing active products receive the same deterministic default association.
INSERT INTO product_shipping_profile (id, product_id, shipping_profile_id)
SELECT 'prodsp_' || lower(hex(randomblob(16))), product.id, profile.id
FROM products product
JOIN (
  SELECT id FROM shipping_profile
  WHERE deleted_at IS NULL
  ORDER BY CASE type WHEN 'default' THEN 0 ELSE 1 END, created_at, id
  LIMIT 1
) profile
WHERE product.deleted_at IS NULL;
