-- Resolves one fulfillment provider for each existing checkout shipping option.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE shipping_option_fulfillment_provider (
  -- Scalar primary key prevents an option from resolving two providers.
  shipping_option_id       TEXT PRIMARY KEY REFERENCES shipping_options (id)
                           ON DELETE CASCADE,
  -- Active options restrict provider deletion so resolution cannot dangle.
  fulfillment_provider_id TEXT NOT NULL REFERENCES fulfillment_providers (id)
                          ON DELETE RESTRICT,
  -- Provider-private option payload never enters the public Store contract.
  data                     TEXT CHECK (data IS NULL OR json_valid(data)),
  -- SQLite owns the creation instant for every option-provider assignment.
  created_at               TEXT NOT NULL DEFAULT
                           (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below owns mutation time; application code never supplies it.
  updated_at               TEXT NOT NULL DEFAULT
                           (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion disables resolution while retaining configuration history.
  deleted_at               TEXT
);

CREATE INDEX idx_shipping_option_provider_active_provider
ON shipping_option_fulfillment_provider (
  fulfillment_provider_id, shipping_option_id
)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER shipping_option_fulfillment_provider_touch_updated_at
AFTER UPDATE ON shipping_option_fulfillment_provider
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE shipping_option_fulfillment_provider
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE shipping_option_id = NEW.shipping_option_id;
END;
