# Gizmo — The Lumen Codex Design System

> *A spark re-illuminates a sleeping codex — and the dopamine becomes a verdict.*

**Gizmo** is a kid-friendly **bullet-heaven / survivors-like** (built in Phaser). You pilot a tiny neon spark-bot through a storm of charged shapes, vacuum XP "Sparks," level up to pick roguelite upgrades, crack loot "Caches," and feed four parallel reward economies. The proven loop needed a soul — and got one.

**The Lumen Codex** is the design system that fuses two worlds:
- **"Lumen & Static"** — premium neon arcade on a disciplined dark void, where *light = reward*.
- **The Symbolic World** grammar — illuminated-manuscript craft: gold-leaf, ink contours, sealed emblems, charged empty space, *borders that behave*.

They look like opposites (glow/speed vs. ink/weight). **The hinge is gold.** Surge — the arcade's biggest payoff — is gold. Illumination — the manuscript's word for a blessing made visible in gold-leaf — is also gold. So neon *light* sits inside ancient *gold-ground*, and **every reward becomes an illumination.**

---

## Sources (design handoff)

This system was authored from a complete art-direction handoff package. The reader is not assumed to have access; paths recorded for provenance:

- `design-handoff/ART-DIRECTION.md` — canonical "Lumen & Static" spec (color, type, form, motion).
- `design-handoff/FUSION-CODEX.md` + `Fusion-Codex.html` — the fusion layer ("The Lumen Codex"): reframe table, fused palette, fidelity rules.
- `design-handoff/HANDOFF-fusion.md` / `HANDOFF-claude-design.md` — paste-ready prompts + Symbolic-World fidelity rules.
- `design-handoff/Shape-Storm-Art-Bible.html` — the base-direction visual showpiece.
- `design-handoff/mockup-*.html` — built HTML/CSS screens (title, HUD, level-up, results) + fused variants. **These are the visual source of truth** and were lifted near-verbatim into the token system and UI kit.
- `design-handoff/assets/` + `assets-fusion/` — SVG sprite sheets (gizmo, enemies, pickups, covenant emblems, rarity ladder, the Illuminated-G emblem).
- `design-handoff/brand/` — polished raster emblem + logo lockup (image-gen finals).
- `design-handoff/screens*/` — reference PNG renders.

Uploaded duplicates also live in `uploads/` (emblem, covenant-emblems, rarity-illuminated, logo lockup, etc.).

---

## CONTENT FUNDAMENTALS — how Gizmo speaks

The voice is **a manuscript narrating an arcade.** Verdicts, not notifications. Every label is chosen to make a reward feel *earned and recorded*, never spammed.

**Register & person.** Second person, imperative, short. *"Pick your surge." "Chase the gold — seal the bounty." "Press any key to wake the page." "Run it back."* The game addresses **you**; it never says "I." Copy is encouraging but disciplined — it respects the player's intelligence.

**Two diction layers, deliberately mixed.**
- **Arcade plain** (UI body, Nunito): clear, punchy, kid-readable. *"Your pulse fires a second beat on every shot." "Fire Rate +18%."*
- **Manuscript elevated** (labels & verdicts, Cormorant): the system's ceremonial voice. The four economies are **covenants** — *Flow · Thread, Clutch · Breath, Echo · Vigil, Surge · Seal.* Score is **Illumination**. Hearts are **Breath**. A level is a **Rank** (in roman numerals — *Rank VII · Illuminating*). A Cache is a **Sealed Reliquary**. Leveling up = *waking the page* (*"340 to wake"*).

**Casing.** Sentence case for body and descriptions. **ALL-CAPS only for short dopamine callouts** (`ILLUMINED!`, `STORM CLEARED`, `LEVEL UP`, `BOOST`, `RUN IT BACK`). Manuscript eyebrows are UPPERCASE with wide tracking (*ILLUMINATION, COVENANT, RELIQUARY, POWER, VIGIL*) — they frame the value, never star.

**Numbers are characters.** Every dopamine number is a hero: scores with commas (`42,180`), multipliers (`×3`, `×24`), deltas (`+250`, `+12,400`), roman ranks (`VII`, `Rank XIV`). They get the gold-leaf inscription treatment and *scale-up-and-settle* on change.

**Naming pattern for upgrades.** Two short words, evocative + mechanical: *Pulse Driver, Spark Magnet, Echo Coil, Nova Bloom.* Awards are `Role + noun`: *Bounty Hunter, Flow Master, Clutch King, Cache Cracker.*

**Tone words:** plucky, distilled, ceremonial, generous-but-honest. *Beauty may cost* — the false-gift Reliquary keeps danger real. **No emoji** in copy (the lone `⚡` on the Evolve pill is an icon glyph, not punctuation). No exclamation-spam — one `!` per payoff, max.

**Do not write:** generic-game filler ("Congratulations!", "Achievement unlocked"), modern-app chrome ("Settings updated"), or hype adjectives ("epic loot!!!"). Let the verdict be quiet and the number be loud.

---

## VISUAL FOUNDATIONS

