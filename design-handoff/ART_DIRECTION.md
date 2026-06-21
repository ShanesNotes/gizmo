# Art direction — canon

The canonical visual target for Gizmo's 3D rogue-lite. This is the lean
"look & feel" owner: match these references, don't invent. Story lives in
`design-handoff/NARRATIVE.md`; this file owns the look.

## References

- **Character** → `godot/assets/gizmo.glb` (meshy.ai, 53-bone rig). The plucky
  brass-and-bronze clanker with a glowing core; the spark of humanity is
  literally his light.
- **UI + world look** → `design-handoff/gizmo-hud.png`. The single image to
  match — every surface, frame, and glow below is read from it.

## Visual language

A painted, storybook **gouache cosmos of lost tech**: matte, hand-made, warm.

- **Palette.** Deep violet/indigo space, teal/cyan energy, warm nebula orange
  smeared through the clouds. Quiet light, not neon explosions.
- **UI frames.** Ornate **brass/bronze filigree** — beveled cartouches, riveted
  edges, small heraldic flourishes around every panel.
- **Energy.** Glowing **cyan/teal** for power, bars, and beacons; the violet
  **"spark" gem** motif marks the thing being preserved (level badge, Spark
  meter, currency icon).
- **World.** A battlefield of floating platforms and drifting debris in space —
  dead gadgets and sealed machines strewn across the Hush.
- **Camera.** Fixed **Diablo-style** angle (looking down ~45°), never moving off
  that pitch. The 3D model lets the engine solve facing and frame consistency.

## HUD anatomy (from gizmo-hud.png)

Top-left, clockwise:

- **Gizmo nameplate + HP bar** — portrait roundel, name, cyan/teal health fill
  with numeric readout (e.g. 126 / 150). *(Per ADR 0005/0007 this becomes
  **guard-over-HP** — a recoverable guard bar above a smaller mortal HP bar; see
  reconciliation below.)*
- **Level badge** — large violet spark gem framed in brass, top-center (e.g. 12).
- **Objective** — short directive card, top-right. The `gizmo-hud.png` text reads
  "Carry the Spark to the Beacon," but that wording **predates ADR 0005 and is retired**
  (it also conflates the Spark with the objective, which ADR 0001 forbids). The active
  cue is **"Reach / Rekindle the Beacon"** — see reconciliation below.
- **Objective / direction readout** — the old "WAVE x/5" text in concept art is
  **not active design**, and neither is a **player-facing countdown** (ADR 0005). Show
  an **objective cue** ("Reach / Rekindle the Beacon") + a subtle direction marker or
  world-space beacon glow instead. No heavy minimap/distance UI yet; pressure is *felt*
  via swarm density, audio, and zone mood, not a danger meter.
- **Sparks & Scrap counters** — left edge; **Sparks** (primary, violet gem) over
  **Scrap** (secondary, brass gear).
- **Core Matrix** — ability bar, bottom-left, keys 1/2/3 (with a locked fourth
  slot for later draft).
- **Gadgets** — bottom-center, two L/R activated items.
- **Spark of Humanity meter** — bottom-right, the meter you keep alive:
  "Keep it safe. Keep it alive."

## Shattered Meridian reconciliation (2026-06-21)

The look above still governs; this aligns it with the active world direction
(`CONTEXT.md`, `docs/path-a-shattered-meridian-spec.md`).

- **World = painterly floating islands in the Shattered Meridian** — a gouache cosmos
  of lost tech. Path A is a **flat combat-readability layer with dramatic non-walkable
  vertical scenery** (cliffs, waterfalls, hanging chains, islets, spires, gear henges,
  bridges-over-void). Bridges read as flat connectors; nothing walkable occludes Gizmo,
  so the fixed Diablo camera is unchanged.
- **Brass Sphere** survives as **spawn / workshop / ceremony** motif; the **codex**
  survives as a **UI / memory / record** motif — *not* as the whole-world premise. Do
  not resurrect the Lumen-Codex-era world architecture.
- **HUD shifts (ADR 0005/0007):** the HP bar becomes **guard-over-HP** — a cyan/teal
  recoverable **guard** bar above a smaller warm **mortal HP** bar (damage hits guard
  first). Add a **rekindle indicator** near the Beacon (`Dormant → Rekindling →
  Rekindled` + channel fill). **No player-facing countdown.** Keep Level / Sparks
  (Core Matrix runway). Per ADR 0001 the guard is a neutral "protective light," **not**
  the Spark of Humanity meter.
- HEARTH palette for the first island: **warm brass · soft teal · violet spark · deep
  indigo void**; landmark = a vertical heart-spire over a circular workshop basin.

## Production note

Art is generated fresh to match this target — **meshy.ai** for 3D models/rigs,
**ludo** for 2D/UI ideation — then hand-curated into the gouache look. Do not
hand-author or recover Lumen-Codex-era design-system assets; that system was
removed. When in doubt, hold the new art beside `gizmo-hud.png` and match it.
