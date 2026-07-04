# GZ-015 — Scene: author pressure zones in main.tscn + controller registration

intent: The island tells the director how dangerous each place is: author the spec §4 zone table as LevelZones markers and register each into the sim at startup. Spec FL-13.

files in scope:
- PRIMARY: `godot/scenes/main.tscn` (LevelZones subtree)
- also: `godot/scripts/game_controller.gd` (startup registration loop)
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd (API frozen by GZ-006), DesignProbe_ExposureRanks (non-shipping legend — leave as-is, never player-facing).

grounding — the authored table (path-a spec §4, live coordinate authority = main.tscn):
| node | pos | role | exposure | relief_multiplier |
|---|---|---|---|---|
| SouthLandingZone | (0,0,17) | spawn | 0.15 | 1.0 |
| EastGearAlcoveZone | (18,0,-4) | branch | 0.55 | 1.0 |
| WestScrapAlcoveZone | (-20,0,-4) | branch | 0.65 | 1.0 |
| CentralGearPlazaZone | (0,0,-12) | landmark | 0.55 | 1.0 |
| SanctuaryAnchor (ADD) | (15,0,-31) | sanctuary | 0.35 | 1.0 |
| NorthBeaconDaisZone | (0,0,-42) | beacon | 0.9 | 1.0 |
Exposure numbers are recorded v1 calls mapping spec §4's qualitative ranks (very low/medium/medium-hot/medium/relief/high) onto 0..1; radii: 8.0 m each except SanctuaryAnchor 5.0 (breath, not a district).

decisions made:
- Markers are Marker3D nodes with metadata (`zone_role`, `zone_exposure`, `zone_radius`, `zone_relief`) — no new node class (recorded call: scenes compose, scripts behave; a bespoke PressureZone node adds a class without behavior).
- GameController on _ready: iterate LevelZones children → `sim.add_pressure_zone(...)`; also register the beacon (existing) and, if a `WalkableRegion` polygon node exists, `sim.set_walkable_region(...)` (authoring the polygon itself is optional here; empty = permissive, GZ-007 default).
- Existing marker nodes may already exist with these names — align positions/metadata, don't duplicate.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) after controller ready, sim reports 6 registered zones with the roles above; (b) sim.spatial_exposure_at((0,0,17)) < spatial_exposure_at((0,0,-42)); (c) sanctuary zone present with role "sanctuary".
2. `${GODOT_BIN:-godot} --headless --path godot --import` exits 0; `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: walking south→north measurably raises pressure; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-006 (sim API). Parallel-safe vs UI lane; NOT parallel-safe with GZ-012 (both touch main.tscn/game_controller.gd — land after or rebase).
model routing: **Sonnet** — data authoring + one registration loop.
cross-domain: zone grammar originates in gizmo-level-design canon; this consumes the spec §4 projection already in-repo. Do not open the sibling lab.
status: blocked:GZ-006
format: one issue per file (gh import later).
