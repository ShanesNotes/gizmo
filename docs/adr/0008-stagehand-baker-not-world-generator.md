# 0008 — The level baker is a disciplined stagehand, not a world generator

**Status:** accepted · 2026-06-21

## Decision
Path A's island is produced by an **author-time pipeline**, frozen and committed as a
scene. Procedural tooling is a **brush, never the author**. The pipeline, in order:

1. **Image references** (concept / reference sheets) — direction, not final truth.
2. **Meshy** — reusable GLB kit pieces only (trees, crystals, ruin chunks, bridge
   pieces, gear-henge props, beacon pieces).
3. **Blender** — scale, origin, silhouette, topology, collision proxies, readability.
4. **Godot wrapper scenes** — each asset carries metadata: `role`, `footprint`,
   collision intent, prompt/ref ids.
5. **Python baker** — places only *approved, wrapped* kit pieces from a **recipe**,
   and emits the sim-read data: `WalkableRegion`, `PressureZone`s, anchors.
6. **Validators** — gate every scene (below).
7. **Human curation** — the emotional beats are adjusted and frozen in-scene.

**The baker writes a manifest JSON** recording recipe version, asset ids + transforms,
zones, footprint, **soundtrack cue ids**, and validation results.

**The baker MUST NOT:** call AI/image models or Meshy directly; decide emotional
beats; invent landmarks; **overwrite curated authored nodes**; or ship a scene that
fails validation or lacks provenance.

**Validators gate every accepted scene:** reachable anchors · camera readability ·
enemy pressure does not trap spawn · clear loopback · one visible landmark at most
major sightlines · **no player-facing round-counter UI**. Each accepted scene must
also answer five questions: which visual refs informed it; which soundtrack cues
informed it; what **three visible choices** came from those cues; did they improve
readability; did any mood choice harm combat/navigation clarity.

The soundtrack `.md` is used as **mood grammar, not audio analysis** — cue ids map to
**real files** (see the Path A spec mapping), never invented.

## Why
- The existing baker (`tools/godot/generate_first_level_layout.py`) is useful
  precedent but **unsafe as-is**: it hardcodes `load_steps = 19` (the scene is now
  `21`); its whole-block rewrite **wipes curated edits** inside the markers; it has no
  manifest / provenance / seed; it emits a 91-tile grid on old clockwork assumptions;
  and it encodes **neither exposure (ADR 0006) nor the walkable footprint**.
- Canon: *"The baker is a disciplined stagehand: it assembles approved pieces, records
  why they are there, and refuses to ship a scene that cannot be played, read, or
  traced."* The guardrail exists to stop pretty procedural slop with no provenance.

## What this rules out
- An AI-level or runtime generator deciding layout or beats (procedural is a brush,
  not the author).
- **Procedural *reroll* on the spine.** Reroll is permitted only *later* and only for
  *peripheral / non-spine* dressing (side-pocket props, scatter, optional caches) —
  never to re-author the spine, landmarks, anchors, or curated beats (Q2).
- Baked scenes without a manifest, that overwrite curated nodes, or that bypass the
  validators.
- Citing soundtrack cues or asset refs that do not exist on disk.

## Consequences
- The baker is rebuilt as a stagehand: fix the `load_steps` hardcode; stop wiping
  curated nodes; retarget from the 91-tile grid to the **island footprint**; emit
  zones + footprint + anchor stubs + manifest.
- It is **grown across lessons** so it stays a tool the learner can read — never a
  one-shot black box. The GDScript `@tool` rewrite is the **named upgrade path** for
  when text-munging `.tscn` fragility actually bites.

## Related
- ADR 0002 (sim owns rules; scene renders); ADR 0006 (zones + footprint the baker emits).
- `docs/path-a-shattered-meridian-spec.md`.
- `tools/godot/generate_first_level_layout.py`;
  `godot/audio/gizmo-soundtrack/game-soundtrack-composition.md`.
