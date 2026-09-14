-- Records customer membership separately so groups and profiles stay independent.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE customer_group_customers (
  -- One membership event has its own identity for remove and re-add history.
  id                TEXT PRIMARY KEY,
  customer_group_id TEXT NOT NULL REFERENCES customer_groups (id)
                    ON DELETE CASCADE,
  customer_id       TEXT NOT NULL REFERENCES customers (id) ON DELETE CASCADE,
  -- Admin ownership remains auditable without entering public responses.
  created_by        TEXT REFERENCES admin_users (id) ON DELETE SET NULL,
  created_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion retains change history while excluding inactive memberships.
  deleted_at        TEXT
);

-- A customer can be an active member of the same group only once.
CREATE UNIQUE INDEX idx_customer_group_customers_active
ON customer_group_customers (customer_group_id, customer_id)
WHERE deleted_at IS NULL;

CREATE INDEX idx_customer_group_customers_customer
ON customer_group_customers (customer_id, customer_group_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER customer_group_customers_touch_updated_at
AFTER UPDATE ON customer_group_customers
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE customer_group_customers
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