**The thesis is the fiction:** a disciplined dark void where light is earned. Minimalism makes the pop land. Calm readable core, bright loud payoffs.

**Background.** Deep indigo **void** (`#0C0A16`) lifted by a warm radial — `radial-gradient(120% 90% at 50% 20%, #1C1540, #130E2A, #0A0814)`. Over it sits **stipple radiance**: a fine gold-dust dot grid (`radial-gradient(rgba(232,188,136,.14) 1px, transparent 1px)` at ~13–15px pitch, ~45% opacity), often masked to bloom toward the focal point. **Glow is built from dots, not bloom** — radiance reads as *made*, a texture, never generic-AI sheen/fog/bokeh. Sparse `40px` dot grids appear on results/field surfaces.

**Color vibe.** Warm:cool ≈ **9:1** — cool is an *event*. Only **red and gold saturate**; mint/cyan/violet are reserved for the four economies and read as charged light, not candy. **Gold carries light · red (oxblood) carries cost · ink makes it official.** Enemies are cool, matte, low-glow (they're the storm, they keep the field calm); pickups + the player are bright and high-glow (they own the light → "get this").

**Type.** Three voices (see Type tokens): **Fredoka** for display + every dopamine number (gold-leaf gradient fill + `~2.5–3px` ink `text-stroke` + soft gold drop-shadow = "inscription"); **Cormorant Garamond** for manuscript labels/verdicts/taglines (often italic); **Nunito 800–900** for UI body. Tabular figures for anything that ticks. Minimum 11px.

**Panels (the "page apparatus").** HUD panels are **dark glass**: `rgba(20,15,34,.82)` fill, **2px tarnished-gold border** (`#A87A2E`), `12px` radius, an **inner luminous edge** (`inset 0 0 0 1px rgba(232,188,136,.30)`), a soft drop (`0 14px 34px rgba(0,0,0,.5)`), and a **dashed inner rule** 4px inset (`1px dashed rgba(232,188,136,.30)`). The whole screen is wrapped in a **page frame** with **corner wax-seals** (oxblood diamonds, gold-bordered, rotated 45°).

**Cards.** Upgrade cards: `20px` radius, vertical gradient fill (`rgba(34,28,64,.92) → rgba(18,14,36,.96)`), a **rarity border** (3px, colored per tier) and a faint corner "flare" ring. **Rarity signals by gold-leaf & seal density FIRST, glow second** — Common (flat) → Uncommon (subtle) → Rare cyan → Epic pink (lifts `translateY(-14px) scale(1.02)`) → Evolve gold (max glow, double frame). Results dialog: `26px` radius, emblem notched above the top edge.

**Borders & radii.** Confident, never hairline-timid: 2–3px gold/ink contours on anything official; generous corner radii (8 → 12 → 14 → 20 → 26px; `99px` pills; `50%` roundels & seals). Inner cells use `8–9px`.

**Shadows.** Two systems: (1) **outer drop** for float/depth (`0 14–40px` blacks); (2) **inner luminous edge** for the gold-leaf seam. Reward elements add a **glow ring** (`0 0 0 5px` hue at low alpha) — surge gold, flow mint. Rarity glow is additive and *secondary*.

**Hover / press.** Hover = **lift + intensify glow** (epic card lifts and scales; buttons brighten their hue, deepen the ring). Press = **squash** (`scale(.96)`) + shadow collapse — squash & stretch is the house feel. Transitions use an **overshoot-and-settle** ease (`cubic-bezier(0.34,1.56,0.64,1)`); numbers *scale-up-and-settle*. Never linear, never a plain fade for a payoff.

**Motion.** Always-on juice: squash/stretch, screen-shake scaled to event weight, particles in the system's hue, 1–3 frame hit-stop on big pops. Signature beats: the **Level-up Nova** (field dims a beat, a hue-shifting shockwave relights it → now an **Illumination**: gold-ground blooms behind an ink sigil), the **Cache crack** (gold flash, light at the seams, reward arcs out), and four color-keyed **economy bursts**. Honor `prefers-reduced-motion` (keep color + scale, drop shake/heavy particles). **Never rely on color alone** — every hue pairs with an icon and a motion.

**Transparency & blur.** Used purposefully: dark-glass panels are translucent over the field; level-up dims the field with a `blur(7px) brightness(.6)` + `rgba(8,6,18,.66)` scrim. Not a default — clarity wins.

**Material memory.** Damage and restoration leave a mark — a seam / craquelure remains; no clean reset. Enemies are **counterfeit authority**: crooked false crowns, mismatched ornament, craquelure when struck. The gold **aureole** behind a payoff is *secular geometry* — never a literal halo, no sacred/religious imagery.

**Charged empty space frames every payoff.** The most important rule: keep the center quiet so the illumination lands.

**Responsive & touch.** The game canvas is fluid full-viewport, not a fixed size. Honor the shipping build's breakpoints verbatim — `980px` (tablet), `560px` (phone portrait), `max-height:620px` (short/landscape), and the `(hover:none) and (pointer:coarse)` touch trigger — and pad every fixed overlay with `env(safe-area-inset-*)`. On touch, the **page apparatus grows a control surface**: a fixed bottom-left thumbstick (112/52 → 94/44, knob never below the 44px min target) and a right-side **Snap-Boost button** whose six timing states read by color *and* label (gold ready/window, oxblood queued, mint scooping, dark-glass sweep cooling). It's a re-skin of what already ships — behavior is documented in `TOUCH-AND-RESPONSIVE-SPEC.md`, not re-decided. The cluster never hides game state; it telegraphs it.

---

## ICONOGRAPHY

Gizmo's icons are **flat-vector SVG sprite sheets**, hand-built in the brand's form language (circles, rounded triangles, hexagons, diamonds; confident cool-dark outline ~6px at 200px size; soft outer glow only on energized things, matte for inert; one bright focal core per hero element; enemies get **faces** — eyes + brow set attitude). **All copied into `assets/`** — never hand-roll replacements.

- **`assets/sprites/icons.svg`** — the upgrade-chip icon atlas (96×96 cells, sliced with `object-position`, e.g. `-200px 0`, `-300px 0`, `-500px 0`). Used on level-up cards and build pills.
- **`assets/sprites/covenant-emblems.svg`** — the four covenant roundels in one 600px-wide sheet (~150px cells: Flow·Thread, Clutch·Breath, Echo·Vigil, Surge·Seal) plus the Sealed Reliquary and a counterfeit enemy. Sliced via `object-fit:none; object-position`.
- **`assets/sprites/rarity.svg`** / **`rarity-illuminated.svg`** — the 5-tier rank ladder.
- **`assets/sprites/`** — entity sprites: `gizmo.svg`, `gizmo-illuminated.svg`, enemies (`enemy-drifter`, `enemy-bumper`, `enemy-behemoth`, `enemy-counterfeit`, `enemy-family`, `boss-storm-seal`), pickups (`pickup-spark`, `pickup-heart`, `pickup-cache`, `pickup-cache-open`), `cache-reliquary`, `nova-emblem`.
- **`assets/brand/`** — `emblem-illuminated.svg` (the chosen Illuminated-G), `emblem-mark-mini.svg` (neon-matched for tiny sizes), `emblem.svg`, plus raster finals: `emblem-flat-raster.png`, `emblem-medallion-raster.jpg`, `logo-lockup-raster.jpg`.

**Emoji:** not used in copy or UI. **Unicode glyphs:** only a couple as functional marks — `⚡` on the Evolve pill, `✦` for a sealed/maxed slot, `↻` on Reroll, `★` on a new-best badge. No external icon font is required; everything ships as project SVG. If a consumer needs a UI glyph not in the sheets, match the flat-vector / 6px-outline style rather than importing a generic icon set.

---

## INDEX — what's in this system

**Foundations** (`tokens/`, all `@import`ed by root `styles.css`)
- `tokens/colors.css` — void & surfaces, the light, the matter (ancient pigments), four charge hues, accents, glow alphas, semantic aliases.
- `tokens/typography.css` — three families, display/manuscript/body scales, the `.lumen-inscription` + `.lumen-eyebrow` recipes.
- `tokens/spacing.css` — space scale, radii, borders, shadows, motion eases, touch/responsive geometry, `.lumen-stipple` + `.lumen-frame` + `.lumen-seal` utilities and the `lumen-snap`/`lumen-scoop` state keyframes.
- `tokens/fonts.css` — Fredoka · Cormorant Garamond · Nunito (Google Fonts).

**Specimen cards** — small HTML files across groups Type / Colors / Spacing / Brand, rendered in the Design System tab.

**Components** (`components/`) — reusable React primitives (see each `*.prompt.md`):
- `components/core/` — Button, Panel, Pill, Keycap, Meter, Seal, Eyebrow.
- `components/game/` — CovenantRoundel, UpgradeCard, StatCell, BreathRow, VerdictBar (+ `compact` bounty chip), and the **touch layer**: Joystick, BoostButton (six snap states), TouchControls.

**UI kit** (`ui_kits/lumen-codex/`) — interactive recreations:
- `index.html` — the four desktop screens: Title, HUD, Level-Up, Results (1280×720 stage).
- `mobile.html` — the **portrait HUD** + live touch cluster (fluid, safe-area-aware), in a phone frame.

Both kits carry a **Tweaks** panel — Full/Calm/Minimal declutter presets plus field, panel-opacity, and cluster controls (the mobile one adds a fixed↔floating joystick switch).

**Templates** (`templates/`) — copy-and-go starting points consuming projects can seed from (shown in the Templates picker):
- `templates/lumen-codex/` — the desktop four-screen game UI.
- `templates/lumen-codex-mobile/` — the portrait HUD + touch controls.

**Other**
- `TOUCH-AND-RESPONSIVE-SPEC.md` — exact touch + responsive geometry reverse-engineered from the shipping Phaser build (joystick sizes, anchors, safe-area math, breakpoints, every Boost state). The source of truth for the touch layer.
- `SKILL.md` — Agent-Skills-compatible entry for downloading + using this system.
- `assets/` — all sprites, emblems, brand rasters, reference screens.
