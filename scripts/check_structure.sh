#!/usr/bin/env bash
set -euo pipefail

# Enforces the operation naming rule from docs/architecture/backend-structure.md.
#
# Inside handler/, service/ and repository/ there are five permitted file names
# and no others, plus the barrel named after the folder. A rule written down and
# never checked is a rule that lasts until the first hurry.
#
# Only the layer's immediate children are checked. An operation that outgrows
# the line budget becomes a folder of the same name, and the files inside it are
# that operation's breakdown — they are named for what they hold, because they
# are not operations. update/line.dart, update/shipping.dart and
# update/promotion.dart are the three things a cart update can be.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

status=0

for layer in handler service repository; do
  while IFS= read -r path; do
    name="$(basename "$path")"
    name="${name%.dart}"
    case "$name" in
      create|read|update|delete|list|"$layer") ;;
      *)
        echo "::error file=$path::'$name' is not a permitted $layer name" \
             "(create, read, update, delete, list, or $layer)"
        status=1
        ;;
    esac
  done < <(
    find packages/commerce_server/lib/src/features \
      -type d -name "$layer" \
      -exec find {} -mindepth 1 -maxdepth 1 \
        \( -name '*.dart' -o -type d \) \
        ! -name '*.g.dart' \
        \; \
      | sort
  )
done

# A response is a public allowlist, never a domain subtype. Inheriting from a
# domain class couples the wire contract to internal fields and can expose a
# newly-added field without an explicit API review.
while IFS= read -r match; do
  echo "::error::$match"
  echo "response DTOs must declare their public fields instead of extending another class"
  status=1
done < <(
  rg --line-number --multiline \
    'class\s+[A-Za-z0-9_]*Response\s+extends\s+' \
    packages/commerce_server/lib/src/features \
    --glob '*.dart' \
    --glob '!*.g.dart' \
    || true
)

if [[ "$status" -eq 0 ]]; then
  echo "backend structure and response boundaries are valid"
fi

exit "$status"
