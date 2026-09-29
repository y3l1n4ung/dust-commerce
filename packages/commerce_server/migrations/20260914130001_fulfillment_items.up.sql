-- Freezes the exact order-line quantities assigned to each fulfillment.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE fulfillment_items (
  -- Opaque identifier is stable across shipment and delivery operations.
  id                TEXT PRIMARY KEY,
  -- The parent owns this snapshot and removes it on a hard order cleanup.
  fulfillment_id    TEXT NOT NULL REFERENCES fulfillments (id) ON DELETE CASCADE,
  -- Provider-facing title is frozen so later catalogue edits cannot change it.
  title             TEXT NOT NULL CHECK (length(trim(title)) > 0),
  -- Positive integer quantity avoids fractional physical inventory movement.
  quantity          INTEGER NOT NULL CHECK (quantity > 0),
  -- Medusa requires provider snapshots even when a source SKU is empty.
  sku               TEXT NOT NULL,
  -- Medusa requires provider snapshots even when a source barcode is empty.
  barcode           TEXT NOT NULL,
  -- Order-line ownership is checked by the relationship triggers below.
  line_item_id      TEXT NOT NULL REFERENCES order_items (id) ON DELETE CASCADE,
  -- Cross-module inventory id stays optional until managed inventory exists.
  inventory_item_id TEXT CHECK (
    inventory_item_id IS NULL OR length(trim(inventory_item_id)) > 0
  ),
  -- SQLite owns the creation instant for every fulfillment-item writer.
  created_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below owns mutation time; application code never supplies it.
  updated_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves provider history while freeing active quantity.
  deleted_at        TEXT
);

CREATE UNIQUE INDEX idx_fulfillment_items_active_pair
ON fulfillment_items (fulfillment_id, line_item_id)
WHERE deleted_at IS NULL;

CREATE INDEX idx_fulfillment_items_line_active
ON fulfillment_items (line_item_id, fulfillment_id)
WHERE deleted_at IS NULL;

CREATE INDEX idx_fulfillment_items_inventory_active
ON fulfillment_items (inventory_item_id, fulfillment_id)
WHERE deleted_at IS NULL AND inventory_item_id IS NOT NULL;

-- A fulfillment can contain only lines owned by its immutable order.
CREATE TRIGGER fulfillment_items_validate_insert
BEFORE INSERT ON fulfillment_items
WHEN NEW.deleted_at IS NULL AND (
  NOT EXISTS (
    SELECT 1
    FROM fulfillments fulfillment
    JOIN order_items item ON item.id = NEW.line_item_id
    WHERE fulfillment.id = NEW.fulfillment_id
      AND fulfillment.order_id = item.order_id
      AND fulfillment.canceled_at IS NULL
      AND fulfillment.deleted_at IS NULL
  ) OR NEW.quantity > (
    SELECT item.quantity - COALESCE(SUM(
      CASE WHEN parent.id IS NOT NULL THEN existing.quantity ELSE 0 END
    ), 0)
    FROM order_items item
    LEFT JOIN fulfillment_items existing
      ON existing.line_item_id = item.id AND existing.deleted_at IS NULL
    LEFT JOIN fulfillments parent
      ON parent.id = existing.fulfillment_id
      AND parent.canceled_at IS NULL AND parent.deleted_at IS NULL
    WHERE item.id = NEW.line_item_id
    GROUP BY item.quantity
  )
)
BEGIN
  SELECT RAISE(ABORT, 'invalid fulfillment item ownership or quantity');
END;

-- Updates preserve the same ownership and cumulative quantity invariants.
CREATE TRIGGER fulfillment_items_validate_update
BEFORE UPDATE OF fulfillment_id, line_item_id, quantity, deleted_at
ON fulfillment_items
WHEN NEW.deleted_at IS NULL AND (
  NOT EXISTS (
    SELECT 1
    FROM fulfillments fulfillment
    JOIN order_items item ON item.id = NEW.line_item_id
    WHERE fulfillment.id = NEW.fulfillment_id
      AND fulfillment.order_id = item.order_id
      AND fulfillment.canceled_at IS NULL
      AND fulfillment.deleted_at IS NULL
  ) OR NEW.quantity > (
    SELECT item.quantity - COALESCE(SUM(
      CASE WHEN parent.id IS NOT NULL THEN existing.quantity ELSE 0 END
    ), 0)
    FROM order_items item
    LEFT JOIN fulfillment_items existing ON existing.line_item_id = item.id
      AND existing.deleted_at IS NULL AND existing.id <> OLD.id
    LEFT JOIN fulfillments parent ON parent.id = existing.fulfillment_id
      AND parent.canceled_at IS NULL AND parent.deleted_at IS NULL
    WHERE item.id = NEW.line_item_id
    GROUP BY item.quantity
  )
)
BEGIN
  SELECT RAISE(ABORT, 'invalid fulfillment item ownership or quantity');
END;

-- An order cannot be reassigned after fulfillment items reference its snapshot.
CREATE TRIGGER fulfillment_items_guard_order_update
BEFORE UPDATE OF order_id ON fulfillments
WHEN NEW.order_id <> OLD.order_id AND EXISTS (
  SELECT 1 FROM fulfillment_items WHERE fulfillment_id = OLD.id
)
BEGIN
  SELECT RAISE(ABORT, 'fulfilled order ownership is immutable');
END;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER fulfillment_items_touch_updated_at
AFTER UPDATE ON fulfillment_items
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE fulfillment_items
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
