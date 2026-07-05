# Next Imagegen Goal Todo

Status: ready for next art-generation goal
Prepared: 2026-07-05

This is the launch checklist for the next Codex/imagegen art pass. It is based on a
fresh scout of the active game repo plus the clean-canvas siblings:

- `/home/ark/gizmo`
- `/home/ark/gizmo-asset-pipeline`
- `/home/ark/gizmo-design-system`
- `/home/ark/gizmo-level-design`
- `/home/ark/gizmo-lore`
- `/home/ark/gizmo-audio-canon`
- `/home/ark/gizmo-soundtrack`

Previous run output:

- `docs/art-concepts/2026-07-05-imagegen-run/images/`
- 28 images generated.
- Strongest scale references:
  - `hearthwake_playable_footprint_blockout.png`
  - `hearthwake_basin_macro_open_region.png`
  - `hearthwake_basin_macro_scale_map.png`
- Strongest Meshy/product references:
  - `island_base_01.png`
  - `island_base_01_turnaround_sheet.png`
  - `beacon_01_dormant.png`
  - `gear_ring_01.png`
  - `orrery_altar_01.png`
  - `sanctuary_01.png`
  - `spark_crystal_cluster_01.png`

## Non-Negotiable Direction

- Build for a true 3D Godot rogue-lite with fixed Diablo-style camera.
- Map art must prove playable scale first: large landmasses, broad combat arenas, long
  traversal distance, loops, side pockets, and distant sightline landmarks.
- Avoid miniature connected-platform dioramas. Those are pretty but imply a 30-second
  slice, not a 30-minute run.
- No player-facing wave rounds, countdowns, danger meters, boss bars, or exposure UI.
- Beacon Rekindled is the win. HP 0 is the loss.
- Sparks, Scrap, Guard, HP, and Spark of Humanity stay visually and semantically distinct.
- Saturated teal/cyan is scarce: Gizmo eye/core, guard layer, active Beacon core-spark.
- Sparks are violet-bodied with warm inner glow, not teal/blue mana crystals.
- Generated images remain draft witnesses until owning sibling canon promotes them.

## Folder Scout Summary

### Game Repo: `gizmo`

Current need: art references should help Path A become a playable, dressed Hearthwake Basin
without expanding scope beyond the AFK queue.

Useful anchors:

- `CONTEXT.md`
- `docs/path-a-shattered-meridian-spec.md`
- `docs/afk/queue/PHASE-MAP.md`
- `docs/afk/queue/SPEC-fun-loop-v1.md`
- `docs/afk/queue/GZ-030-assets-p0-queue.md`
- `docs/afk/queue/GZ-033-consume-p0-assets.md`
- `docs/art-concepts/2026-07-05-imagegen-run/`

Next imagegen should support:

- GZ-030 asset-pipeline handoff readiness.
- GZ-033 scene consumption after assets install.
- GZ-111/GZ-112 route graph / baker readiness.
- GZ-131/GZ-134 style and hollowed-state probes.

### Asset Pipeline: `gizmo-asset-pipeline`

Current queue still has all items pending. Previous run covered q01-q09 conceptually, but
only q01 has a three-view sheet.

Queue order:

- P0: q01 island base, q02 Beacon, q03 gear ring, q04 Gizmo clips.
- P1: q05 spire, q06 orrery altar, q07 sanctuary, q08 spark crystal, q09 Nibbler clips.
- P2/P3: q10 platform small, q11 bridge arch, q12 gear gate, q13 debris cluster, q14 scrap cluster.

Next imagegen should generate missing Meshy-friendly sheets:

- Three-view turnarounds for q02, q03, q05, q06, q07, q08.
- Clean product refs for q10-q14.
- Optional texture/material reference sheets for each asset class.

### Design System: `gizmo-design-system`

Current need: visual outputs must obey the face-axis, scarce-light law, Beacon vocabulary,
and style-as-world-state.

Generate next:

- Living/faced vs hollowed/faceless state pairs for the same object.
- Degradation operator sheets: de-face, drain, mechanize-repeat, decay.
- Large readable motif sheets: frame threshold, face axis, beacon light, sanctuary vine,
  thread/ribbon path, celestial sun/moon, decay signs.
- Godot-readable gouache material target sheets, not fake final shaders.

Avoid:

- Generic gears/circuits as corruption.
- Teal as decorative tech glow.
- Tiny filigree at HUD/icon size.

### Level Design: `gizmo-level-design`

Current need: art should help level agents see route grammar at playable scale.

