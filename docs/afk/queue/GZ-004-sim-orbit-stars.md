# GZ-004 — Simulation: Orbit Stars weapon

intent: Third weapon — circling stars that clip enemies close to Gizmo. Fills the mid-range kiting niche. Spec FL-2/FL-8.

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: scenes/VFX, other scripts.

grounding:
- Source: ts:859–873 (fires on its own timer when `upgrades.orbit > 0`, damages a nearby target; orbit geometry ts:575–581 — count/radius grow with rank).
- Defs: ts:283–290 (maxRank 6, unlockLevel 2, weight 0.96, color #ff79c6).

decisions made (recorded v1 numbers):
- Sim keeps orbit ABSTRACT (ADR-0002: data + math): star count `1 + floor(r/2)`, orbit radius `1.8 + 0.15*r` m, angular speed 2.4 rad/s, each star damages (1) any enemy within 0.5 m of its computed position, per-enemy hit cooldown 0.5s to avoid multi-tick shredding. Star positions derivable by the scene from `orbit_state()` (angle, radius, count) — sim exposes that accessor; rendering is a later ticket's concern.
- Basis: balance §5.4 (trash ≤0.5s near player), §2 (close-range pack value; penalty = requires proximity).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) rank 0 → orbit_state().count == 0 and no orbit damage; (b) rank 1 → an enemy parked on the orbit ring takes damage within one revolution, an enemy at player center or far outside does not; (c) per-enemy hit cooldown enforced (≤ 3 hits in 1.2s); (d) rank 2 vs rank 1 → count or radius increases.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: orbit rank drafted → ring damage provable in headless tests; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-003 (sim-lane serialization). Blocks GZ-005.
model routing: **Sonnet** — contained port; geometry is simple parametric math.
cross-domain: none.
status: blocked:GZ-003
format: one issue per file (gh import later).
