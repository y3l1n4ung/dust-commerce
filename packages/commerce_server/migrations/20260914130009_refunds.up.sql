-- Records money returned from a captured payment as its own audit event.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE refunds (
  -- Opaque identifier keeps refund retries separate from provider references.
  id                    TEXT PRIMARY KEY,
  -- This service currently models one payment per collection without leaking it.
  payment_collection_id TEXT NOT NULL
                        REFERENCES payment_collections (id) ON DELETE CASCADE,
  -- Positive integer minor units prevent meaningless or floating-point refunds.
  amount                INTEGER NOT NULL CHECK (amount > 0),
  -- Currency is frozen with the event so later order changes cannot rewrite it.
  currency_code         TEXT NOT NULL
                        CHECK (length(currency_code) = 3
                               AND currency_code = lower(currency_code)),
  -- External adapters may retain their opaque refund id without credentials.
  provider_reference    TEXT,
  -- Authenticated Admin ownership is retained while allowing staff deletion.
  created_by            TEXT REFERENCES admin_users (id) ON DELETE SET NULL,
  -- Provider-private response data remains valid JSON and outside Store DTOs.
  metadata              TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  -- SQLite owns the actual refund event time for every writer.
  created_at            TEXT NOT NULL DEFAULT
                        (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion retains reconciliation history without presenting it as active.
  deleted_at            TEXT
);

CREATE INDEX idx_refunds_payment_active
ON refunds (payment_collection_id, created_at, id)
WHERE deleted_at IS NULL;
