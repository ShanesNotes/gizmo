# Downstream Agent Tasks From Run 02

Status: active draft

## Meshy.ai Agents

- Use the P0/P1 saved product refs and turnarounds in `images/`:
  - `beacon_01_turnaround_sheet.png`
  - `gear_ring_01_turnaround_sheet.png`
  - `sanctuary_01_turnaround_sheet.png`
  - `spark_crystal_cluster_01_turnaround_sheet.png`
  - `spire_01_turnaround_sheet.png`
  - `orrery_altar_01_turnaround_sheet.png`
  - `platform_small_01_product_ref.png`
  - `bridge_arch_01_product_ref.png`
  - `gear_gate_01_product_ref.png`
  - `debris_cluster_01_product_ref.png`
  - `scrap_cluster_01_product_ref.png`
- Build low-poly-to-mid-poly 3D source models from object sheets only after checking each
  prompt caveat in `prompts.md`.
- Preserve faceless/faced canon and scarce-teal law.
- Do not invent sockets, portals, boss mechanics, or UI meanings from concept art.

## Blender MCP Agents

- Await Meshy outputs or use product refs for blockout meshes.
- Produce game-readable silhouettes from fixed Diablo-style camera distance.
- Keep collision simple: broad walkable surfaces, simple blockers, clear landmark volumes.
- Export Godot-ready GLB candidates with sensible origins, scale, and material slots.
- Use `hearthwake_greybox_playable_scale_map.png` as the strongest blockout reference.
- Use `hearthwake_footprint_long_s_curve_side_pockets.png` and
  `hearthwake_footprint_broken_ring_loopback.png` for route-scale alternatives.
- Use `hearthwake_fixed_camera_sightlines_sheet.png` to validate landmark visibility from
  origin, branch, sanctuary, and Beacon approach views.
- Simplify future-region enemy sheets before modeling: reduce upright armor reads, remove
  pseudo-writing, and preserve faceless mechanical silhouettes.

## Godot / CLI Coding Agents

- Use level-scale concepts as route and landmark references, not final geometry.
- Keep runtime work in `godot/`.
- Do not add wave-round UI, countdowns, boss bars, or exposure meters.
- If consuming asset refs, wire them through the existing asset-pipeline/Godot import path.
- Candidate first route implementation: broad long S-curve trunk with side pockets,
  sanctuary branch, central landmark sightline, and far Beacon approach.
- Use `nibbler_attack_telegraph_pose_sheet.png` for wind-up/lunge/recovery readability
  tests, not as final animation frames.

## ElevenLabs / Audio Agents

- Use visual boards only as mood/material references.
- Keep SFX semantics distinct: guard, HP damage, Sparks pickup, Scrap pickup, Beacon state.
- No generic sci-fi alarm language, no countdowns, and no wave-round stingers.
- Build prompts from:
  - `audio_path_a_mood_board.png`
  - `audio_sfx_material_cue_board.png`
  - `audio_resource_sfx_cue_board.png`

## Lore / Design-System Agents

- Review enemy family sheets for future-region canon only; do not pull future-region
  enemies into Hearthwake Path A.
- Review companion sheets as narrative/ceremony concepts only.
- Review `design_state_beacon_prop_living_vs_hollowed.png` for face-axis clarity and
  simplify the living face before promotion.
- Review `ceremony_codex_landmark_memory_board.png` and
  `ceremony_core_matrix_draft_board.png` as ceremony mood references only.
- Review `future_guardian_silhouette_sheet.png` as future-scope only; simplify away from
  humanoid/armored reads before any model work.
- Review `design_degradation_operators_sheet.png`,
  `design_sanctuary_vs_pressure_contrast.png`, and
  `design_hud_icon_readability_primitives.png` for canon/readability promotion.
