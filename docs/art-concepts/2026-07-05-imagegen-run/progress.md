# Imagegen Progress

Status: in progress
Tool path: built-in imagegen 2.0
Started: 2026-07-05

## Done

- Read active game direction and clean-canvas routing.
- Read AFK queue and P0/P1 asset-pipeline briefs.
- Read sibling visual, lore, level, audio, and asset-pipeline canon.
- Created local run folder and image output folder.
- Generated and saved 11 P0/P1 concept references:
  - `images/island_base_01.png`
  - `images/beacon_01_dormant.png`
  - `images/beacon_01_rekindling.png`
  - `images/beacon_01_rekindled.png`
  - `images/gear_ring_01.png`
  - `images/gizmo_animation_pose_sheet.png`
  - `images/spire_01.png`
  - `images/orrery_altar_01.png`
  - `images/sanctuary_01.png`
  - `images/spark_crystal_cluster_01.png`
  - `images/nibbler_animation_pose_sheet.png`
- Recorded user scale correction: future map concepts must depict expansive rogue-lite
  regions for long traversal, not miniature connected-platform dioramas.
- Generated and saved macro-scale corrections:
  - `images/hearthwake_basin_macro_scale_map.png`
  - `images/hearthwake_basin_macro_open_region.png`
  - `images/hearthwake_playable_footprint_blockout.png`
  - `images/hearthless_rows_macro_region.png`
  - `images/glare_shoals_macro_region.png`
  - `images/colloquy_macro_region.png`
  - `images/fold_macro_region.png`
- Generated future guardian silhouette exploration:
  - `images/guardian_silhouette_sheet_future_scope.png`
- Generated utility concept sheets:
  - `images/island_base_01_turnaround_sheet.png`
  - `images/hearthwake_material_look_sheet.png`
  - `images/core_matrix_icon_concept_sheet.png`

## In Progress

- Consolidate downstream handoff tasks.

## Remaining Imagegen Work

- Optional additional imagegen passes:
  - Region-specific enemy skin sheets at macro-readable silhouette scale.
  - Simplified guardian silhouette sheets with fewer humanoid/armor details.
  - Meshy 3-view turnarounds for remaining approved P0/P1 objects.
  - Material/style sheets for gouache terrain, brass, glass, and drained pressure states.

## Unlocked Downstream Tasks

- Meshy MCP agents: turn approved clean references into GLB/FBX candidates through
  the asset-pipeline queue.
- Blender MCP agents: clean topology, scale, origins, collision proxies, material slots,
  and animation clips after Meshy outputs exist.
- ElevenLabs/API audio agents: generate or convert modular ambience/SFX against the
  region soundscape and audio-canon event grammar.

## Best Current References

- Use `hearthwake_playable_footprint_blockout.png` first for playable scale.
- Use `hearthwake_basin_macro_open_region.png` for Path A macro art tone after scale
  correction.
- Use `beacon_rekindling_siege_key_art.png` for Beacon climax mood.
- Use P0/P1 clean references for Meshy only after asset-pipeline review.
- Treat early `*_region_key_art.png` images as mood boards, not layout scale.
