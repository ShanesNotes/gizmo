#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="${GODOT_BIN:-godot}"

"${GODOT_BIN}" --headless --path godot --import

scripts=(
  scripts/simulation.gd
  scripts/hud.gd
  scripts/end_screen.gd
  scripts/game_controller.gd
  scripts/gizmo.gd
  scripts/camera_rig.gd
  tests/run_simulation_tests.gd
  tests/run_balance_tests.gd
  tests/run_game_controller_tests.gd
  tests/run_hud_tests.gd
  tests/run_end_screen_tests.gd
)

for script in "${scripts[@]}"; do
  "${GODOT_BIN}" --headless --path godot --check-only --script "res://${script}"
done

tests=(
  run_simulation_tests.gd
  run_balance_tests.gd
  run_game_controller_tests.gd
  run_hud_tests.gd
  run_end_screen_tests.gd
)

for test in "${tests[@]}"; do
  "${GODOT_BIN}" --headless --path godot --script "res://tests/${test}"
done

"${GODOT_BIN}" --headless --path godot --quit-after 2
