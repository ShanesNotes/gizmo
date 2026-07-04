# GZ-033 — Game: swap greybox island/beacon for installed P0 assets

intent: The island becomes painterly: replace the greybox floor and beacon placeholder with the validated q01/q02 wrapper scenes; keep every gameplay coordinate (zones, anchors, spawn) exactly where the spec §4 table put them.

files in scope:
- PRIMARY: `godot/scenes/main.tscn`
- tests: `godot/tests/run_game_controller_tests.gd` (existing zone/beacon assertions are the regression net)
- DO NOT touch: installed wrapper scenes under `godot/assets/` (asset-lab law: derived, do not edit as source), simulation.gd, zone metadata values.

grounding: asset_pipeline_to_game seam (ecosystem yaml): installs land as wrapper .tscn + GLB + metadata under `godot/assets/<category>/<asset_id>/`. ADR 0008: curated scene composition is human/agent authoring in the game repo; the wrappers carry role/footprint/collision metadata.

decisions made:
- Instance q01 island wrapper as the ground; align so the spec §4 marker coordinates remain valid (move the ASSET to fit the coordinates, never the markers — coordinates are the live authority, spec §4).
- Instance q02 beacon wrapper at (0,0,-42); GZ-017's state→light mapping re-targets to the wrapper's light node if names differ (small game_controller.gd touch allowed).
- If the wrapper's collision footprint shrinks the playable area, author/update the `WalkableRegion` polygon (GZ-007 API) to match the new footprint in the same diff.
- q03 gear ring placed at CentralGearPlazaZone (0,0,-12) as the landmark read; q04 clips: if an AnimationLibrary installed for Gizmo, wire walk clip only (idle/attack wiring deferred E9).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --import` exits 0; `tools/godot/run_all_checks.sh` exits 0 (all existing zone/beacon/controller tests green, unmodified in meaning).
2. NEW test: sim.spatial_exposure_at() values at the six marker positions unchanged from pre-swap recordings (world dressing changed nothing mechanical).

acceptance / done: same loop, painterly island; a screenshot at the gameplay camera is attached to the PR as evidence; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-030 (installs), GZ-015 (markers), GZ-017 (beacon mapping). NOT parallel-safe with other main.tscn tickets.
model routing: **Sonnet** — scene composition against locked coordinates.
cross-domain: consumes asset-pipeline installs; wrappers are read-only here.
status: blocked:GZ-030,GZ-015,GZ-017
format: one issue per file (gh import later).
