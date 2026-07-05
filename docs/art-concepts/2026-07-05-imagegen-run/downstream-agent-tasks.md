# Downstream Agent Tasks

Status: draft handoff

These tasks are unlocked by the imagegen run. Generated images are draft witnesses; the
owning lab must still apply its canon, validators, and promotion gates.

## Meshy MCP Lane

- In `C:/Users/Shane/gizmo-asset-pipeline`, claim q01 through q03 first:
  `island_base_01`, `beacon_01`, `gear_ring_01`.
- Use the clean single-object references, not the cinematic key art:
  - `images/island_base_01.png`
  - `images/beacon_01_dormant.png` as the base mesh candidate
  - `images/beacon_01_rekindling.png` and `images/beacon_01_rekindled.png` as state/material references
  - `images/gear_ring_01.png`
- Then evaluate q05 through q08 from:
  - `images/spire_01.png`
  - `images/orrery_altar_01.png`
  - `images/sanctuary_01.png`
  - `images/spark_crystal_cluster_01.png`
- Do not feed macro region key art directly to Meshy. It is layout/style evidence, not
  clean object reference.
- Before any spend, record the prompt, source image path, model, target polycount, and
  result in the asset-pipeline run ledger.

## Blender MCP Lane

- For Meshy world-kit outputs, prioritize:
  - playable-top flattening and collision proxy on `island_base_01`
  - state material slots and light anchor naming on `beacon_01`
  - aggressive decimation / silhouette preservation on distant `gear_ring_01`
  - collision simplification on `sanctuary_01`
  - isolated emissive material slot on `spark_crystal_cluster_01`
- Use `images/gizmo_animation_pose_sheet.png` only as timing reference for the existing
  Gizmo rig. Do not regenerate or rerig `godot/assets/gizmo.glb`.
- Use `images/nibbler_animation_pose_sheet.png` as enemy timing reference, preserving a
  mechanical faceless shell and avoiding organic scuttle motion.
- Use `guardian_silhouette_sheet_future_scope.png` only after a future guardian ADR opens;
  simplify heavily before any rig/model work.
- Use `hearthwake_material_look_sheet.png` to guide material-slot naming and shader probes;
  do not treat it as a texture atlas.

## Level / Godot CLI Lane

- Use `images/hearthwake_playable_footprint_blockout.png` as the strongest current scale
  reference for Path A.
- Use `images/hearthwake_basin_macro_open_region.png` as the art-direction scale companion.
- Use `images/core_matrix_icon_concept_sheet.png` only for UI ideation after design-system
  review; it is not a final icon set.
- Treat early `*_region_key_art.png` files as mood-only. They are too compressed for
  playable layout scale.
- Any route graph or Godot blockout should preserve:
  - broad combat arenas
  - long travel distance between origin, central plaza, sanctuary, and Beacon
  - optional side pockets and loopbacks
  - distant landmarks that orient without shrinking the route
  - no player-facing wave/counter/timer/danger UI

## ElevenLabs / Audio Lane

- Use macro region images as visual context for generation briefs, but keep audio ids and
  semantics owned by `gizmo-audio-canon`.
- Recommended image-to-audio pairings:
  - `hearthwake_playable_footprint_blockout.png` + `hearthwake_basin_macro_open_region.png`
    for Path A ambience scale and distance.
  - `beacon_rekindling_siege_key_art.png` for `rekindle_siege` and Beacon pressure layers.
  - `hearthless_rows_macro_region.png` for hospitality-without-host ambience.
  - `glare_shoals_macro_region.png` for watched/prismatic exposure ambience.
  - `colloquy_macro_region.png` for convergence/unison pressure.
  - `fold_macro_region.png` for tender museum custody and enclosure.
- Preserve audio-canon hard rules: no lyrics, no choir/voice unless later allowed, no
  countdown beeps, no wave-round language, no generic sci-fi alarms, no Spark/Sparks/guard
  semantic collapse.

## Still Needed

- Human/art-director review to choose which image references become approved inputs.
- Meshy 3-view turnarounds for approved hero pieces if single-image reconstruction drifts.
- A simplified guardian pass with fewer humanoid armor cues.
- Region enemy skin sheets only after the game/level side decides which enemy families are
  actually needed.
- A shader/material probe in Godot before treating gouache screenshots as achievable runtime
  style.
