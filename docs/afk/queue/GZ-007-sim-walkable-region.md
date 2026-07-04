# GZ-007 — Simulation: walkable region + spawn validation + soft clamp (ADR 0006 §6)

intent: The island owns where combat may exist. Sim gains an authored XZ walkable footprint; ring-spawns validate against it; enemies are soft-clamped back inside after movement. Spec FL-5.

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: main.tscn authoring (region data registration from the scene is GZ-015's follow-up concern), NavigationServer/navmesh (rejected by ADR 0006).

grounding:
- ADR 0006 walkable region: sample candidates → reject outside region → reject obstacle overlap → nearest-valid fallback; enemies post-move soft-clamped inside; obstacles remain simple push-out circles (exists: add_obstacle simulation.gd:431, _resolve_obstacles :444).
- Existing spawn ring: SPAWN_RING 9.0 simulation.gd:38, _spawn_enemy :484.

decisions made (recorded v1 shape):
- Region representation: `set_walkable_region(points: PackedVector2Array)` — a single convex-or-concave XZ polygon; `is_walkable(pos: Vector3) -> bool` via Geometry2D.is_point_in_polygon. Empty region (default) → everything walkable (today's behavior preserved; all existing tests must pass untouched).
- Spawn validation: up to 12 ring samples (golden-angle stepped); all invalid → nearest-valid fallback = closest polygon point to the last sample (SPEC edge cases).
- Soft clamp: after enemy movement, if outside polygon, project to nearest polygon edge point (no bounce, no velocity change) — "soft" means position-only correction.
- Player is NOT clamped by the sim (ADR-0002: player movement stays scene-side; scene collision already contains Gizmo).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) empty region → spawns behave exactly as before (regression pair); (b) with a 20×20 square region and player near an edge, 50 spawns all satisfy is_walkable; (c) an enemy seeded outside is inside after one tick; (d) spawn candidates overlapping an obstacle circle are rejected (spawn lands non-overlapping); (e) nearest-valid fallback fires when the whole ring is outside (player in a tight corner) and still yields a walkable point.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: no enemy ever fights from the void; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-006 (sim-lane serialization). Blocks GZ-008.
model routing: **Sonnet** — well-specified geometry with named Godot APIs.
cross-domain: none (region polygon authored scene-side later; this ticket ships with test-authored polygons).
status: blocked:GZ-006
format: one issue per file (gh import later).
