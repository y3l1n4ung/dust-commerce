-- Assigns one exact minor-unit price to a variant in each currency.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE variant_prices (
  variant_id    TEXT NOT NULL REFERENCES product_variants (id)
                ON DELETE CASCADE,
  currency_code TEXT NOT NULL
                CHECK (length(currency_code) = 3
                       AND currency_code = lower(currency_code)),
  -- Integer minor units avoid floating-point money errors.
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- A variant cannot have two competing prices for the same currency.
  PRIMARY KEY (variant_id, currency_code)
);
