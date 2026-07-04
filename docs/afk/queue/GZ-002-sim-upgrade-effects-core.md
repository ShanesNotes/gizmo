# GZ-002 — Simulation: apply core upgrade effects (spark, magnet, sprint, heart, focus)

intent: Make drafted ranks DO something. Five effects that touch existing systems only (no new weapons). Spec FL-8, FL-6.

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: gizmo.gd (speed consumption is GZ-016), scenes, hud.

grounding:
- spark rank scaling: replace the retired level_bonus autoscale (simulation.gd:361–372) with rank-driven cooldown/targets/damage; drafting spark rank 1 also sets `attack_range` MELEE_RANGE→ATTACK_RANGE (simulation.gd:85–86 comment is the seam). Source analog ts:820–836.
- magnet: pickup radius bonus ts:562 (`260 + rank*58` px world) → metres: `pickup_radius = PICKUP_RADIUS + rank * 0.55`; plus pull motion toward player inside pull radius, speed easing per ts:891–910.
- sprint: expose `speed_multiplier() -> float` = `1.0 + rank * 0.09` (ts:652 analog, 24/266 ≈ 0.09). Sim stores it; gizmo.gd consumes later (GZ-016).
- heart: `max_hp += 1; hp = min(hp + 1... )` heal-now per ts def :309–316 ("Gain max health and heal right now").
- focus: global cooldown multiplier `0.94^rank` applied in `current_attack_cooldown()` (ts "All weapons recharge faster"; reuse ATTACK_LEVEL_COOLDOWN_MULT 0.94, simulation.gd:90, as the per-rank step).

decisions made:
- px→metre conversions use the repo's established relative-balance rule (ADR-0002 "Units: Godot metres... relative balance faithful"); exact constants above are the recorded v1 numbers — do not re-derive.
- Rank-0 spark must equal the pre-GZ-001 level-1 baseline (regression guard).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) spark rank 1 sets attack_range == 5.0; ranks lower cooldown / raise damage-or-targets monotonically; (b) magnet rank raises pickup_radius and a pickup inside pull radius moves closer each tick; (c) heart raises max_hp and heals immediately; (d) focus multiplies current_attack_cooldown by 0.94/rank; (e) speed_multiplier() == 1.0 at rank 0, > 1.0 at rank 1.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: choosing each of the five upgrades measurably changes sim behavior per tests; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-001 (same file; needs ranks + apply dispatch). Blocks GZ-003.
model routing: **Sonnet** — well-specified single-file port with named constants.
cross-domain: none.
status: blocked:GZ-001
format: one issue per file (gh import later).
