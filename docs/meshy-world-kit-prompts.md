# Meshy World Kit Prompts — Clockwork Observatory v0

Status: historical / forward prompt seed. The active asset-production queue now
lives in `/home/ark/gizmo-asset-pipeline/queue/QUEUE.yaml`, with current briefs
under `/home/ark/gizmo-asset-pipeline/briefs/`. Keep this file as provenance for
the early floor/pylon prompt direction; do not treat its target paths or checklist
as live implementation state.

Purpose: first Godot-ready world-building tiles for Gizmo's fixed Diablo-style camera. Output format is `glb` for Godot import.

## Cost Gate

Do not run a credit-costing Meshy generation until the user confirms the exact spend.

Recommended first pass:

- `meshy_text_to_3d`
- model: `meshy-5`
- cost: 5 credits per preview
- output: `target_formats: ["glb"]`
- no texture refine until the imported silhouette/scale passes in Godot

Higher-quality option:

- `meshy_text_to_3d`
- model: `meshy-6` / `latest`
- cost: 20 credits per preview
- output: `target_formats: ["glb"]`

## Prompt: clockwork_floor_tile_01

Low-poly modular square stone floor tile for a fixed-camera Godot 3D rogue-lite arena, flat walkable top, 2 meter square footprint, brass rim, subtle teal rune glow in the center, matte gouache texture feel, readable from a Diablo-style camera, clean silhouette, no characters, no text, no background, game asset.

Legacy target path after download. In the current pipeline, install location is
chosen by the asset-pipeline promotion report and `canon/godot-import.yaml`:

```text
godot/assets/world_kits/clockwork_observatory/clockwork_floor_tile_01.glb
```

Legacy wrapper scene target. Current wrappers are authored and proven by the
asset-pipeline lab before handoff:

```text
godot/scenes/world_kits/clockwork_observatory/clockwork_floor_tile_01.tscn
```

## Prompt: clockwork_edge_pylon_01

Low-poly clockwork arena edge pylon landmark for a fixed-camera Godot 3D rogue-lite, brass and dark stone, teal rune light, compact vertical silhouette, marks a floating island boundary, readable from above, matte gouache material feel, no characters, no text, no background, game asset.

Legacy target path after download. In the current pipeline, install location is
chosen by the asset-pipeline promotion report and `canon/godot-import.yaml`:

```text
godot/assets/world_kits/clockwork_observatory/clockwork_edge_pylon_01.glb
```

Legacy wrapper scene target. Current wrappers are authored and proven by the
asset-pipeline lab before handoff:

```text
godot/scenes/world_kits/clockwork_observatory/clockwork_edge_pylon_01.tscn
```

## Import Verification Checklist

- Treat the bullets above as an old local target example, not a current source
  path claim.
- Current promotion must pass the asset-pipeline brief, cleanup, wrapper, proof,
  and promotion-report validators.
- Any game-repo handoff must keep the main gate green:
  `tools/godot/run_all_checks.sh`.
- There is no active `godot/tests/run_world_kit_tests.gd` runner in this repo.
