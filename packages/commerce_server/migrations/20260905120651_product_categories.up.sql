-- Defines a nested storefront category tree with stable path handles.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_categories (
  id                 TEXT PRIMARY KEY,
  -- Customer-facing category name.
  name               TEXT NOT NULL CHECK (length(trim(name)) > 0),
  description        TEXT,
  -- Full stable route path, such as clothing/shirts for a nested category.
  handle             TEXT NOT NULL CHECK (length(trim(handle)) > 0),
  -- Self-reference establishes the navigation hierarchy without JSON nesting.
  parent_category_id TEXT REFERENCES product_categories (id)
                     ON DELETE SET NULL,
  -- Inactive categories remain editable but never appear in the store.
  is_active          INTEGER NOT NULL DEFAULT 1
                     CHECK (is_active IN (0, 1)),
  -- Sibling display order; identifiers remain independent of presentation.
  rank               INTEGER NOT NULL DEFAULT 0 CHECK (rank >= 0),
  -- Validated JSON supports merchant extensions outside the public contract.
  metadata           TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  deleted_at         TEXT,
  CHECK (parent_category_id IS NULL OR parent_category_id != id)
);

CREATE UNIQUE INDEX idx_product_categories_handle
ON product_categories (handle) WHERE deleted_at IS NULL;
CREATE INDEX idx_product_categories_parent
ON product_categories (parent_category_id, rank)
WHERE deleted_at IS NULL AND is_active = 1;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER product_categories_touch_updated_at
AFTER UPDATE ON product_categories
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE product_categories
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
