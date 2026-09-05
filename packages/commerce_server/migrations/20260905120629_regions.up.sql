-- Defines a selling market so cart prices, taxes, and allowed countries agree.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE regions (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  currency_code   TEXT NOT NULL
                  CHECK (length(currency_code) = 3
                         AND currency_code = lower(currency_code)),
  -- Basis points keep tax calculations exact without floating-point rounding.
  tax_rate        INTEGER NOT NULL CHECK (tax_rate BETWEEN 0 AND 10000),
  tax_inclusive   INTEGER NOT NULL DEFAULT 0
                  CHECK (tax_inclusive IN (0, 1)),
  -- Compact CSV matches the current domain model; application code validates it.
  countries       TEXT NOT NULL CHECK (length(countries) > 0),
  automatic_taxes INTEGER NOT NULL DEFAULT 1
                  CHECK (automatic_taxes IN (0, 1)),
  -- Extension data remains optional but must be valid JSON when present.
  metadata        TEXT CHECK (metadata IS NULL OR json_valid(metadata)),
  created_at      TEXT NOT NULL DEFAULT
                  (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at      TEXT NOT NULL DEFAULT
                  (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion preserves references and historical order meaning.
  deleted_at      TEXT
);
