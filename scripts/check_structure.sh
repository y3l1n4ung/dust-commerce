#!/usr/bin/env bash
set -euo pipefail

# Enforces the operation naming rule from docs/architecture/backend-structure.md.
#
# Inside handler/, service/ and repository/ there are five permitted file names
# and no others, plus the barrel named after the folder. A rule written down and
# never checked is a rule that lasts until the first hurry.
#
# An operation that outgrows the line budget becomes a folder of the same name,
# so a directory named after an operation is allowed too.

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
      -path "*/$layer/*" \
      \( -name '*.dart' -o -type d \) \
      ! -name '*.g.dart' \
      ! -path '*/.dart_tool/*' \
      | sort
  )
done

if [[ "$status" -eq 0 ]]; then
  echo "every handler, service and repository file is an operation"
fi

exit "$status"
