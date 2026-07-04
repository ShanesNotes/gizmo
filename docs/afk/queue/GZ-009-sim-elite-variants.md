# GZ-009 — Simulation: elite variants (director's special threats)

intent: Late-run pressure texture without wave rounds: the director periodically injects an elite — a scaled variant of an existing kind — on an internally compressing interval. ADR 0003's "special threats". Spec FL-3.

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: HUD (no elite announcements/counters — pressure is diegetic, spec §7), enemy.tscn (visual scale mirroring is GameController's existing radius-driven concern).

grounding:
- Source: ts:674–676 — first elite at elapsed ≥ 55 (`nextEliteAt: 396`), then `nextEliteAt += 48 − min(20, wave*2.6)` (interval compresses 48s → 28s). "wave" here is INTERNAL director bookkeeping only — keep the internal counter name `elite_index`; never surface it (ADR 0003).
- Elite scaling: elite flag ts:56; TTK target = elite band 3–10s per balance ref §5.4.
- Existing kind stats: simulation.gd:34–65; enemy struct carries radius/hp/xp already.

decisions made (recorded v1 numbers):
- Elite = existing kind with hp ×3.5, radius ×1.3, speed ×0.9, xp ×3, `elite: true` on the enemy record (mirrors ts elite-HP band ×3.65–5.14 at the low end; TTK with rank-2 spark ≈ 3–6s → inside band).
- Elite kind chosen from kinds currently unlocked, weighted toward the newest unlock (recorded call: mirrors chooseEliteKind intent; cite ts:675).
- Elite spawns bypass the budget (they are director punctuation, not budget spend) but respect walkable-region validation (GZ-007).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) fast-forward to 54s → zero elites; past 55s → exactly one; (b) interval compresses: 3rd gap < 1st gap, floor 28s respected; (c) elite hp/xp/radius scaled per numbers; (d) elite death drops ×3 XP and increments kills; (e) no elite before its base kind's unlockAt.
2. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_balance_tests.gd` exits 0 (existing suite unregressed; new elite-TTK assertion lands in GZ-019).
3. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: long runs grow spikes, not rounds; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-008 (sim-lane serialization). Last sim-lane ticket; unblocks GZ-019, GZ-020.
model routing: **Sonnet** — additive, well-anchored port.
cross-domain: none.
status: blocked:GZ-008
format: one issue per file (gh import later).
