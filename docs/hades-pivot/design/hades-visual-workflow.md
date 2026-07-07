# Hades Visual Standard — Operational Workflow

Research pass to answer Shane's challenge: our internal "gorgeous" is calibrated against
our own greybox, not against a shipped, gorgeous game. This document extracts Hades
(Supergiant, 2020) craft into reproducible rules, then states what our gouache/storybook
target keeps deliberately different, per `/home/ark/gizmo-design-system/canon/CANON.md`.

**Sourcing note up front:** I do not have pixel-measured screenshot data (no direct frame
access with a color-picker). Every claim below is either (a) a direct quote/paraphrase from
a cited article/interview describing the technique, or (b) marked `[inferred]` where I am
reasoning from the described technique to a specific numeric rule. Treat `[inferred]` lines
as a first-draft calibration, not settled fact — verify them against our own Godot
screenshots per §6 before trusting them as gates.

---

## 1. Value structure — floor / actors / FX separation

Hades' base rule, stated directly by observers analyzing gameplay footage: **enemies and
player are colored for maximum contrast against their specific room's floor palette, not
against a universal rule.** Per-biome:

- **Tartarus:** cold grays / stony floor tones. Enemies are bright yellow against gray stone
  — the single highest-contrast complementary pairing available in that biome.
- **Asphodel:** brown/scorched-earth floor. Enemies read bright green, pink, and red against
  the brown — again, complementary-clash pairing, not value alone.
- **Player (Zagreus):** red, kept consistently saturated against whatever muted-green or
  brown floor is under him, "orange monsters and red main character achieve heavy contrast
  against the dark, muted green background due to their distinct colors... main elements are
  very bright and saturated, while the background is deliberately subdued."
  (tech4gamers.com/game-dev-students-should-analyze-hades-for-design-lessons)
- **Projectiles:** locked to one identity color across the whole game — "all projectiles are
  a consistent pink/purple color" — so the read is trained once and reused everywhere,
  independent of biome. (same source)

Shadow/volume handling (pointnthink.fr — "The Art of Hades"): **pure black is used for the
deepest shadow**, "sometimes on entire parts of the characters, creating a strong contrast
with the colour," and volume beyond that is sculpted by **shifting color temperature**, not
by graduating black-to-midtone. This is a *hard graphic* choice (comic-ink shadow shapes),
distinct from a soft PBR falloff.

**Operational restatement (value ladder, floor → actor → FX):**
1. Floor/background: desaturated, biome-tinted, mid-to-low value — never competes for the eye.
2. Actors (player + enemies): high saturation, chosen as the *complement* of that biome's floor
   hue, not a generic "brighter than floor" rule — same technique, per-biome color script.
3. Shadows on actors: crushed to true black in shape-defining zones (ink shadow), not a
   soft gradient — this is what keeps actors graphic/flat-readable at speed.
