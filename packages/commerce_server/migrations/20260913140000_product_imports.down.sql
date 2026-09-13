-- Removes staged product-import transactions and their table-owned objects.
DROP TRIGGER IF EXISTS product_imports_touch_updated_at;
DROP INDEX IF EXISTS idx_product_imports_owner_pending;
DROP TABLE IF EXISTS product_imports;
