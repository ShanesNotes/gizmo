# First-Level Visual Asset Backlog

Date: 2026-06-21
Scope: OMX G006 — image-reference to Meshy asset pipeline for a hookier first level.
Status: forward backlog / historical evidence. The active asset queue now lives
in `/home/ark/gizmo-asset-pipeline/queue/QUEUE.yaml`; current production briefs
live under `/home/ark/gizmo-asset-pipeline/briefs/`. Treat paths in this file as
old intended handoff targets unless a promotion report installs them into the
game repo.

## Meshy/Godot pipeline decision

Use case is **Game Engine / Godot**. For this repo, request
`target_formats: ["glb", "fbx"]` when generating new Meshy world assets:

- `glb` feeds the existing Godot world-kit wrapper/import pipeline directly.
- `fbx` is retained for Blender/game-engine cleanup if topology or animation work is needed.

Preferred quality path: `meshy-6/latest`, `should_texture: true`, `enable_pbr: true`,
`remove_lighting: true`, `should_remesh: true`, `topology: "quad"`,
`target_polycount: 15000-30000` depending on object scale.

## Generated reference images

Historical/local reference records. These files are not present in the active
game checkout unless supplied by a later asset-pipeline run:

1. `godot/assets/reference/first_level/generated/north_beacon_reference.png`
   - Purpose: north destination hook / readable objective landmark.
   - Meshy status: **generated and downloaded** as `clockwork_north_beacon_01`.
2. `godot/assets/reference/first_level/generated/orrery_altar_reference.png`
   - Purpose: central/side landmark, upgrade altar, or future boss-room anchor.
   - Meshy status: queued; use image-to-3D when the next credit spend is desired.
3. `godot/assets/reference/first_level/generated/spark_crystal_cluster_reference.png`
   - Purpose: Spark pickup source / mini-landmark cluster.
   - Meshy status: queued; likely low-poly prop with smaller collision footprint.

## Prioritized backlog

| Priority | Asset | Why it matters | Reference | Suggested target path |
| --- | --- | --- | --- | --- |
| P0 | North beacon tower | Gives the expanded arena a destination hook at the far end. | `north_beacon_reference.png` | `godot/assets/world_kits/clockwork_observatory/clockwork_north_beacon_01.glb` |
| P1 | Orrery gear-ring altar | Strong central landmark / upgrade altar visual. | `orrery_altar_reference.png` | `godot/assets/world_kits/clockwork_observatory/clockwork_orrery_altar_01.glb` |
| P1 | Spark crystal cluster | Makes pickups/resources feel like world objects. | `spark_crystal_cluster_reference.png` | `godot/assets/world_kits/clockwork_observatory/spark_crystal_cluster_01.glb` |
| P2 | Broken bridge arch | Frames negative space between central plaza and side pads. | generate next | `godot/assets/world_kits/clockwork_observatory/broken_bridge_arch_01.glb` |
| P2 | Gear gate / locked door | Future objective and level progression marker. | generate next | `godot/assets/world_kits/clockwork_observatory/clockwork_gate_01.glb` |
| P3 | Small brass scrap clusters | Cheap edge dressing variants for repetition breakup. | existing debris refs okay | `godot/assets/world_kits/clockwork_observatory/scrap_cluster_*.glb` |

## Exact Meshy payloads for queued assets

These payloads are retained as provenance. Current Meshy parameters belong in
the asset-pipeline brief and run ledger before any credit-costing call.

### Orrery altar

```json
{
  "file_path": "/home/ark/gizmo/godot/assets/reference/first_level/generated/orrery_altar_reference.png",
  "ai_model": "meshy-6",
  "model_type": "lowpoly",
  "should_texture": true,
  "enable_pbr": true,
  "image_enhancement": true,
  "remove_lighting": true,
  "should_remesh": true,
  "topology": "quad",
  "target_polycount": 30000,
  "symmetry_mode": "auto",
  "origin_at": "bottom",
  "target_formats": ["glb", "fbx"],
  "texture_prompt": "Godot fixed-camera clockwork orrery gear-ring altar: warm brass rings, dark indigo stone plinth, muted teal crystal core, matte gouache material, clean game-ready readable silhouette, no text."
}
```

### Spark crystal cluster

```json
{
  "file_path": "/home/ark/gizmo/godot/assets/reference/first_level/generated/spark_crystal_cluster_reference.png",
  "ai_model": "meshy-6",
  "model_type": "lowpoly",
  "should_texture": true,
  "enable_pbr": true,
  "image_enhancement": true,
  "remove_lighting": true,
  "should_remesh": true,
  "topology": "quad",
  "target_polycount": 18000,
  "symmetry_mode": "auto",
  "origin_at": "bottom",
  "target_formats": ["glb", "fbx"],
  "texture_prompt": "Godot fixed-camera Spark crystal cluster: teal luminous crystals, brass clockwork roots, dark indigo stone base, matte gouache material, clean low-poly readable game prop, no text."
}
```
