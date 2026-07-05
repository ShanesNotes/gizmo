# Gizmo Imagegen Concept Run - 2026-07-05

Status: in progress

Generated art in this folder is a draft witness only. It is not canon, not a promoted
asset, and not a game-ready file until the owning lab reviews it and promotes it through
the relevant gates.

## Scope

This run scouts the Gizmo clean-canvas ecosystem and produces imagegen 2.0 concept art
for:

- P0/P1 Meshy-ready asset references for the asset-pipeline queue.
- Path A world mood and route concepts for Hearthwake Basin.
- Future region / guardian mood concepts that can seed later level, audio, and asset
  work without changing current v1 scope.

## Source Anchors Read

- `AGENTS.md`
- `gizmo-ecosystem.yaml`
- `CONTEXT.md`
- `CLAUDE.md`
- `design-handoff/ART_DIRECTION.md`
- `design-handoff/NARRATIVE.md`
- `docs/path-a-shattered-meridian-spec.md`
- `docs/afk/queue/INDEX.md`
- `docs/afk/queue/PHASE-MAP.md`
- `docs/afk/queue/SPEC-fun-loop-v1.md`
- `docs/world-asset-prompts.md`
- `docs/first-level-visual-asset-backlog.md`
- `docs/meshy-world-kit-prompts.md`
- `gizmo-asset-pipeline/AGENTS.md`
- `gizmo-asset-pipeline/canon/ASSET_PIPELINE_CANON.md`
- `gizmo-asset-pipeline/canon/prompt-grammar.yaml`
- `gizmo-asset-pipeline/queue/QUEUE.yaml`
- `gizmo-asset-pipeline/briefs/**`
- `gizmo-design-system/canon/CANON.md`
- `gizmo-design-system/canon/acceptance-gates.md`
- `gizmo-design-system/canon/shader-matrix.yaml`
- `gizmo-level-design/canon/LEVEL_CANON.md`
- `gizmo-level-design/canon/landmark-taxonomy.yaml`
- `gizmo-level-design/canon/pressure-zones.yaml`
- `gizmo-lore/canon/LORE_CANON.md`
- `gizmo-lore/canon/glossary.yaml`
- `gizmo-lore/canon/world-structure.md`
- `gizmo-audio-canon/canon/AUDIO_CANON.md`
- `gizmo-audio-canon/canon/cue-map.yaml`
- `gizmo-audio-canon/canon/ambient-layers.yaml`
- `gizmo-audio-canon/canon/sfx-events.yaml`
- `gizmo-level-design/docs/elevenlabs-region-soundscapes.md`

## Art Law For This Run

- True 3D Godot target, fixed Diablo-style camera.
- Playable map concepts must read as an expansive rogue-lite region, not a miniature
  diorama. The first playable slice should support a long traversal session: broad combat
  arenas, long routes, loops, side pockets, sightline landmarks, and meaningful distance
  between origin, branches, sanctuary, and Beacon.
- Connected platforms are allowed, but they must be large landforms. Avoid toy-sized
  stepping-stone chains that would play out in seconds.
- No player-facing wave-round, countdown, or danger-meter concepts.
- Beacon Rekindled is the win; HP 0 is the loss.
- Sparks, Scrap, guard, HP, and Spark of Humanity stay distinct.
- Saturated teal/cyan is scarce: Gizmo eye/core, guard, and active Beacon core-spark only.
- Sparks are violet-bodied with warm inner light, not generic blue mana.
- Runtime world art should be readable at 1280x720 from the fixed camera.
- Meshy candidates use clean product-shot references: one object, centered, full frame,
  plain pale-grey background, no text, no scene.

## Scale Correction - 2026-07-05

User steering: early map concepts had useful art direction but the connected platforms
were far too small for a playable rogue-lite. They looked like 30-second dioramas, not an
expansive explorable world for a 30-minute run.

Updated map prompt rule:

- Treat Gizmo as tiny compared with the island.
- Make main traversal surfaces field-sized, not room-sized.
- Use multiple broad combat clearings connected by readable wide routes.
- Include optional side pockets and loopbacks so the route is explorable rather than a
  single scenic chain.
- Keep vertical scenery dramatic, but non-walkable cliffs/spires must not shrink the
  playable footprint.
- Landmarks should be visible across long distances and should orient the player without
  compressing the route.
