-- Stores the crossed-out customer price that proves a variant is on sale.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE variant_original_prices (
  variant_id    TEXT NOT NULL REFERENCES product_variants (id)
                ON DELETE CASCADE,
  currency_code TEXT NOT NULL
                CHECK (length(currency_code) = 3
                       AND currency_code = lower(currency_code)),
  -- Original minor-unit price shown only when above the active selling price.
  amount        INTEGER NOT NULL CHECK (amount >= 0),
  created_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  updated_at    TEXT NOT NULL DEFAULT
                (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- One original price per variant and storefront currency.
  PRIMARY KEY (variant_id, currency_code)
);

-- Composite keys identify the exact original price whose timestamp advances.
CREATE TRIGGER variant_original_prices_touch_updated_at
AFTER UPDATE ON variant_original_prices
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE variant_original_prices
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE variant_id = NEW.variant_id AND currency_code = NEW.currency_code;
END;
