-- Defines the cart-value condition that makes one delivery option available.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE shipping_option_price_rules (
  -- Stable identifier lets operational tooling address one rule safely.
  id                 TEXT PRIMARY KEY,
  -- Removing an option removes conditions that can no longer be evaluated.
  shipping_option_id TEXT NOT NULL
                     REFERENCES shipping_options (id) ON DELETE CASCADE,
  -- The measured cart fact is explicit so new rule kinds require a decision.
  attribute          TEXT NOT NULL CHECK (attribute IN ('item_total')),
  -- The comparison is stored rather than inferred from a marketing label.
  operator           TEXT NOT NULL
                     CHECK (operator IN ('gt', 'gte', 'lt', 'lte', 'eq')),
  -- Integer minor units match cart totals without floating-point rounding.
  value              INTEGER NOT NULL CHECK (value >= 0),
  -- Creation time supports audit and deterministic operational inspection.
  created_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below advances this when an operator edits the rule.
  updated_at         TEXT NOT NULL DEFAULT
                     (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion withdraws a rule without losing its history immediately.
  deleted_at         TEXT,
  UNIQUE (shipping_option_id, attribute, operator, value)
);

CREATE INDEX idx_shipping_option_price_rules_option
ON shipping_option_price_rules (shipping_option_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER shipping_option_price_rules_touch_updated_at
AFTER UPDATE ON shipping_option_price_rules
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE shipping_option_price_rules
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE id = NEW.id;
END;
