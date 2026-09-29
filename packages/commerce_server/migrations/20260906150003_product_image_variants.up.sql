-- Associates product gallery images with the variants that should display them.
-- An image without rows remains visible for every variant of its product.
CREATE TABLE product_image_variants (
  image_id   TEXT NOT NULL REFERENCES product_images (id) ON DELETE CASCADE,
  variant_id TEXT NOT NULL REFERENCES product_variants (id) ON DELETE CASCADE,
  -- SQLite generates the immutable UTC audit instant for each association.
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (image_id, variant_id)
);

CREATE INDEX idx_product_image_variants_variant
ON product_image_variants (variant_id, image_id);

-- Both sides must be active children of the same product. Foreign keys alone
-- cannot express that cross-table ownership invariant in SQLite.
CREATE TRIGGER product_image_variants_same_product_insert
BEFORE INSERT ON product_image_variants
WHEN NOT EXISTS (
  SELECT 1
  FROM product_images image
  JOIN product_variants variant ON variant.product_id = image.product_id
  WHERE image.id = NEW.image_id
    AND variant.id = NEW.variant_id
    AND image.deleted_at IS NULL
    AND variant.deleted_at IS NULL
)
BEGIN
  SELECT RAISE(ABORT, 'image and variant must belong to the same product');
END;

-- Associations are immutable pairs; callers replace them with delete/insert.
CREATE TRIGGER product_image_variants_immutable
BEFORE UPDATE ON product_image_variants
BEGIN
  SELECT RAISE(ABORT, 'product image variant links are immutable');
END;
