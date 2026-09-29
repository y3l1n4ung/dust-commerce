-- Links each shipping option to the product profile it can fulfill.
-- UTC timestamps use ISO-8601 TEXT because SQLite has no native TIMESTAMPTZ.
CREATE TABLE shipping_option_shipping_profile (
  -- Scalar primary key keeps Medusa's shipping_profile_id relation unambiguous.
  shipping_option_id  TEXT PRIMARY KEY REFERENCES shipping_options (id)
                      ON DELETE CASCADE,
  -- Active options restrict profile deletion so item filtering cannot dangle.
  shipping_profile_id TEXT NOT NULL REFERENCES shipping_profile (id)
                      ON DELETE RESTRICT,
  -- SQLite owns the creation instant for every option-profile assignment.
  created_at          TEXT NOT NULL DEFAULT
                      (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- The trigger below owns mutation time; application code never supplies it.
  updated_at          TEXT NOT NULL DEFAULT
                      (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  -- Soft deletion disables selection while retaining configuration history.
  deleted_at          TEXT
);

-- Admin option discovery filters by profile while excluding retired links.
CREATE INDEX idx_shipping_option_profile_active_profile
ON shipping_option_shipping_profile (shipping_profile_id, shipping_option_id)
WHERE deleted_at IS NULL;

-- SQLite has no automatic ON UPDATE timestamp, so this maintains updated_at.
CREATE TRIGGER shipping_option_shipping_profile_touch_updated_at
AFTER UPDATE ON shipping_option_shipping_profile
WHEN NEW.updated_at = OLD.updated_at BEGIN
  UPDATE shipping_option_shipping_profile
  SET updated_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now')
  WHERE shipping_option_id = NEW.shipping_option_id;
END;
