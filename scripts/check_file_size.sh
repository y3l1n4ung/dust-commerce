#!/usr/bin/env bash
set -euo pipefail

# Enforces the 180-line rule from CONTRIBUTING.md.
#
# A limit nobody checks drifts one long file at a time, and the drift is
# invisible in review because each diff is small. This turns it into a failing
# check.
#
# Generated files are exempt: they are output, not source, and their length is
# decided by the generator rather than by an author.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

LIMIT="${1:-180}"
status=0

while IFS= read -r file; do
  # Count code: no blank lines, no doc comments, no line comments.
  lines="$(grep -cve '^[[:space:]]*$' -e '^[[:space:]]*//' "$file" || true)"
  if [[ "$lines" -gt "$LIMIT" ]]; then
    echo "::error file=$file::$lines lines of code, limit is $LIMIT"
    status=1
  fi
done < <(
  find packages apps -name '*.dart' \
    -not -name '*.g.dart' \
    -not -path '*/.dart_tool/*' \
    -not -path '*/build/*' \
    | sort
)

if [[ "$status" -eq 0 ]]; then
  echo "every source file is within $LIMIT lines"
fi

exit "$status"
