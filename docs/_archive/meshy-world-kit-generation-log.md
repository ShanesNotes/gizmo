# Meshy World Kit Generation Log

Date: 2026-06-20

Scope: OMX G002 — first world-building tiles for Gizmo's Godot 3D project.

## Credit Spend

User confirmed Meshy credit spend and asked not to stop for another confirmation.

- `clockwork_floor_tile_01`: `meshy_text_to_3d`, `ai_model: meshy-5`, `target_formats: ["glb"]`, 5 credits.
- `clockwork_edge_pylon_01`: `meshy_text_to_3d`, `ai_model: meshy-5`, `target_formats: ["glb"]`, 5 credits.
- Total for this slice: 10 credits.

## Generated Tasks

| Piece | Meshy task id | Status | Local file | Size |
|---|---|---|---|---:|
| `clockwork_floor_tile_01` | `019ee729-0b25-72ce-b022-a61fef84d5b2` | SUCCEEDED | `godot/assets/world_kits/clockwork_observatory/clockwork_floor_tile_01.glb` | 813,920 bytes |
| `clockwork_edge_pylon_01` | `019ee729-2048-7452-87d7-aa371604784c` | SUCCEEDED | `godot/assets/world_kits/clockwork_observatory/clockwork_edge_pylon_01.glb` | 972,668 bytes |

Godot import generated both sidecars:

- `godot/assets/world_kits/clockwork_observatory/clockwork_floor_tile_01.glb.import`
- `godot/assets/world_kits/clockwork_observatory/clockwork_edge_pylon_01.glb.import`

## Wrapper Scenes

- `godot/scenes/world_kits/clockwork_observatory/clockwork_floor_tile_01.tscn`
- `godot/scenes/world_kits/clockwork_observatory/clockwork_edge_pylon_01.tscn`
- `godot/scenes/dev/world_kit_preview.tscn`

Each wrapper has:

- `WorldKitPiece` metadata.
- `MeshyImportSlot/GeneratedGLB` instance.
- Hidden proxy geometry retained as fallback/reference.
- `GeneratedMeshStyler` material tint so the imported GLBs read as brass/stone under the fixed camera.
- Simple collision shape for gameplay tests.
- Fixed-camera readability note.

## Headless Bounds Evidence

Godot importer already converts the Meshy GLBs to Y-up. Wrapper lift values place the generated meshes above the floor plane.

- Floor tile visible bounds: size approximately `(2.014, 0.146, 2.014)`, center approximately `(0.0, 0.079, 0.0)`.
- Edge pylon visible bounds: size approximately `(0.870, 2.012, 0.993)`, center approximately `(0.0, 1.048, 0.008)`.

## Verification

- `godot --headless --path godot --import --quit` generated `.import` sidecars.
- `godot --headless --path godot --script res://tests/run_world_kit_tests.gd` passed: 26 checks.

Runtime screenshot gap: `mcp__godot_runtime.run_project` could not start because this attached tmux has no `DISPLAY` or `WAYLAND_DISPLAY`; headless load/bounds checks are the available evidence in this environment.
