-- Defines selectable dimensions such as Size or Color for one product.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE product_options (
  id         TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  title      TEXT NOT NULL CHECK (length(title) > 0),
  -- Compact CSV matches the current API; variant_option_values stores selection.
  values_csv TEXT NOT NULL,
  metadata   TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at TEXT NOT NULL DEFAULT
             (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves existing variant and order history.
  deleted_at TEXT
);

CREATE INDEX idx_options_product ON product_options (product_id)
WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_options_product_title
ON product_options (product_id, title)
WHERE deleted_at IS NULL;
