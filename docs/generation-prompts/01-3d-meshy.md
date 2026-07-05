# 01 — 3D Assets (Meshy)

`derived from ecosystem canon; do not edit as source`

Global Meshy params (`gizmo-asset-pipeline/canon/meshy-workflow.yaml`): `ai_model: meshy-6`,
`model_type: lowpoly`, `should_texture: true`, `enable_pbr: true`, `image_enhancement: true`,
`remove_lighting: true`, `should_remesh: true`, `topology: quad`, `symmetry_mode: auto`,
`origin_at: bottom`, `target_formats: [glb, fbx]`. Budgets per `canon/budgets.yaml`:
landmark 40k tris / world_kit 20k / prop 8k / enemy 15k / character 30k.

**STYLE TAG** (append to every prompt below): *hand-painted gouache storybook; warm patinated
brass and bronze + carved sandstone; teal/cyan glowing rune accents used scarcely; violet
spark-crystal motif; matte, soft, weathered; deep violet shadows, warm highlights. Not photoreal,
not neon, not glossy.*

**NEGATIVE** (append to every prompt below): *no photoreal chrome, no generic sci-fi droid or
portal, no horror gore, no text labels or logos, no tiny filigree that will mush at gameplay
scale, no direct copyrighted character resemblance, no neon glow flooding the object.*

Known failure modes to plan for: raw Meshy PBR reads too realistic — a post-generation
gouache tint/material pass is expected, not a prompt-only fix; validate the **back view first**.
Hero pieces (Beacon, Sanctuary, orrery altar, enemies) go **image-to-3D** — generate the
reference sheet from `02-images-imagegen.md` first.

---

## Queue items (q01–q14, `gizmo-asset-pipeline/queue/QUEUE.yaml`)

### q01 · island_base_01 (world_kit, P0, text-to-3D)
> A large flat-topped floating island slab of carved warm sandstone, edges broken and eroded
> where it tore free from a greater landmass, underside tapering to cracked rock roots trailing
> loose pebbles, top surface a gently uneven but walkable flat plain with faint circular
> tool-worn paving traces near the center, thin veins of patinated bronze inlay following old
> mason lines, moss-dry weathering in crevices. Single object, centered, readable silhouette
> from a high 3/4 view.
- Silhouette req: flat walkable top (single traversal plane, no step-ups), dramatic broken underside. Gameplay role: map base, defines walkable footprint (L9, ADR 0006 flat combat layer).
- Provenance: level-design mechanic 6 (flat traversal), spec §6; lore "wounded floating island".

### q02 · beacon_01 (landmark, P0, image-to-3D — reference sheet IMG-05)
> A tall dormant hearth-beacon: a ceremonial brass-and-sandstone lantern tower the height of
> four figures, built like an oversized handcrafted lamp — a wide carved stone base dais, a
> patinated bronze body with hand-riveted seams, an open lantern crown holding a large unlit
> glass-and-brass flame vessel, cold ash streaks and cobweb veiling on the crown, snuffed
> candle-cups around the dais rim, a faint carved serene face on the lantern housing that is
> cracked and dust-veiled. Warm materials gone cold, not sci-fi.
- Three states are material/emissive variants of ONE mesh (build Dormant; Rekindling/Rekindled are texture/emissive passes): Dormant = snuffed, faceless-veiled, cobwebbed (M8); Rekindling = warm ember flame `#e0461e` growing in the vessel, teal core-spark `#8fe6e6` at the very heart ONLY; Rekindled = open warm gold sun-face mandorla, warmth pushing outward.
- NEVER: portal, teleporter, countdown device, crystal socket/cradle awaiting a carried item, finish-line trophy, tech-beacon with antennas.
- Provenance: ADR 0005; M8 `design-system/canon/motifs.yaml`; asset-pipeline lore-bindings "beacon"; audio A9 (states must be distinct across senses — G14 pole unison).

### q03 · gear_ring_01 (world_kit, P0, text-to-3D)
> A monumental broken ring of interlocked bronze observatory gears, half-buried upright in
> sandstone like a fallen henge arc, teeth worn smooth, patina green-brown, some teeth snapped,
> carved star-notation etched along the rim, dry moss in the joins. Hand-made, ceremonial,
> weathered — an instrument people once tended, not industrial machinery.
- Provenance: spec §2 gear-henge; G2 (this is *warm lost tech*, the LIVING register of machines — never cold steel).

