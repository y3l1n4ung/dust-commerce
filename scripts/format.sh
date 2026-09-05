#!/usr/bin/env bash
set -euo pipefail

# Formats handwritten Dart, and only handwritten Dart.
#
# Generated files are excluded deliberately. `dart format` rewrites them into
# something the generator would not emit, and `dust check` then reports every
# one of them stale — the two tools disagree, and the generator is the
# authority on its own output. Dust's own repository excludes them the same way.
#
# Usage: scripts/format.sh [--check]

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CHECK_MODE=false
if [[ "${1:-}" == "--check" ]]; then
  CHECK_MODE=true
fi

# `find -exec +` rather than mapfile: bash 3.2 ships on macOS and has no
# mapfile, and a contributor's laptop should run the same script CI does.
find_sources() {
  find packages apps -name '*.dart' \
    ! -name '*.g.dart' \
    ! -path '*/.dart_tool/*' \
    ! -path '*/build/*' \
    "$@"
}

if [[ "$CHECK_MODE" == true ]]; then
  find_sources -exec dart format --output=none --set-exit-if-changed {} +
  echo "handwritten Dart is formatted"
else
  find_sources -exec dart format {} +
fi
