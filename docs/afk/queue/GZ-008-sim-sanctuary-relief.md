# GZ-008 — Simulation: sanctuary relief drives guard recharge (ADR 0007 × 0006)

intent: The Sanctuary lets Gizmo regain his protective light: standing in a sanctuary-role zone shortens guard-recharge delay and raises the rate. It never heals HP. Anti-camp stays structural. Spec FL-9 (sanctuary half).

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: HUD, scenes.

grounding:
- ADR 0007: sanctuary (relief-role PressureZone, ADR 0006) shortens delay / raises recharge rate; recovery capped; camping dominated by rising pressure_clock; canon "The Sanctuary does not undo mortality…". NEVER "sanctuary heals HP".
- Seam prepared by GZ-005: `set_guard_recharge_modifier(rate_mult, delay_mult)`; zone data from GZ-006 (role == "sanctuary", relief_multiplier).

decisions made (recorded v1 numbers):
- Each tick, if gizmo_position is inside (d < radius) a sanctuary-role zone: rate_mult = 2.5 × relief_multiplier-normalized weight, delay_mult = 0.5; outside all sanctuaries: 1.0/1.0. Overlapping sanctuaries do not stack beyond the single strongest (recorded call: stacking invites degenerate authoring).
- Sanctuary relief also multiplies LOCAL spatial exposure via the zone's own low exposure value — no extra pressure discount here (avoids double-dipping; ADR 0006's exposure already encodes relief).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) inside sanctuary, guard recharge begins at ≤ 2.0s since damage and fills at 1.5 guard/s (2.5 × 0.6); (b) outside, GZ-005 baseline unchanged (regression pair); (c) HP never rises inside a sanctuary; (d) temporal_pressure() keeps rising while camped in sanctuary (anti-camp assertion over a 60s fast-forward); (e) two overlapping sanctuaries == strongest single one.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: breath-before-the-beacon works: duck into sanctuary, guard returns faster, world keeps getting crueler; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-007 (sim-lane serialization; logically needs GZ-005 seam + GZ-006 zones, both upstream). Blocks GZ-009.
model routing: **Sonnet** — two established seams joined by explicit numbers.
cross-domain: sanctuary_breath semantics originate in gizmo-level-design canon; consume the ADR 0007 projection only.
status: blocked:GZ-007
format: one issue per file (gh import later).
