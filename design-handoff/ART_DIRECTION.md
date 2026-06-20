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
  with numeric readout (e.g. 126 / 150).
- **Level badge** — large violet spark gem framed in brass, top-center (e.g. 12).
- **Objective** — short directive card, top-right: "Carry the Spark to the Beacon."
- **Minimap + WAVE x/5** — compass-framed minimap with the wave counter beneath
  (e.g. WAVE 3 / 5): regular enemies → elites → bosses.
- **Sparks & Scrap counters** — left edge; **Sparks** (primary, violet gem) over
  **Scrap** (secondary, brass gear).
- **Core Matrix** — ability bar, bottom-left, keys 1/2/3 (with a locked fourth
  slot for later draft).
- **Gadgets** — bottom-center, two L/R activated items.
- **Spark of Humanity meter** — bottom-right, the meter you keep alive:
  "Keep it safe. Keep it alive."

## Production note

Art is generated fresh to match this target — **meshy.ai** for 3D models/rigs,
**ludo** for 2D/UI ideation — then hand-curated into the gouache look. Do not
hand-author or recover Lumen-Codex-era design-system assets; that system was
removed. When in doubt, hold the new art beside `gizmo-hud.png` and match it.
