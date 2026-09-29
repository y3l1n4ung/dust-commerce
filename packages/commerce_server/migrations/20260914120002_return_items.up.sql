-- Stores requested quantities against immutable order-line snapshots.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE return_items (
  id                TEXT PRIMARY KEY,
  -- Deleting an uncommitted return removes only its owned item requests.
  return_id         TEXT NOT NULL REFERENCES return_requests (id) ON DELETE CASCADE,
  -- The immutable order item proves title, price and originally bought quantity.
  order_item_id     TEXT NOT NULL REFERENCES order_items (id),
  quantity          INTEGER NOT NULL CHECK (quantity > 0),
  -- Receipt quantities are updated by later merchant operations, never clients.
  received_quantity INTEGER NOT NULL DEFAULT 0
                    CHECK (received_quantity BETWEEN 0 AND quantity),
  -- Damaged received units are excluded from any future stock restoration.
  damaged_quantity INTEGER NOT NULL DEFAULT 0
                    CHECK (damaged_quantity BETWEEN 0 AND received_quantity),
  -- A retired reason remains referentially valid for historical requests.
  reason_id         TEXT REFERENCES return_reasons (id),
  -- Optional item-specific context does not overload the reason label.
  note              TEXT CHECK (note IS NULL OR length(note) <= 1000),
  -- Extension data is private and must remain valid JSON when present.
  metadata          TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at        TEXT NOT NULL DEFAULT
                    (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  UNIQUE (return_id, order_item_id)
);

CREATE INDEX idx_return_items_order_item
ON return_items (order_item_id);

CREATE INDEX idx_return_items_reason
ON return_items (reason_id);

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER return_items_touch_updated_at AFTER UPDATE ON return_items
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE return_items
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
