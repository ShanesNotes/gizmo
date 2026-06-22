# First-level asset pipeline inventory

Generated for ultragoal `G001-inventory-new-assets-and-pipeline` on 2026-06-20.

## Goal

Build the first complete playable 3D Godot level from the strongest available assets before spending more generation credits. Keep the game true 3D, fixed Diablo camera, and small-v1 playable.

## Found assets

### Downloaded references and models outside the repo

These are in `/home/ark/Downloads` and should be copied into `godot/assets/reference/` or a specific asset folder when each story consumes them.

| Asset | Type | Size/shape | Best use |
| --- | --- | --- | --- |
| `Gizmo-Position-the-wooden-robot-standing-firmly-with-fee-max-px-frames-36-rows-6-cols-6.png` | Gizmo walk sprite sheet | 2064x4320, 36 frames, 6x6 | Use as pose/timing reference for `gizmo.tscn` rig tracks; not as 2D gameplay sprite. |
| `nibbler-concept-rigged.glb` | Rigged 3D enemy | 12.4 MB, 1 mesh, 1 skin, 59 joints, 0 animations | Best candidate for G003 enemy replacement; animate locally in Blender/Godot or with Meshy rig/animate only if needed. |
| `nibbler-concept.glb` | Unrigged 3D enemy | 10.6 MB, 1 mesh, 0 skins, 0 animations | Backup enemy mesh / comparison asset. |
| `nibbler-solo-concept.jpg` | Painted reference | 1792x1008 | Meshy/image-to-3D or material/silhouette reference. |
| `nibbler.jpg` | Painted reference | 1792x1008 | Enemy art-direction reference. |
| `clockworkfloortilevariantsheet.jpg` | Painted tile sheet | 1792x1008 | Primary floor/pattern reference for G002 tile variants. |
| `stone-floor-tile-variant.jpg` | Painted tile reference | 1792x1008 | Secondary tile color/material reference. |
| `edge-pylon-beacon.jpg` | Painted pylon reference | 1792x1008 | Primary pylon/landmark reference for G002. |
| `nebula-sky.jpg` | Sky reference | 1280x720 | Already mirrored as `godot/assets/sky/nebula_sky.jpg`; use for sky/panorama look. |

### Current Godot 3D assets

| Asset | Notes | Current use |
| --- | --- | --- |
| `godot/assets/gizmo.glb` | 12.7 MB, rigged, 53 joints, no imported animation clips | Instanced by `godot/scenes/gizmo.tscn`; local Godot AnimationPlayer drives movement/bone tracks. |
| `godot/assets/enemies/nibbler_01.glb` | 1.0 MB, unrigged Meshy enemy, no materials/images | Instanced by `godot/scenes/enemy.tscn`; currently styled by `GeneratedMeshStyler`. |
| `godot/assets/world_kits/clockwork_observatory/clockwork_floor_tile_01.glb` | 0.8 MB, unrigged/static Meshy tile | Wrapped by `clockwork_floor_tile_01.tscn`; proxy polish currently gives more readable art. |
| `godot/assets/world_kits/clockwork_observatory/clockwork_edge_pylon_01.glb` | 1.0 MB, unrigged/static Meshy pylon | Wrapped by `clockwork_edge_pylon_01.tscn`. |
| `godot/assets/sky/nebula_sky.jpg` | 1280x720 nebula reference | Available for sky/background experiments; `main.tscn` currently uses shader sky. |

### Current concept-art anchors

Use these as art direction, not as active 2D gameplay architecture:

- `design-handoff/gizmo-hud.png` — strongest first-level target: brass UI/material language, cosmos atmosphere, floating stone platforms.
- `design-handoff/concept art/gizmo-world-concept-1..5` — floating island/world tone.
- `design-handoff/concept art/gizmo-trashmob-1.jpeg`, `gizmo-trashmob-2.jpeg`, `gizmo-dario-trash.jpeg` — enemy family language.
- `design-handoff/concept art/tower-concept.jpeg`, `clockwork-heartbeat.jpeg`, `workshop-concept.jpeg`, `spark-concept.jpeg` — prop/objective references.

### Audio assets

New imported ambience/SFX in `godot/audio`:

| Asset | Duration | Best use |
| --- | ---: | --- |
| `ambiance/core-matrix-long.mp3` | 162.85s | Main level bed or playlist anchor. |
| `ambiance/core-matrix.mp3` | 53.05s | Shorter core ambience loop. |
| `ambiance/beacon-proximity-long-2.mp3` | 52.22s | Beacon/objective proximity layer. |
| `ambiance/beacon-proximity-long.mp3` | 24.50s | Short beacon proximity layer. |
| `ambiance/machine-swarm.mp3` | 16.00s | Mechanical bed/loop layer. |
| `ambiance/pulsing-machine-swarm.mp3` | 11.02s | Pulse layer for pressure/combat. |
| `ambiance/energy-wisp-wind.mp3` | 9.56s | Magic/cosmos ambience layer. |
| `ambiance/beacon-pulse.mp3` | 16.00s | Beacon landmark loop. |
| `ambiance/chain-tension.mp3` | 16.00s | Tension/level pressure layer. |
| `ambiance/tower-banging.mp3` | 16.00s | Landmark/far machinery stinger/loop. |
| `ambiance/scrap-skitter.mp3` | 14.00s | Nibbler/skitter ambience or enemy loop candidate. |
| `ambiance/distant-stone-fracture.mp3` | 14.00s | Environmental stinger. |
| `sfx/foot-contact.mp3` | 0.76s | Gizmo footstep or contact one-shot. |