Generate next:

- Macro route blockouts for Hearthwake using the route beats:
  warm origin -> discernment branch -> landmark memory -> trial pressure ->
  sanctuary breath -> Beacon Rekindle.
- Alternate Hearthwake footprint options:
  - one huge basin island
  - island plus two large side peninsulas
  - broken-ring route with sanctuary loopback
  - long S-curve road with optional pockets
- Overpaint-style concepts where walkable ground is visually obvious and vertical
  scenery is pushed to the edges.
- Landmark sightline studies from the fixed camera:
  - origin looking toward gear-henge
  - branch looking back to origin
  - sanctuary looking toward Beacon
  - Beacon approach looking back across the whole route.

Avoid:

- Toy-scale chains of platforms.
- Fake platforming affordances.
- Narrow bridges that would not support swarm combat.

### Lore: `gizmo-lore`

Current need: future-region art should express the world questions without implying
unbuilt systems.

Generate next:

- Region enemy skin sheets for the four fixed archetypes:
  - Hearthwake: tinklings, skitters, lugs, stewards.
  - Hearthless Rows: crumbsweeps, fetchlings, butlers, doormen.
  - Glare Shoals: glints, flickers, facets, collectors.
  - Colloquy: postulants, syllogists, adamants, catechists.
  - Fold: latchlings, shepherds, bulwarks, wardens.
- Companion concept sheets:
  - Wick, sanctuary lamp-tender.
  - Marginalia / Margin, scribe-moth of the Codex.
  - Rote, care-automaton stalled into meaning.
- Simplified guardian silhouettes:
  - Host, Panoply, Corollary, High Warden.

Hard caution:

- Guardians are future-scope only. Hearthwake has no bespoke guardian.
- No guardian-slaying as win condition.
- No boss UI, phase language, or villain posing.

### Audio Canon: `gizmo-audio-canon`

Current need: imagegen can produce visual context sheets for ElevenLabs/audio agents, not
audio itself.

Generate next:

- Audio mood boards with no text:
  - warm origin / calibration room
  - first steps / roam
  - trial pressure
  - sanctuary breath
  - Beacon Rekindling siege
  - afterglow release
- SFX visual cue sheets:
  - guard strain / guard recover
  - HP damage
  - pickup Sparks vs pickup Scrap
  - attack Gizmo
  - Nibbler skitter / bite / defeat
  - UI confirm / deny / hover

Rules:

- No wave-round language in image prompts.
- No timer/counter imagery.
- No generic sci-fi alarm visuals.
- Keep audio-resource meanings distinct.

### Soundtrack: `gizmo-soundtrack`

Current need: map/region images can pair with ORCH/JAZZ/BRG cue families for later
audio generation and implementation choices.

Generate next:

- Per-cue visual companion boards for:
  - `SEG_01.1 ORCH Clockwork_Heartbeat`
  - `SEG_02.1 ORCH Clockwork_Wanderer`
  - `SEG_09.1 ORCH Before_the_Beacon_Falls`
  - `SEG_10.1 ORCH The_Final_Ascent`
  - `SEG_11.1 ORCH The_Iron_Threshold`
  - `AMB_02.1 ORCH Sanctuary_of_Fallen_Stars`
- Dual-variant mood comparisons:
  - ORCH = mythic/structural.
  - JAZZ = nimble/mechanical/inner motion.

## Recommended Next Goal Objective

Use this as the next `/goal` prompt:

> Scout the Gizmo clean-canvas ecosystem from the existing art-concept run, then run a
> second imagegen pass focused on production gaps: Meshy turnarounds for P0/P1 assets,
> P2/P3 world-kit clean references, corrected macro-scale Hearthwake route variants,
> region enemy family sheets, companion concepts, simplified future guardian silhouettes,
> and audio/SFX visual mood boards. Persist all outputs under a new dated art-concepts
> run folder and update the downstream agent task list for Meshy, Blender, Godot/level,
> and ElevenLabs agents.

## Priority Todo For Next Imagegen Run

### P0 - Production Unlocks

- [ ] Create a new dated run folder under `docs/art-concepts/`.
- [ ] Copy forward the scale law from this file into the new run README.
- [ ] Generate `beacon_01` three-view base turnaround.
- [ ] Generate `gear_ring_01` three-view turnaround.
- [ ] Generate `sanctuary_01` three-view turnaround.
- [ ] Generate `spark_crystal_cluster_01` three-view turnaround.
- [ ] Generate `spire_01` three-view turnaround.
- [ ] Generate `orrery_altar_01` three-view turnaround.
- [ ] Generate clean product refs for P2/P3 asset-pipeline queue:
  - `platform_small_01`
  - `bridge_arch_01`
  - `gear_gate_01`
  - `debris_cluster_01`
  - `scrap_cluster_01`
