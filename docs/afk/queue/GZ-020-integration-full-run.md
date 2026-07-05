# GZ-020 — Tests: headless full-run integration (win path + loss path)

intent: The whole loop, proven end-to-end in one headless script: spawn → fight → collect → level → draft → survive crest → reach beacon → rekindle → PHASE_COMPLETE; and the mortal mirror: guard gone → HP attrition → PHASE_GAMEOVER. Spec: all FL-* joined.

files in scope:
- PRIMARY (new): `godot/tests/run_integration_tests.gd`; register in `tools/godot/run_all_checks.sh` in BOTH arrays (`scripts=(...)` for --check-only and `tests=(...)` for execution — verified structure)
- DO NOT touch: any script or scene — this ticket only OBSERVES. If it can't pass without changing production code, it fails with a report naming the gap (new ticket).

grounding:
- Win/lose law: ADR 0005; loop statement: SPEC "The loop"; sim API surface as of GZ-009 (upgrades, guard, zones, region, elites, beacon).
- Test style precedent: run_simulation_tests.gd (598 lines, headless SceneTree scripts).

decisions made:
- Two scripted scenarios, deterministic seeds, sim-level only (no rendering):
  - WIN: authored zone set (spec §4 table), scripted player path south→north with scripted choose_upgrade picks at each draft, park inside beacon radius, assert Rekindling→Rekindled→PHASE_COMPLETE, assert exposure hit 1.0 during the hold, assert ≥1 elite was faced, assert ≥2 drafts occurred.
  - LOSS: player parked in the beacon dais from t=0 with no upgrades chosen (auto-skip drafts by choosing first offer), assert guard depletes before HP, HP reaches 0 → PHASE_GAMEOVER.
- Wall-clock budget: each scenario fast-forwards with large-but-clamped dt steps (MAX_DT law, simulation.gd:23); full runner must finish < 60s wall time.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_integration_tests.gd` exits 0 with both scenarios passing and printing a one-line run summary each (elapsed, level, kills, outcome).
2. `tools/godot/run_all_checks.sh` exits 0 (now includes the integration runner).

acceptance / done: one command proves the fun loop exists as a system; this becomes v1's ship gate; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-009 (full sim surface), GZ-012 (draft flow semantics), GZ-015 (authored zones — test may inline the table but must match it). Final ticket on the critical path.
model routing: **Opus** — cross-system choreography; failure diagnosis needs judgment.
cross-domain: none.
status: blocked:GZ-009,GZ-012,GZ-015
format: one issue per file (gh import later).
