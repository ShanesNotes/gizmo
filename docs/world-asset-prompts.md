# World-asset prompt backlog — first map (Clockwork Observatory)

Pipeline: **image model (GPT Image / etc.) → Meshy image-to-3D → Godot**.
This is where the gouache look comes from — painted reference, then reconstructed to 3D.
(Blender procedural is reserved for greybox/collision/scatter only, not hero art.)

Canon: gouache cosmos of lost tech — deep violet/indigo space, teal/cyan energy,
warm nebula orange, brass/bronze clockwork. Matte, hand-made, "quiet light."
Match `design-handoff/gizmo-hud.png` + `concept art/gizmo-world-concept-*`.

---

## How to get clean 3D out of these (read first)

Meshy image-to-3D reconstructs geometry from the picture, so the IMAGE must be a clean
product shot, not a scene:

- **One object, centered, fully in frame**, on a **plain pale-grey background**.
- **3/4 elevated view** (~30–45° down), even neutral studio lighting, soft shadow.
- **No other objects, no ground/horizon, no characters, no text, no border.**
- Readable silhouette; avoid heavy atmospheric haze on the object itself.
- For HERO pieces, generate **3 consistent views** (front, 3/4, side) of the SAME object
  and use Meshy **multi-image-to-3D** — much better geometry than a single view.
- After reconstruction, use Meshy **retexture** if you want to push the gouache/brass
  paint further. Target format **GLB**. Keep ≤300k faces if you'll rig it.

Every prompt below already ends with the clean-shot constraints. Paste as-is.
Drop results in `godot/assets/world_kits/clockwork_observatory/` with the suggested name;
I'll wire + scale them in Godot.

**Shared style tag** (already baked into each prompt, here for reuse):
> hand-painted gouache storybook steampunk; warm patinated **brass and bronze** + carved
> sandstone; **teal/cyan** glowing rune accents; **violet** spark-crystal motif; matte,
> soft, weathered; deep violet shadows, warm highlights. Not photoreal, not neon, not glossy.

---

## P1 — Hero silhouette (do these first)

### A1 · Floating island platform  → `clockwork_island_base_01`
```
A single floating island platform for a storybook steampunk game, 3/4 elevated view,
centered on a plain pale-grey background, full object in frame, even soft studio lighting.
A carved chunk of warm weathered sandstone fused with patinated brass: a broad flat round
top inlaid with concentric clockwork rune-rings and small bronze gears, the rim ragged like
broken stone. The underside is craggy rock tapering downward, with exposed brass pipes,
cogs, a few dangling chains and dead roots. Hand-painted gouache style, matte and warm —
deep violet shadows, faint teal-glowing rune lines, brass highlights, verdigris.
Single object only. No scene, no horizon, no characters, no text, no border.
Clean 3D-asset reference with a readable silhouette.
```

### A2 · Colossal clockwork gear-ring (distant landmark)  → `clockwork_gear_ring_01`
```
A single colossal ancient clockwork orrery gear-ring, 3/4 view, centered on a plain
pale-grey background, full object in frame, even lighting. A giant ring of interlocking
brass and bronze gears and armillary bands, weathered with verdigris, a faint teal glow
in the gaps, and a small suspended violet crystal core at center. Hand-painted gouache
steampunk, matte, warm brass. Symmetrical, readable silhouette. Single object only.
No scene, no characters, no text, no border. Clean 3D-asset reference.
```

---

## P2 — Map build-out

### A3 · Small floating platform variant (satellite island)  → `clockwork_platform_small_01`
```
A single small floating stepping-stone platform, 3/4 elevated view, centered on a plain
pale-grey background, full object in frame, even lighting. A modest carved sandstone-and-
brass disc, slightly tilted, one teal rune glyph on top, craggy rock underside with a
couple of exposed cogs and a hanging chain. Hand-painted gouache steampunk, matte, warm,
weathered. Single object only. No scene, no characters, no text. Clean 3D-asset reference.
```

### A4 · Observatory spire / pylon  → `clockwork_spire_01`
```
A single tall clockwork observatory spire, 3/4 view, centered on a plain pale-grey
background, full object in frame, even lighting. A slender weathered brass-and-stone tower
topped with a small armillary sphere and a glowing teal lens, gear collars and rivets down
the shaft, a faint violet crystal set in the base. Hand-painted gouache steampunk, matte,
warm brass with verdigris. Vertical readable silhouette. Single object only. No scene,
no characters, no text. Clean 3D-asset reference.
```

### A5 · The Beacon (objective prop — "carry the Spark to the Beacon")  → `beacon_01`
```
A single ornate brass beacon shrine, 3/4 view, centered on a plain pale-grey background,
full object in frame, even lighting. A waist-high clockwork pedestal of brass filigree and
carved stone with an empty cradle at the top ringed by teal rune-light, designed to hold a
glowing violet spark-crystal. Gears, rivets, small pipes; weathered, sacred, inviting.
Hand-painted gouache steampunk, matte, warm. Single object only, symmetrical. No scene,
no characters, no text. Clean 3D-asset reference.
```

---

## P3 — Detail & dressing

### A6 · Floating debris cluster (broken machinery)  → `clockwork_debris_cluster_01`
```
A single cluster of floating broken clockwork debris, 3/4 view, centered on a plain
pale-grey background, full object in frame, even lighting. Tumbled chunks of cracked stone,
bent brass pipes, loose gears and a snapped cog-wheel, a trailing chain, faint teal spark
glints. Hand-painted gouache steampunk, matte, warm, weathered. Single grouped object only.
No scene, no characters, no text. Clean 3D-asset reference.
```

### A7 · Brass dressing prop — orrery telescope stand  → `clockwork_orrery_prop_01`
```
A single antique brass orrery-telescope on a tripod stand, 3/4 view, centered on a plain
pale-grey background, full object in frame, even lighting. Weathered brass tube, gear-driven
mount, small armillary rings, a teal lens glow, riveted stone base. Hand-painted gouache
steampunk, matte, warm brass with verdigris. Single object only. No scene, no characters,
no text. Clean 3D-asset reference.
```

### A8 · Spark crystal formation (the thing you protect)  → `spark_crystal_01`
```
A single glowing violet spark-crystal cluster on a small brass mount, 3/4 view, centered on
a plain pale-grey background, full object in frame, even lighting. Faceted indigo-to-violet
crystals radiating a soft inner light, set in a weathered brass clockwork cradle with tiny
gears. Hand-painted gouache style, matte, the crystal the only bright glow. Single object
only. No scene, no characters, no text. Clean 3D-asset reference.
```

---

## Suggested order
A1 (island) and A2 (gear-ring) first — they define the map's silhouette. Then A4/A5
(spire + Beacon) for verticality and objective, A3 for the larger map, A6–A8 for dressing.

When you have images, hand them to me and I'll drive the Meshy image-to-3D conversion
(I'll confirm the credit cost per asset before spending) and wire each into Godot at the
right scale. Or generate the GLBs yourself and just point me at them.
