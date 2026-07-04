# GZ-019 — Tests: balance gate with upgrades + elites

intent: Turn the balance north star into executable gates: TTK bands hold with drafted builds, the offer pool can't exhaust mid-run, spawn pressure stays clearable. Spec FL-2/FL-3/FL-7 verification.

files in scope:
- PRIMARY: `godot/tests/run_balance_tests.gd`
- DO NOT touch: simulation.gd (if a gate fails, the ticket FAILS with a report — tuning fixes are a new ticket; validators reject, they don't silently retune).

grounding:
- TTK bands: reference/game-balance-reference.md §5.4 — trash ≤ ~0.7s (v1 cadence deviation recorded at simulation.gd:84), bruiser 1–3s, elite 3–10s.
- Pool exhaustion check: §7.5 — ExpectedRunPicks ≤ AvailableMeaningfulPicks (7 upgrades' maxRanks: 8+6+6+5+5+4+5 = 39 picks available; assert expected level-ups over a 240s pressure horizon stay under this with margin).
- Spawn vs clear: §6.1–6.2 (`ClearPressure ≥ SpawnPressure` at intended power) — approximate with a scripted median build (spark 3, pulse 2, magnet 1) auto-playing a stationary-kite harness.
- Existing suite: run_balance_tests.gd (366 lines) — extend, don't rewrite.

decisions made:
- Median-build harness: deterministic seed, fast-forward 180s, assert (a) player alive with the scripted build under default zones, (b) enemy population stays under a sane cap (no unbounded backlog), (c) elite TTK with the same build inside 3–10s.
- These are RED-LINE gates, not tuning: tolerances generous (±30%) so they catch breakage, not drift.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_balance_tests.gd` exits 0 including NEW assertions: trash/bruiser/elite TTK bands with rank-0 and median builds; pool-exhaustion inequality; 180s median-build survival harness.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: any future sim change that breaks the loop's math turns the gate red; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-004 (all three weapons), GZ-009 (elites). Parallel-safe vs scene/UI lanes.
model routing: **Sonnet** — test authoring against a stable API; math is provided.
cross-domain: none.
status: blocked:GZ-004,GZ-009
format: one issue per file (gh import later).
