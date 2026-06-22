# First-level expansion audit — audio, procedural layout, and asset pipeline

Date: 2026-06-21
Scope: OMX G002 for the expanded first-level redesign ultragoal.

## Current slice: what is working

- **Playable 3D foundation is real.** `godot/scenes/main.tscn` has a fixed-camera 3D scene with `Gizmo`, `GameController`, `GameAudio`, `FeedbackFx`, a cosmos `WorldEnvironment`, 21 floor-tile instances, and 8 edge pylons.
- **Feedback seam is correct.** `Simulation.last_events` stays rules-side; `GameController.simulation_events_emitted` bridges to scene-side `FeedbackFx`, which routes SFX through `GameAudio` and spawns simple `GPUParticles3D` bursts.
- **World-kit wrappers are the right pattern.** `WorldKitPiece` wraps Meshy/Blender output under `MeshyImportSlot`, keeps art-direction proxy geometry where needed, exposes `piece_id`, `placement_role`, `footprint_meters`, and collision checks.
- **Existing generated assets are enough for expansion.** Available local GLBs include floor tile, edge pylon, island base, and two floating debris pieces under `godot/assets/world_kits/clockwork_observatory/`.
- **Blender pipeline exists and works locally.** `tools/blender/gen_floating_islands.py` can generate `clockwork_island_base_01.glb`, `clockwork_debris_01.glb`, and `clockwork_debris_02.glb`; Blender 5.1.2 is installed.
- **Visual reference backlog exists.** `docs/world-asset-prompts.md` already defines the correct image-model → Meshy image-to-3D direction for island, gear-ring, platform, spire, beacon, debris, orrery, and Spark crystal assets.

## Main problems to fix

### 1. Ambience is too busy

Current defaults in `GameAudio` layer four simultaneous ambience streams:

1. `core-matrix-long.mp3`
2. `energy-wisp-wind.mp3`
3. `first_level_machine_swarm.ogg`
4. `first_level_beacon_pulse.ogg`

Those all start automatically through identical `AudioStreamPlayer`s at `ambience_layer_volume_db = -6.0` on an `Ambience` bus at `-18.0 dB`. The structure works, but the design is dense: long bed + airy wind + machine swarm + beacon pulse means the level never gets quiet. For a first hook scene, the player needs **quiet wonder**, not constant machinery.

**Keep:** runtime bus/player structure, stream duplication/loop flags, tests for missing assets.

**Change next:** default to two calm layers only, lower the ambience bus and layer gain, and make machine/beacon/tower sounds explicit accent/proximity layers rather than always-on bed.

### 2. SFX are prototype placeholders

Current event SFX are short local mono WAVs:

- `spark_attack.wav` — 0.180s, peak about -5.6 dBFS
- `spark_hit.wav` — 0.140s, peak about -4.1 dBFS
- `spark_defeat.wav` — 0.420s, peak about -4.4 dBFS
- `spark_pickup.wav` — 0.220s, peak about -3.4 dBFS
- `spark_levelup.wav` — 0.580s, peak about -6.4 dBFS

They are technically correct for low-latency Godot playback, but the sonic shape is arcade-like: bright, tiny, and not tied enough to Gizmo's brass/stone/Spark identity.

**Keep:** WAV format, mono, SFX pool, event mapping tests.

**Change next:** regenerate local layered SFX with warmer transient design: brass knock, stone grit, spring/gear tick, glassy Spark shimmer, short clean tails, no laser/cartoon tone.

### 3. Level footprint is still a compact test platform

`main.tscn` currently uses 21 tile instances in a compact diamond/rectangle from roughly `x=-4..4`, `z=-4..4`, with pylons at `±6` / corners. It proves the world-kit seam, but it reads like a board, not an enticing first-level space.

**Keep:** tile kit, edge pylon kit, cosmos sky, fixed camera, existing collision/readability tests.

**Change next:** move from a single compact board to a larger authored/procedural island path: spawn court, central clockwork plaza, side alcoves, beacon approach, satellite stepping islands, debris silhouettes, and perimeter landmarks.

### 4. Procedural pipeline is present but not integrated

The current procedural/asset pipeline is split across:

- `tools/blender/gen_floating_islands.py` — geometry generation for island/debris GLBs.
- `docs/world-asset-prompts.md` — image reference prompts for Meshy image-to-3D.
- `docs/meshy-world-kit-generation-log.md` — successful text-to-3D Meshy proof for tile/pylon.
- `godot/scenes/world_kits/...` — wrappers only for floor tile and edge pylon.

The missing bridge is Godot-side wrapper scenes for `clockwork_island_base_01`, `clockwork_debris_01`, and `clockwork_debris_02`, plus a deterministic layout generator/fixture that places pieces into the main scene or a generated scene.

**Keep:** Blender-generated GLBs for greybox/large silhouettes; Meshy/image-gen reserved for hero props and higher-value objects.

**Change next:** add wrapper scenes and a small deterministic layout script/resource so tests can prove count, footprint, zones, and landmarks.

## Meshy/image-generation pipeline decision

Meshy text-to-3D worked for tile/pylon, but the current art critique points toward a better path:

1. Generate clean painted reference images for hero props with the image model.
2. Use Meshy image-to-3D or multi-image-to-3D for selected hero objects.
3. Import as GLB/FBX into `godot/assets/world_kits/clockwork_observatory/`.
4. Wrap in `WorldKitPiece` scenes with scale, collision, material readability, and tests.

Best candidates for actual Meshy spend, in order:

1. `beacon_01` — objective prop/hook; high player meaning.
2. `clockwork_gear_ring_01` — distant silhouette/landmark; defines the fantasy.
3. `clockwork_spire_01` — vertical map landmark; improves edge readability.
4. `clockwork_orrery_prop_01` — dressing prop for curiosity/scale.
5. `spark_crystal_01` — readable pickup/objective dressing.

Do **not** spend credits on more random floor tiles yet; the existing floor wrapper plus procedural placement is enough until the larger layout reads well.

## Safe implementation order

1. **Audio ambience redesign** — small code/test change: default two layers, quieter buses, accent layer metadata.
2. **SFX replacement** — local WAV generation and path-stable replacement, preserving event API.
3. **World-kit wrappers for island/debris** — static scenes/tests using existing GLBs.
4. **Expanded layout generator/scene integration** — deterministic coordinates, larger zones, tests updated from 21 tiles to expanded layout metrics.
5. **Image-reference/Meshy backlog** — generate top reference images and prepare Meshy prompts; spend credits only if the tool surface is available and the asset is high-value.
6. **Final review gate** — full Godot validation, visual evidence, ai-slop-cleaner, independent review.

## Verification anchors for later stories

- Audio: `godot/tests/run_game_audio_tests.gd`, `godot/tests/run_feedback_fx_tests.gd`.
- World kit: `godot/tests/run_world_kit_tests.gd`, `godot/tests/run_playable_slice_tests.gd`.
- Current visual reference screenshot: `godot/.mcp/screenshots/screenshot_1782013901_61914.png`.
- Meshy pipeline docs: `docs/world-asset-prompts.md`, `docs/meshy-world-kit-generation-log.md`, `docs/meshy-world-kit-prompts.md`.
