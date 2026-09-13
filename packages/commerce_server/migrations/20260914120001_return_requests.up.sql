-- Stores customer-owned return requests independently from immutable orders.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE return_requests (
  id              TEXT PRIMARY KEY,
  -- Short monotonic number is shown to people; opaque ids remain API keys.
  display_id      INTEGER NOT NULL UNIQUE CHECK (display_id > 0),
  -- The frozen order remains the commercial source for every requested item.
  order_id        TEXT NOT NULL REFERENCES orders (id),
  -- Ownership is copied so every read can enforce the authenticated boundary.
  customer_id     TEXT NOT NULL REFERENCES customers (id),
  -- Status names match Medusa's return lifecycle for later Admin operations.
  status          TEXT NOT NULL DEFAULT 'requested'
                  CHECK (status IN (
                    'open', 'requested', 'received',
                    'partially_received', 'canceled'
                  )),
  -- Optional customer context applies to the whole return, not one item.
  note            TEXT CHECK (note IS NULL OR length(note) <= 2000),
  -- Notification preference is retained without disclosing provider details.
  no_notification INTEGER NOT NULL DEFAULT 0 CHECK (no_notification IN (0, 1)),
  -- Refund stays absent until a merchant has accepted a concrete amount.
  refund_amount   INTEGER CHECK (refund_amount IS NULL OR refund_amount >= 0),
  requested_at    TEXT NOT NULL DEFAULT
                  (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Receipt and cancellation times are mutually exclusive final audit facts.
  received_at     TEXT,
  canceled_at     TEXT,
  created_at      TEXT NOT NULL DEFAULT
                  (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT
                  (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion keeps historical item and refund relationships readable.
  deleted_at      TEXT,
  CHECK (
    (status IN ('open', 'requested')
      AND received_at IS NULL AND canceled_at IS NULL) OR
    (status IN ('received', 'partially_received')
      AND received_at IS NOT NULL AND canceled_at IS NULL) OR
    (status = 'canceled'
      AND received_at IS NULL AND canceled_at IS NOT NULL)
  )
);

CREATE INDEX idx_return_requests_customer
ON return_requests (customer_id, requested_at DESC)
WHERE deleted_at IS NULL;

CREATE INDEX idx_return_requests_order
ON return_requests (order_id, requested_at DESC)
WHERE deleted_at IS NULL;

CREATE INDEX idx_return_requests_status
ON return_requests (status, requested_at)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER return_requests_touch_updated_at AFTER UPDATE ON return_requests
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE return_requests
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