4. FX (projectiles, boons, impacts): a small, fixed vocabulary of identity colors
   (pink/purple projectiles; each god's signature hue for their boon effects) layered *above*
   actor brightness, closer to pure hue+white than anything else on screen.

Sources: [tech4gamers.com](https://tech4gamers.com/game-dev-students-should-analyze-hades-for-design-lessons/), [pointnthink.fr — The Art of Hades](https://www.pointnthink.fr/en/the-art-of-hades-en/)

---

## 2. Silhouette hierarchy — player vs enemy vs FX readability

Multiple sources converge on the same one-line design law: **"The contrast, the color
choices, the silhouettes, the readability of enemies, all of it serves gameplay first."**
(quoted by tech4gamers, echoed by gamerant/critical-video-game-studies coverage). The
implication for a fast-action isometric brawler:

- **Silhouette is decided before paint.** Character shapes are designed to be distinguishable
  in outline alone — this is why Hades characters read even mid-combat-chaos, at speed, at
  the game's default zoom.
- **Distinctive-per-character silhouette + expressive animation** is called out specifically
  as what makes each character "instantly recognizable even in the heat of combat"
  (80.lv summary framing, corroborated by tech4gamers).
- **Flashiness is subordinate to information delivery** — VFX must never obscure the
  silhouette or the telegraphs that matter for player decision-making; "flashy" only exists
  where it doesn't cost readability.

**Hierarchy, most-readable-must-win, in priority order:**
1. Player silhouette (always must read, at all times, over everything).
2. Incoming-threat telegraphs (wind-ups, projectile paths) — must read over ambient FX.
3. Enemy silhouettes — must read against floor and against each other, but can be occluded
   briefly by attack FX since the threat information already fired at telegraph-time.
4. Ambient/decorative FX (embers, room atmosphere) — lowest priority, can be dimmed/thinned
   whenever it competes with 1–3.

`[inferred]` A concrete consequence: Hades' pink/purple projectile-color lock (§1) is also a
silhouette-hierarchy device — a single instantly-parsed hue means the player's eye doesn't
have to re-segment "is this FX or a threat" per-enemy, freeing attention for path-reading.

Sources: [tech4gamers.com](https://tech4gamers.com/game-dev-students-should-analyze-hades-for-design-lessons/), [80.lv — Behind-the-scenes VFX](https://80.lv/articles/a-behind-the-scenes-look-at-the-effects-in-hades)

---

## 3. Color discipline — saturation zones, rim/accent usage, UI-in-world

**Palette-per-god as an information system, not decoration.** Pointnthink.fr: "Each god
receives a dominant color—yellow for Zeus (ego, power), violet for Dionysus, pink for
Aphrodite—enabling quick visual distinction while establishing emotional tone." Color here is
doing **narrative + gameplay double-duty**: it identifies the boon-source at a glance AND
carries the god's characterization.

**Saturation is not uniform across the frame — it's zoned:**
- Background/floor: restrained, narrow-hue palette per biome (pointnthink names "cold grays
  and tangy greens" for Tartarus, "crimsons and purples" for Asphodel scorched-earth) —
  the base is *desaturated relative to* the accent work, never flat-neutral.
- Rim/edge highlighting on characters: "highlighted edges in bright, sometimes acidic hues
  (green on hair, orange on skin)" — i.e., **rim light is a deliberately unnatural, saturated
  accent color chosen for pop, not physically-motivated light bounce.** This is the single
  most copyable technique for cheaply reading as "expensive": a thin, high-chroma rim on the
  silhouette edge, independent of the character's local color.
- Impressionist touch technique: "saturated touches of color to break up large areas of solid
  hue" — small dabs/flecks of a contrasting saturated color scattered through an otherwise
  flat fill, borrowed explicitly from Impressionist painting. This keeps large flat-shaded
  areas (a comic-ink flat-fill silhouette) from reading as dead/plastic.
- Signature secondary detail: hexagonal light-source halos are called out as a repeated
  signature motif around light sources — a small, consistent geometric accent shape used
  wherever a light is diegetically present, functioning like a "brand mark" for lit objects.

**UI-in-world:** direct sourcing here is thinner than requested — I could not retrieve a
working fetch of the UI-specific breakdown pages (interfaceingame.com 403'd; the 80.lv VFX
deep-dive text wasn't retrievable past the summary). What is confirmed: Josh Barnett held
both the VFX **and** UI-art role on Hades (multiple sources), meaning UI iconography and
in-world FX were designed by the same hand with the same material vocabulary (ink-line +
flat-color + saturated-accent) — this is *why* Hades UI doesn't look bolted-on: it's drawn in
the same graphic language as the enemies and boons it represents, not a separate "clean UI
skin" over a "painterly world." `[inferred]` The god-dominant-color system (Zeus=yellow,
Aphrodite=pink, etc.) is very likely the same key used for that god's boon icon color in the
HUD/prompt UI — this needs direct visual confirmation in §6, not asserted as fact here.

Sources: [pointnthink.fr — The Art of Hades](https://www.pointnthink.fr/en/the-art-of-hades-en/), [80.lv](https://80.lv/articles/a-behind-the-scenes-look-at-the-effects-in-hades), [gamedeveloper.com — hand-painted characters](https://www.gamedeveloper.com/art/learn-how-supergiant-brought-i-hades-i-hand-painted-characters-to-life)

---

## 4. FX language — why death/impact FX read as expensive

Confirmed facts are thinner than I'd like here (the 80.lv deep-dive page only returned its
summary teaser, not the full technical breakdown — the linked video/article body wasn't
retrievable via fetch). What is confirmed and citable:

- Josh Barnett (VFX + UI artist) authored the effects for each god's granted ability —
  "Zeus' thunder, Poseidon's waves, Artemis' arrows" are named as distinct, per-god visual
  languages, not a shared generic particle set reskinned per-god. Each Olympian's kit gets
  its own shape/motion vocabulary matching their domain (lightning = jagged/branching,
  waves = flowing/volumetric, arrows = linear/directional).
- The base art technique — ink-line + flat color + pure-black shadow shapes (§1) — extends
  to FX: this is confirmed by the overall "pen & ink style inspired by Mike Mignola and Fred
  Taylor" framing (tech4gamers), meaning FX are drawn with the same hard-edged,
  graphic-shape-first approach as characters, not soft painterly gradients or photoreal
  particle sims.
- The consistent projectile-identity-color rule (§1, pink/purple) is itself an FX-language
  rule: **color is reserved for identity/threat-signaling, not varied for "visual interest."**

`[inferred]` — reasoning from the above to a reproducible FX recipe, since the source
material didn't give me frame-by-frame timing data:
1. **Silhouette-first FX shapes**: design the FX shape as a flat, recognizable graphic icon
   (a jagged bolt, a wave crest, an arrow streak) before adding any secondary motion —
   the FX itself has a silhouette, matching the god's domain, not a generic particle burst.
2. **Layering = base shape + rim accent + impact flash**, echoing the character rim-light
   technique in §3: a flat-colored core shape, a thin saturated rim/edge pass, and a
   single bright (near-white) flash frame at the moment of contact.
3. **Timing = fast in, held silhouette, fast out**: readability at speed requires the FX to
   snap to full shape almost instantly (1-2 frames), hold recognizably for the "this hit
   registered" beat, then clear quickly so it doesn't linger and clutter the next FX's read.
4. **Reused, don't randomized**: the same shape vocabulary and color repeats across every
   use of that god's ability, which is what "expensive-reading" actually buys — pattern
   recognition trained once compounds every subsequent hit into an instant, cheap read for
   the player, which registers emotionally as "polished."

Sources: [80.lv](https://80.lv/articles/a-behind-the-scenes-look-at-the-effects-in-hades), [tech4gamers.com](https://tech4gamers.com/game-dev-students-should-analyze-hades-for-design-lessons/)

---

## 5. Door/reward presentation anatomy — the lure

Confirmed from door-symbol guides (Inverse, Prima Games, Game8, GameRant):

- **Every doorway carries a symbol** previewing what's behind it before the player commits —
  the lure is informational-first: you choose based on legible iconography, not mystery.
- **Icon = god identity or reward-category glyph**: a god's symbol (e.g., a heart for
  Aphrodite, a sword for Ares) for boon rooms; a skull-on-a-bag for Charon's shop; an
  exclamation point for NPC encounter rooms; gem icons for resource rooms.
- **Color-coded permanence tier, not icon shape**: "gold laurels signify temporary buffs,
  while blue laurels signify items that remain after a run ends" — a laurel-wreath framing
  device wrapped around the icon, whose *color* (not shape) tells the player the stakes
  (run-only vs. meta-permanent). This is a reusable frame-color pattern: one consistent
  frame shape, a small fixed palette of frame colors, each color meaning something durable
  and memorized once.
- **A glow/ray-emission overlay signals a bonus/upgrade tier**: "rays of light emanating off
  a door symbol indicate +1 to rewards or double artifact rewards" — the base icon stays
  identical, an additive glow layer is the only change communicating "better than normal,"
  which keeps the icon vocabulary small while still layering in a bonus-tier signal.

**Anatomy, decomposed:**
- **Core glyph** (god symbol / reward-type icon) — the identity layer, always present, always
  the same shape per meaning.
- **Frame** (laurel wreath) — the container, whose color carries the permanence-tier meaning.
- **Emission overlay** (glow/rays) — purely additive, signals "enhanced," absent by default.

This is a clean 3-layer system: shape=what, frame-color=stakes, glow=bonus. `[inferred]`
Scale/size of the icon itself is very likely constant regardless of reward value (I found no
source claiming icons scale by reward tier) — the tiering signal lives entirely in
frame-color and glow-presence, not icon size. Verify this against actual screenshots before
treating it as settled; I list it as the working hypothesis for our own door icons.

Sources: [Inverse — Hades symbols guide](https://www.inverse.com/gaming/hades-symbol-meaning-guide-hera-dionysus-apollo-ares-aphrodite), [Prima Games — Door Symbol Guide](https://primagames.com/tips/hades-door-symbols-guide-boons-artifacts), [Game8 — Door Symbols and Room Rewards](https://game8.co/games/Hades-2/archives/453727), [GameRant — Hades Door Symbol Guide](https://gamerant.com/hades-door-symbol-guide/)

---

## 6. Calibration workflow — checks our look-passes must run

Five concrete, verifiable checks, each with a Godot-screenshot verification method. Run these
against `mcp__godot-runtime__take_screenshot` output every wave a visual pass claims
"gorgeous."

1. **Squint test — player readable at 50% zoom / heavy blur?**
   Take the in-engine screenshot, apply a strong Gaussian blur (or literally squint), confirm
   Gizmo's silhouette is still distinguishable from enemies and floor. Fails if Gizmo blends
   into background value or an enemy's silhouette is confusable with his at a glance.
   *(Directly ports Hades' "silhouette serves gameplay first" law, §2.)*

2. **Value histogram — floor midtone, actors brighter, FX brightest.**
   Grab the screenshot, convert to grayscale, histogram it. Confirm three separated value
   bands: floor/background clustered low-mid, player+enemies clustered mid-high (and
   *separated from* the floor band, not overlapping it), FX/impact flashes spiking into the
   top band. Fails if any actor's value band overlaps the floor's — that's the Hades
   "actor pops off desaturated ground" rule (§1) being violated.

3. **Color-identity lock check — does one recurring FX/threat type keep one hue everywhere?**
   Pick one recurring gameplay signal in our game (an enemy telegraph, a specific hazard, a
   specific pickup) and confirm it uses the *same* hue in every biome/lighting condition it
   appears in. Fails if the same signal shifts hue between rooms due to ambient
   tint/lighting bleeding into it — ports the "projectiles always pink/purple, everywhere"
   rule (§1) that trains pattern recognition once.

4. **Rim-accent presence check — does every hero-readable actor carry a non-physical
   saturated edge highlight?**
   Screenshot a character in a neutral-lit area; confirm there's a thin, high-chroma rim or
   edge line on the silhouette that would NOT be explained by the actual light sources in the
   scene (i.e., it's a deliberate graphic accent, not PBR specular). Fails if the only
   brightening on the character is physically-motivated key/fill light — that reads
   "correctly lit" but not "Hades-expensive" (§3).

5. **Door/reward legibility at approach distance — 3-layer read from the player's actual
   approach angle/distance?**
   Screenshot the door/reward prompt from the distance a player is actually standing when
   they'd decide to enter (not a close-up crop). Confirm the three anatomy layers (§5) are
   each independently legible at that distance: glyph shape readable, frame color
   distinguishable from the two other tier-colors in our system, glow/no-glow obviously
   binary. Fails if any layer requires stepping closer to parse — the lure has to work from
   the decision-making distance, not just in a marketing close-up.

---

## 7. What our gouache/storybook target keeps deliberately different from Hades

We are filtering Hades' *craft rules* (readability, value-separation, silhouette-first FX,
color-as-information) through `CANON.md`, not adopting its *look*. Named differences,
sourced against the canon:

- **Line technique — flat gouache/woodcut, not pen-and-ink comic shading.** Hades' "pen &
  ink style inspired by Mike Mignola and Fred Taylor" (tech4gamers) with pure-black
  crush-shadow shapes is a specific comic-illustration lineage. CANON.md commits to
  "illuminated folk-tale illustration, flat ornamental gouache, woodcut-like linework,
  manuscript border" (CANON.md line 17) — flat painterly fill and woodcut linework read
  differently from ink-crosshatch/crush-black comic shading, even though both use hard-edged
  flat color. We take Hades' *lesson* (crush shadows to a decisive shape, don't soften into
  gradient) but express the shape in gouache/woodcut terms, not ink-splatter terms.

- **Per-god dominant-color-as-identity → replaced by the Face/pole system, not a roster of
  gods.** Hades assigns one saturated hue per Olympian as an identity+tone signal (§3).
  CANON.md's structuring axis is not "one color per character" but the **Face=alive /
  Faceless=hollowed pole** (CANON.md §0, D5) plus the teal-cyan scarcity rule reserved
  exclusively for Gizmo's own spark (CANON.md §3, D3, gate G6). We do not multiply saturated
  "identity colors" per NPC/enemy the way Hades multiplies them per god — our accent
  saturation budget is deliberately scarcer and semantically loaded (teal = consciousness,
  never decorative) rather than an assignable per-character palette swatch.

- **Rim-light accent hue is unnatural/acidic in Hades (green on hair, orange on skin,
  arbitrary per-character) → ours is pole-coded, not per-character-arbitrary.** Where Hades
  picks a rim color for "pop" independent of meaning, our warm/cool accent choices are bound
  to the LIVING/FACED (warm gold, parchment, ember) vs HOLLOWED/FACELESS (cold slate-teal,
  drained) registers (CANON.md §1–§2). A rim light in our world is either a warmth-signal or
  a drain-signal — never a free aesthetic pick the way Hades' green-on-hair is.

- **Environment palette is biome-flavor-only for Hades (Tartarus grays, Asphodel
  crimson/scorched) vs. ours is world-state-driven.** Hades' floor/background hue shifts room
  to room to establish *place*. Ours shifts along the Beacon-state axis (Dormant →
  Rekindling → Rekindled, CANON.md §4) to establish *world-state* — the same location can
  shift its whole value/color structure as the master mechanic advances, which Hades' fixed
  per-biome palette does not attempt.

- **UI material language: Hades' UI is drawn in the same ink/flat-color hand as its FX
  (Josh Barnett held both roles) → ours is explicitly a page-object, not a world-object**
  (CANON.md D7, §5). CANON.md draws a hard seam: "HUD/UI/Codex/manuscript surfaces ground in
  parchment (page); 3D scenery grounds in the violet-void cosmos family (world) — the page
  is a warm object held against a violet night." We copy Hades' *lesson* (one artist/one
  vocabulary keeps UI from feeling bolted-on) but our specific solution is the opposite of
  "same material as the world" — it's "a consistent, warm, parchment page held up against a
  cooler world," a deliberate object-in-hand framing Hades doesn't use.

- **Door/reward icon system: adopt the 3-layer anatomy (§5), not Hades' iconography.** The
  glyph/frame-color/glow-overlay *structure* is worth reusing; the actual glyphs (god heads,
  laurel wreaths) are Hades' Greek-myth vocabulary and out of scope for our
  illuminated-manuscript vocabulary — our glyphs should come from the manuscript-border /
  quatrefoil / roundel primitives already licensed in CANON.md §5 ("silhouette-safe
  primitives only — quatrefoil, caption-bar, roundel, bead-rule, corner-boss").

---

## Summary of what's solid vs. what needs verification

**Solid, directly sourced:** value/contrast-per-biome color scripting (§1), silhouette-first
design law (§2), per-god color-as-information + rim-accent + impressionist-touch technique +
pure-black shadow shapes (§3), door/reward 3-layer anatomy (§5).

**Thinner / needs a follow-up pass:** the FX layering/timing specifics in §4 (source material
gave the *what*, not frame counts or layer order — I marked my reconstruction `[inferred]`),
and UI-material specifics in §3/§7 (Josh Barnett's dual VFX+UI role is confirmed, but I
could not retrieve his own account of the UI design process — interfaceingame.com blocked the
fetch with a 403, and the 80.lv article's full technical body wasn't retrievable past its
summary). If a deeper UI/FX-timing breakdown is needed, the next step is pulling actual
gameplay-footage screenshots and running §6's checks directly against Hades frames (not just
our own), which this pass didn't have the tooling to do.