### q04 · gizmo_clips (character animation — NOT a Meshy generation)
**Do not run any Meshy/AI rig op.** Shipped `godot/assets/gizmo.glb` (53-bone, hand-keyed
v1 walk) is protected (`canon/animation-pipeline.yaml`). Author clips in Blender on a **copy**
of the skeleton, export animation-only GLB, import as shared AnimationLibrary. Clip contract:
`[idle, walk, attack]` exact lowercase; idle/walk loop, attack does not; attack = 2-phase
wind-up + strike readable at the 50° camera; foot-contact frames marked for SFX binding;
gait "squat, clanky, handcrafted — never a stretched-human gait." Tripo `animate_rig` permitted
as timing **reference only**.

### q05 · spire_01 (world_kit, P1, text-to-3D)
> A tall slender vertical heart-spire of stacked carved sandstone and bronze bands, tapering
> upward like a workshop chimney crossed with a bell tower, a small unlit lantern niche near
> the top, prayer-worn smooth at its base, leaning very slightly. Non-walkable dramatic
> scenery; strong tall silhouette against a void sky.
- Provenance: spec §2 "vertical heart-spire over a circular workshop basin"; L4 (landmark does orientation work — tall + warm-emissive = goal register).

### q06 · orrery_altar_01 (world_kit, P1, image-to-3D — verify existing reference first, else IMG-07)
> A waist-high circular orrery altar: a carved sandstone drum table holding a hand-made brass
> orrery of small planets on curved arms around a lantern-sun, arms frozen mid-orbit, one arm
> bent, the lantern-sun's tiny carved face intact and serene, wax drips and gear-dust on the
> drum, violet crystal chips inlaid at the compass points.
- Provenance: queue note (reference may already exist — verify, then image-to-3D); M6 faced luminary.

### q07 · sanctuary_01 (landmark, P1, image-to-3D — reference sheet IMG-06)
> A sheltered hearth-pocket built into a brass-and-stone workshop shell: a half-dome of
> patinated bronze ribs over a circular sandstone floor, a low tended fire-lamp on a plinth
> at center (small warm gold flame, kept — not a bonfire), repaired hanging lamps on chains,
> a workbench with folded cloth and neat small tools, living dry vines with tiny rose
> flourishes climbing two ribs, one wide open threshold arch facing out. Everything hand-mended,
> warm, breathing.
- NEVER: healing fountain, save-point shrine, glowing HP crystal, bunker. Sanctuary reads as *relief and care*, mechanically it recovers guard only (ADR 0007).
- Provenance: lore "Sanctuary/Wick's kept lamp" (X-L4); M3 living vines only where care is mechanically present (B-sanctuary); L6.

### q08 · spark_crystal_cluster_01 (world_kit, P1, text-to-3D)
> A small cluster of luminous crystal shards growing from a bronze-veined sandstone knuckle:
> deep violet and indigo crystal bodies, faceted like hand-cut reliquary glass, each shard lit
> from within by a warm gold-white inner glow at its core, glow soft and candle-like. Readable
> as a precious pickup at a distance.
- **Color law (ruling D6): violet/indigo body `#7b62a4`/`#574073`, warm gold-white `#e0c17a` inner glow. NEVER teal, never cyan.**
- NEVER: fuel cell, HP/ammo pickup styling, generic mana crystal blue.
- Provenance: X-P2 concordance; lore "Sparks = rescued fragments, not farmed XP".

### q09 · nibbler_clips — same law as q04: no AI rig ops; Blender on skeleton copy after NIB mesh (below) is promoted; reuse the proven clip pipeline.

### q10 · platform_small_01 (world_kit, P2, text-to-3D, depends q01)
> A small round floating stone platform matching the island's carved sandstone, flat walkable
> top with a worn bronze compass inlay, broken edge on one side, short cracked underside taper.
> Scale/style anchor for the kit; must sit visually on the island_base material family.

### q11 · bridge_arch_01 (world_kit, P2, text-to-3D)
> A flat stone-and-bronze footbridge segment spanning a gap: level walkable deck of sandstone
> planks bound by riveted bronze straps, low side rails of worn brass rope-posts, ends finished
> as threshold steps. Strictly flat deck — reads as floor, never as platforming.
- Provenance: spec §6 "bridges are flat connectors"; L9.

### q12 · gear_gate_01 (world_kit, P2, text-to-3D)
> A freestanding threshold arch built from two upright bronze gear-halves meeting overhead,
> carved sandstone footings, a small unlit lantern at the keystone, tall enough to walk through,
> visibly a doorway between places. A frame you cross, not a wall.
- Provenance: M1 frame-as-threshold (B-frame, G8); level rule `thresholds_mark_zone_crossings` — place only at real zone boundaries.

