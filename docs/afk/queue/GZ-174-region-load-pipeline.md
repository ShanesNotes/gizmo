# GZ-174 — P3 (game): region load pipeline

intent: One island today becomes N: main.tscn refactors into a region-agnostic shell (sim, controller, HUD, camera) + per-region world scenes (`godot/scenes/regions/<region_id>.tscn`) instanced by the flow on region_selected.
files in scope: PRIMARY: `godot/scenes/main.tscn` restructure + `godot/scripts/game_controller.gd` (load path); (new) `godot/scenes/regions/hearth.tscn` = today's island content extracted verbatim; tests: run_game_controller_tests.gd. DO NOT: change any zone coordinate or gameplay value — this is a pure re-plumbing (exposure regression test is the proof).
grounding: ADR 0010 (scene-per-region, no streaming); GZ-015/033's zone/asset layout (moves intact); ADR 0002 (the shell owns the bridge; region scenes are pure world: geometry, zones, anchors, beacon).
decisions made: region scene CONTRACT (recorded; REGION-TEMPLATE cites it): root Node3D named `Region`, children `LevelZones` (markers per GZ-015 metadata law), `WalkableRegion`, `BeaconAnchor`, `PlayerSpawn`, `ShopAnchor` (optional), `Kit` (dressing). Controller discovers by name — a region that violates the contract fails loudly at load (assert, not silent nulls).
executable success criteria: hearth.tscn loads through the new path and the GZ-033 exposure-regression values at all six markers are IDENTICAL; full suite green; a deliberately contract-violating test region asserts a clear error. Gate green.
dependencies / order: blockedBy GZ-173, GZ-033 (final island layout). Blocks all REGION-* builds. Cluster B — exclusive.
model routing: **Opus** — the riskiest refactor in the plan; regression-guarded re-plumbing.
status: deferred:P3