Soundtrack source files were moved to `/home/ark/gizmo-audio-canon/sources/soundtrack/*.mp4`; `godot/audio/` is reserved for explicit Godot-ready imports. Godot gameplay audio should use `AudioStreamMP3`, `AudioStreamOggVorbis`, or WAV for short SFX. Convert selected source cues to `.ogg` or `.mp3` before playlist wiring.

## Current Godot scene usage

- `godot/scenes/main.tscn` contains `ArenaTiles`, 3x3 floor kit, four pylons, `WorldEnvironment`, `Gizmo`, and `GameController`.
- `godot/scenes/enemy.tscn` uses `res://assets/enemies/nibbler_01.glb` and `EnemyVisual`.
- `godot/scripts/simulation.gd` already emits transient events: `attack`, `hit`, `defeat`, `pickup`, `levelup`. These are the right hooks for G006 VFX/audio.
- `godot/scenes/spark.tscn` exists for pickup visuals.
- No dedicated audio manager, ambience scene, music playlist, or VFX event consumer is currently wired into `main.tscn`.

## Blender and generation availability

- Blender is available locally: `Blender 5.1.2`.
- Useful Blender jobs:
  1. Inspect/import `nibbler-concept-rigged.glb`.
  2. Add or bake a simple looping walk/skitter animation if no clip is present.
  3. Export GLB back into `godot/assets/enemies/`.
  4. Optionally clean scale/origin/material names.
- Meshy balance check is free and reports `3075` credits available.
- Existing Meshy tasks available:
  - `019ee729-0b25-72ce-b022-a61fef84d5b2` floor tile.
  - `019ee729-2048-7452-87d7-aa371604784c` edge pylon.
  - `019ee730-a647-73a5-93f1-964386c56e55` nibbler/trash mob.

## Meshy spend candidates

Spend credits only when the deterministic local asset path is worse than generated output.

1. **Likely worth it later: hero objective/landmark prop**
   - Use image/text-to-3D from `tower-concept.jpeg`, `clockwork-heartbeat.jpeg`, or a new painted beacon reference.
   - Output: GLB for Godot.
2. **Maybe worth it: stronger enemy family member**
   - Use `nibbler.jpg` / `nibbler-solo-concept.jpg` for image-to-3D if the downloaded rigged GLB looks bad in-game.
   - Output: GLB; rig only if the generated model is actually better.
3. **Probably not first: more random floor tiles**
   - The downloaded floor concept sheets plus proxy geometry are likely enough for G002.
   - Meshy floor rerolls should wait until layout/material direction is approved.
4. **Possible but not default: Meshy rigging**
   - `meshy_rig` costs 5 credits and includes walk/run, but it needs a Meshy task id or public model URL. Since `nibbler-concept-rigged.glb` is already rigged locally, try Blender/Godot first.

## Recommended implementation order

1. **G002 arena** — copy floor/pylon reference images into `godot/assets/reference/`, expand `main.tscn` into a larger first-level platform, and add tile/edge/cosmos/debris variants using Godot-native meshes plus existing kit scenes.
2. **G003 Nibbler** — import/copy `nibbler-concept-rigged.glb`, compare against current `nibbler_01.glb`, then animate via Blender/Godot fallback. Use `scrap-skitter.mp3` or later SFX for enemy feedback.
3. **G004 Gizmo** — copy/use the 36-frame walk sheet as pose timing reference; adjust existing rig tracks rather than switching to sprites.
4. **G005 Audio** — add an `AudioDirector`/scene in Godot; wire ambience layers and convert 1-3 playlist candidates from the audio-canon source pack to `.ogg`.
5. **G006 VFX/SFX** — consume `simulation.gd` events in `GameController` or a small feedback director; add beam/hit/spark VFX and one-shots.
6. **G007 Final** — screenshot review, scene validation, full relevant tests, cleanup, independent review, checkpoint.

## Risks and constraints

- The newly mentioned downloaded sprite sheets are outside the repo; do not rely on them until copied under `godot/assets/reference/` or an import folder.
- The rigged Nibbler has a skin but no animation clips; animation work is still required.
- The audio-canon source `.mp4` files should be converted before gameplay use; Godot-native audio should be MP3/OGG/WAV.
- Current rendering screenshots need a display server or a manually running Godot editor; headless tests are reliable for parse/regression checks, but not visual verdict screenshots.
