# GZ-016 — Scene: gizmo.gd consumes sim speed multiplier

intent: Make the sprint upgrade real in the hands: player base speed scales by `sim.speed_multiplier()`. Spec FL-8 (sprint's scene half).

files in scope:
- PRIMARY: `godot/scripts/gizmo.gd`
- also (only if needed to pass the multiplier through): `godot/scripts/game_controller.gd`
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd.

grounding: GZ-002 exposes `speed_multiplier()`; ADR-0002 keeps player movement scene-side, so the multiplier crosses the bridge as a plain float each frame (or on upgrade_chosen — builder's call, record it in the PR).

decisions made: dash burst (GZ-010) multiplies ON TOP of sprint (×2.4 × sprint) — recorded, matches ts:652 structure.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with a NEW test: sprint rank 2 → measured walk displacement over 1s ≈ base × 1.18 (±5%).
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: sprint picks visibly change movement; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-002; if GZ-010 already landed, respect its dash math (not blocking).
model routing: **Haiku** — one multiplier, one test.
cross-domain: none.
status: blocked:GZ-002
format: one issue per file (gh import later).
