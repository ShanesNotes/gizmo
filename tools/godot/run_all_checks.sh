#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"
USER_DATA_DIR="${GODOT_USER_DATA_DIR:-/tmp/gizmo-godot-checks}"

"${GODOT_BIN}" --headless --path godot --user-data-dir "${USER_DATA_DIR}" --import

# Syntax-check every script in the project (auto-discovered).
while IFS= read -r script; do
  rel="${script#godot/}"
  "${GODOT_BIN}" --headless --path godot --user-data-dir "${USER_DATA_DIR}" --check-only --script "res://${rel}"
done < <(find godot/scripts -name '*.gd' | sort)

# Run every test suite (auto-discovered — new suites can never be silently
# orphaned from the gate again; HZ-076 audit finding).
failures=0
while IFS= read -r test; do
  rel="${test#godot/}"
  echo "== ${rel}"
  if ! "${GODOT_BIN}" --headless --path godot --user-data-dir "${USER_DATA_DIR}" --script "res://${rel}"; then
    failures=$((failures + 1))
    echo "FAILED: ${rel}"
  fi
done < <(find godot/tests -name 'run_*_tests.gd' | sort)

if [[ "${failures}" -gt 0 ]]; then
  echo "run_all_checks: ${failures} suite(s) failed"
  exit 1
fi
echo "run_all_checks: all suites green"
