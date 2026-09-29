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

-- Composite keys identify the exact price whose timestamp must advance.
CREATE TRIGGER variant_prices_touch_updated_at AFTER UPDATE ON variant_prices
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE variant_prices
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE variant_id = NEW.variant_id AND currency_code = NEW.currency_code;
END;
