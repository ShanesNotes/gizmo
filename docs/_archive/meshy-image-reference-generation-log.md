# Meshy Image-Reference Generation Log

Date: 2026-06-21
Scope: OMX G006.

## Image generation references

Built-in image generation produced three project-bound references, then the PNG
payloads were extracted from the Codex session log into:

- `godot/assets/reference/first_level/generated/north_beacon_reference.png`
- `godot/assets/reference/first_level/generated/orrery_altar_reference.png`
- `godot/assets/reference/first_level/generated/spark_crystal_cluster_reference.png`

## Meshy spend

User had already authorized Meshy spending. After presenting the concrete cost,
one top-priority asset was generated with Meshy image-to-3D:

- Asset: `clockwork_north_beacon_01`
- Reference: `/home/ark/gizmo/godot/assets/reference/first_level/generated/north_beacon_reference.png`
- Tool: `meshy_image_to_3d`
- Model: `meshy-6`
- Cost: 20 credits
- Task ID: `019ee889-5b2c-7e4f-a748-f054e1d3b2f4`
- Status: `SUCCEEDED`
- Requested target formats: `glb`, `fbx`
- Downloaded format: `glb`
- Download path: `godot/assets/world_kits/clockwork_observatory/clockwork_north_beacon_01.glb`
- Texture sidecars downloaded:
  - `clockwork_north_beacon_01_base_color.png`
  - `clockwork_north_beacon_01_metallic.png`
  - `clockwork_north_beacon_01_roughness.png`
  - `clockwork_north_beacon_01_normal.png`
  - `clockwork_north_beacon_01_emission.png`

Wrapper scene:

- `godot/scenes/world_kits/clockwork_observatory/clockwork_north_beacon_01.tscn`

## Notes

The orrery altar and Spark crystal cluster references are deliberately queued but
not generated yet to avoid spending another 40 credits before the beacon is seen
inside the level. Their exact Meshy payloads live in
`docs/first-level-visual-asset-backlog.md`.