- [ ] For each output, record source generator path, workspace path, prompt intent, and
  downstream lane.

### P1 - Hearthwake Level Scale And Readability

- [ ] Generate 4 alternate Hearthwake macro footprint concepts:
  - huge basin island
  - twin-branch peninsula route
  - broken-ring loopback route
  - long S-curve route with side pockets
- [ ] Generate 4 fixed-camera sightline concepts:
  - warm origin to central gear-henge
  - side branch back toward origin
  - sanctuary toward Beacon
  - Beacon approach looking back over the run
- [ ] Generate one greybox-like playable-scale map with walkable/non-walkable separation
  expressed visually, without labels.
- [ ] Generate one dressed macro concept that combines the best footprint with gouache
  art direction.

### P2 - Enemy And Motion Language

- [ ] Generate Hearthwake enemy family sheet:
  - tinkling / skitter / lug / steward.
- [ ] Generate Rows enemy family sheet:
  - crumbsweep / fetchling / butler / doorman.
- [ ] Generate Shoals enemy family sheet:
  - glint / flicker / facet / collector.
- [ ] Generate Colloquy enemy family sheet:
  - postulant / syllogist / adamant / catechist.
- [ ] Generate Fold enemy family sheet:
  - latchling / shepherd / bulwark / warden.
- [ ] Generate simplified Nibbler attack telegraph sheet with camera-readable wind-up.
- [ ] Keep all enemy sheets mechanical/faceless and avoid organic monster language.

### P3 - Companions And Ceremony

- [ ] Generate Wick concept sheet:
  - small stooped lamp-tender automaton, sanctuary warmth, no vendor/shop implication.
- [ ] Generate Marginalia concept sheet:
  - scribe-moth / Codex margin spirit, record/ceremony only, no gameplay buff read.
- [ ] Generate Rote concept sheet:
  - care-automaton stalled mid-gesture, redeemed but still awkward, no combat-pet read.
- [ ] Generate Codex ceremony / landmark memory mood board.
- [ ] Generate Core Matrix draft ceremony mood board.

### P4 - Future Guardians, But Safer

- [ ] Regenerate guardian silhouettes as simplified, game-readable forms:
  - Host
  - Panoply
  - Corollary
  - High Warden
- [ ] Make each guardian less humanoid/armored than the previous sheet.
- [ ] Make each guardian readable by silhouette at fixed camera distance.
- [ ] Add explicit future-scope warning in the manifest.
- [ ] Do not generate a Hearthwake guardian.

### P5 - Audio / SFX Visual Boards

- [ ] Generate Path A audio mood board:
  - warm origin
  - roam
  - trial pressure
  - sanctuary breath
  - Beacon siege
  - afterglow
- [ ] Generate SFX material cue sheet:
  - warm brass mechanics
  - ancient stone
  - living-light glass
  - void pressure
  - Beacon warmth
- [ ] Generate distinct resource visual cue sheet:
  - guard strain
  - guard recover
  - HP damage
  - Sparks pickup
  - Scrap pickup
- [ ] Keep all boards textless and route semantic labels into the manifest only.

### P6 - Design-System State Studies

- [ ] Generate same-object living vs hollowed pair for a Beacon-adjacent prop.
- [ ] Generate de-facing operator sheet.
- [ ] Generate drain operator sheet.
- [ ] Generate mechanize-repeat operator sheet.
- [ ] Generate decay operator sheet.
- [ ] Generate sanctuary vs pressure contrast sheet.
- [ ] Generate HUD/icon size readability sheet using large primitives only.

## Stop Conditions

- Stop and document if imagegen repeatedly makes toy-scale maps despite macro prompts.
- Stop and document if outputs repeatedly violate the scarce-teal law.
- Stop and document if character/guardian sheets drift into generic fantasy boss or
  copyrighted resemblance territory.
- Stop and document if a requested concept would imply a mechanic the game has not decided.

## Expected Deliverables

- New run README.
- New `prompts.md`.
- New `progress.md`.
- New `downstream-agent-tasks.md` or an update to the existing one.
- Saved images under the new run's `images/` folder.
- Final summary naming the strongest production candidates and the images that are only
  mood boards.
