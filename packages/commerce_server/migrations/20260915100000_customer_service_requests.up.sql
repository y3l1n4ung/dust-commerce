-- Stores customer-service conversations submitted from the public Store.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE customer_service_requests (
  -- Opaque identity is safe to expose in the submission acknowledgement.
  id              TEXT PRIMARY KEY,
  -- Proven account ownership is optional because guest checkout is supported.
  customer_id     TEXT REFERENCES customers (id) ON DELETE SET NULL,
  -- Contact details are copied so later profile edits do not rewrite history.
  name            TEXT NOT NULL
                  CHECK (length(trim(name)) BETWEEN 1 AND 120),
  email           TEXT NOT NULL
                  CHECK (length(trim(email)) BETWEEN 3 AND 254
                    AND instr(email, '@') > 1),
  -- Subject and message retain the exact customer support context.
  subject         TEXT NOT NULL
                  CHECK (length(trim(subject)) BETWEEN 1 AND 160),
  message         TEXT NOT NULL
                  CHECK (length(trim(message)) BETWEEN 1 AND 5000),
  -- Free-form reference also works for guests who only know an order number.
  order_reference TEXT
                  CHECK (order_reference IS NULL OR
                    length(trim(order_reference)) BETWEEN 1 AND 255),
  -- A compact lifecycle is enough for merchant triage without fake replies.
  status          TEXT NOT NULL DEFAULT 'open'
                  CHECK (status IN ('open', 'in_progress', 'resolved')),
  -- Resolution time is an audit fact generated only by the status update.
  resolved_at     TEXT,
  created_at      TEXT NOT NULL DEFAULT
                  (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT
                  (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  CHECK (
    (status = 'resolved' AND resolved_at IS NOT NULL) OR
    (status != 'resolved' AND resolved_at IS NULL)
  )
);

CREATE INDEX idx_customer_service_requests_status
ON customer_service_requests (status, created_at DESC, id DESC);

CREATE INDEX idx_customer_service_requests_customer
ON customer_service_requests (customer_id, created_at DESC)
WHERE customer_id IS NOT NULL;

CREATE INDEX idx_customer_service_requests_email
ON customer_service_requests (email COLLATE NOCASE, created_at DESC);

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER customer_service_requests_touch_updated_at
AFTER UPDATE ON customer_service_requests
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE customer_service_requests
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