### q13 · debris_cluster_01 (world_kit, P3, text-to-3D)
> A scatter cluster of broken warm tech: a cracked bronze kettle-boiler, a spilled drawer of
> gear wheels, a leaning carved stone slab, torn cloth awning scraps, all weathered together
> into one readable mound. Sad domestic ruin, not battlefield wreckage.

### q14 · scrap_cluster_01 (world_kit, P3, text-to-3D)
> A small tidy pile of salvage: stacked brass plates, coiled copper wire, a worn gear on top,
> unlit and matte — humble material worth. Clearly duller and warmer than any crystal; reads
> as Scrap (salvage), never as Sparks (light).
- Provenance: lore Scrap/Sparks distinction; scrap token `#bd8468` (brass, unlit).

---

## Enemies (the Hush swarm — image-to-3D from reference sheets IMG-01..04)

Design law: enemies are **counterfeit care-machines** — the world's own warm domestic forms
de-faced, drained, mechanize-repeated, decayed (D1 operators). NEVER military robots, never
gears-vs-organic sci-fi menace (G2), never gore. Where Gizmo has one warm faced teal eye, they
have **voids, blanks, or cracked masks**. Palette: drained slate/grey-green (`#7d7066`,
`#5b5a54`, drain ramp `#6e7a72→#2c3633`), traces of former warmth gone ashen. Budget 15k tris,
2 mats. Sound doctrine pairs with SFX file 03.

### ENM-nibbler (small fast swarmer, radius ~22)
> A small hollow kettle-creature: a dented tin kettle body scuttling on six thin stamped-metal
> feet, its spout raised like a blind head, lid slightly ajar showing empty dark inside, faded
> painted flower pattern almost worn away, ash-grey drained finish with one streak of old
> copper warmth. No face — a smooth blank where a face should be. Slightly sad, slightly wrong.

### ENM-dasher (charge attacker, radius ~19, needs readable wind-up pose)
> A lean hollow errand-machine: a narrow bronze letterbox-body on two long backward-bent
> stilt legs, built for delivering things it no longer carries, chest hatch hanging open and
> empty, drained verdigris finish, a cracked porcelain doorbell where its face should be.
> Posture coiled low and forward, clearly built to lunge.

### ENM-brute (large tank, radius ~37)
> A heavy hollow door-warden: a massive wardrobe-like cabinet body on four squat piston legs,
> double doors on its chest bolted shut, welcome-mat plate dragged under one foot, drained
> ash-slate finish over old household lacquer, a large blank oval where a carved face was
> chiselled away. Slow, patient, far too heavy.

### ENM-warden (mid enemy, radius ~30)
> A hollow music-box governess: a rounded pewter music-box body on a rolling skirt-base,
> a bent winding key turning slowly in its back, small mechanical arms folded as if keeping
> order, drained grey-lavender finish, a cracked mirror where its face should be, reflecting
> nothing. Formal, repetitive, joyless.

### ENM-elite (variant law, not a separate mesh)
Elites = same meshes scaled up with degradation pushed one operator further (more de-faced,
more stamped-identical repetition in their surface pattern) + a single cold rim-light. Never a
palette-swap to red (G9) and never a "boss" silhouette — Path A's climax is the siege itself
(spec §10).

---

## Pickups & props (text-to-3D, prop budget 8k)

### PCK-cache (sealed reliquary)
> A sealed lost-tech reliquary chest: a small rounded bronze casket with carved sandstone
> corners, hand-riveted bands, a faint serene face embossed on the lid, seams glowing hairline
> warm gold from within, sitting slightly sunken as if long asleep. Precious, dormant, kept.
- NEVER: loot chest tropes, padlocks, gold coin spills. Provenance: NARRATIVE §3 cache/reliquary; forbidden "loot chest / gear drop".

### PCK-heart (surviving ember of warmth, capped recovery)
> A tiny brass hand-warmer locket, slightly open, holding one small steady ember of warm
> gold-orange light inside, chain pooled beneath it. Intimate, domestic, precious.
- Warm gold-orange `#e0461e`/`#e0c17a` — never teal (that would claim the guard layer), never a red cross / health-pack read.

### PRP-hearth-walls (spawn hearth kit)
> A low broken U of warm hearth wall: carved sandstone blocks with a bronze fire-shelf, soot
> shadow of an old kept flame, one clear north-facing gap as the single way out. Warmth as
> architecture; the gap is the invitation.
- Provenance: `spawn-hearth.yaml` closed-U one-gap rule; M2 warm-behind/cold-ahead.
