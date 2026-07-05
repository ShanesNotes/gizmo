# 02 — Images (imagegen 2.0)

`derived from ecosystem canon; do not edit as source`

Two image classes with different grammars:

**(A) Meshy reference sheets** (`gizmo-asset-pipeline/canon/prompt-grammar.yaml`): one object,
centered, fully in frame, plain pale-grey background, 3/4 elevated view (~30–45° down), even
neutral studio lighting, soft shadow; no scene, no horizon, no ground plane, no characters, no
text, no border; readable silhouette, no atmospheric haze; min 1040×1040. Hero turnarounds =
3 views (front / three-quarter / side) each suffixed: *"orthographic view, no perspective
distortion, flat camera, flat studio lighting, neutral grey background, asset reference sheet."*
**Check the back/rear geometry read before accepting.**

**(B) Art plates / HUD / key art**: full-scene grammar. Always state the **pole**
(living-faced / hollowed-faceless) and the degradation operators in play (design-system
generation-prompt grammar, G11 — describe style descriptively, never name a living artist).
Output is a draft witness; enters canon only after human review.

**STYLE TAG + NEGATIVE from README apply to all.** Page-vs-world rule (X-P1): HUD/Codex plates
ground on parchment `#fdefde`; world plates ground on violet-void `#1c1f23` / night-blue `#2a4468`.

---

## (A) Meshy reference sheets

### IMG-01..04 · enemy turnarounds (feed ENM-nibbler/dasher/brute/warden)
Use the four ENM prompt bodies from `01-3d-meshy.md` verbatim, each as a 3-view turnaround with
the orthographic suffix. Add per sheet: *"drained ash-and-slate palette with traces of former
household warmth; a blank, cracked, or veiled void where a face should be; hand-made, sad,
hollow — never military, never gory, never chrome."*

### IMG-05 · beacon turnaround (feeds q02)
q02 prompt body, 3-view turnaround + orthographic suffix. Add: *"unlit; every lamp and
candle-cup cold; the carved face on the lantern housing cracked and veiled by dust and cobweb;
warm materials under grey ash — a hearth that has been forgotten, not a machine that was
destroyed."* (Dormant state only; Rekindling/Rekindled are emissive passes, not new meshes.)

### IMG-06 · sanctuary turnaround (feeds q07)
q07 prompt body, 3-view + suffix. Add: *"the one warm pole of the sheet: small kept gold flame,
repaired lamps lit low, living vine with rose flourish on two ribs — living-faced pole, no
degradation operators present."*

### IMG-07 · orrery altar (feeds q06 if no approved reference exists)
q06 prompt body, single 3/4 hero view + grammar A rules.

---

## (B) Key art & world plates

### IMG-10 · master key art — "the vigil"
> A hand-painted gouache storybook plate, deep violet-indigo cosmos with soft warm nebula
> orange smeared through distant clouds, quiet light not neon. In the foreground a small
> stocky handcrafted brass clanker — warm matte brass with hand-made seams, a single serene
> teal-cyan glowing eye-core, the only saturated teal in the image — walks a broken sandstone
> causeway across a wounded floating island, carrying a small kept lantern-warmth about him.
> Far ahead at the cold end of the island, a tall dormant hearth-beacon stands grey and
> snuffed under ash. Behind him, the warm hearth he left glows faintly at the frame's edge.
> Composition follows a warm luminous center-of-care against cold massing at the edges;
> one continuous unbroken gold thread of path light runs from hearth to beacon, never
> segmented. Living-faced pole in the south of the frame, hollowed-faceless drain toward the
> north; the de-facing — not the darkness — is what reads as wrong.
- Provenance: M2, M5 (thread never a meter, G4), M8, X-L2 (thread = Shattered Meridian re-joined), X-P4 body contract, ART_DIRECTION palette.

### IMG-11 · Gizmo character plate (portrait/marketing, NOT a Meshy ref)
> Gouache storybook portrait of Gizmo: a small handcrafted brass-and-bronze clanker, short
> stocky silhouette, kettle-round chest with hand-riveted seams, stubby capable arms, one
> single large serene teal-cyan eye-core glowing softly — a face, present and alive. Earnest,
> dutiful, a little worn, plucky. Warm workshop light, parchment-warm backdrop vignetting to
> deep violet. No second light source on his body; the eye/core is the only teal.
- NEVER: industrial robot, chrome android, military hardware, cartoon toy mascot, second teal emitter (X-P4).

### IMG-12 · end screen — Beacon Rekindled (win)
> A gouache ceremonial plate on a parchment ground with a gilt living-vine frame (ornate
> brass filigree cartouche, riveted edges): at center a rekindled hearth-beacon crowned with
> an open warm gold sun-face mandorla, warmth visibly pushing from center to periphery,
> snuffed candle-cups relit, the tiny teal core-spark alive at the flame's very heart. Below,
> small and steadfast, Gizmo looks up. Quiet light, not fireworks. Space reserved for the
> caption "Beacon Rekindled" set later in real type — do not paint text.
- Copy law: caption is "Beacon Rekindled" — never "you win", never time survived (ADR 0005, N8).

### IMG-13 · end screen — Gizmo's light failed (loss)
> A gouache plate on a drained parchment ground, frame gone grey stone with cobweb in the
> corners (M1 hollowed register): Gizmo kneeling small in a cold field, his eye-core dimmed
> to the faintest ember — dimmed, not shattered — while soft ash falls. Sad but savable;
> tender, never gory, never hopeless. The vigil rhythm: this is a lamp lowered, not a death
> celebrated. No painted text; caption "Gizmo's light failed" set in real type.
- NEVER: "you died / retry" tropes, skulls, red vignette (G9).

### IMG-14 · Codex plate background (UI/ceremony motif)
> An illuminated-manuscript margin plate: warm parchment ground, gilt bead-rule border,
> hand-inked living vine with small rosettes climbing one margin, a small moth resting near
> an inked marginal note-mark, generous empty vellum space at center for live text. Ceremony
> and memory — a record, not a menu.
- Provenance: Codex = UI/memory/ceremony motif only (N7); Marginalia's hand (X-L4). Parchment ground is correct here (page surface).

---

## (C) HUD elements (match `design-handoff/gizmo-hud.png` — read it before generating)

All HUD art: parchment/brass page surfaces, silhouette-safe primitives only — quatrefoil,
caption-bar, roundel, bead-rule, corner-boss. **No fine filigree/knotwork at HUD scale (G7).**
Generate as clean elements on neutral background for slicing; numerals/labels are live Godot
fonts (Cinzel/EB Garamond/Spectral) — never paint text.

### HUD-01 · nameplate + portrait roundel
> An ornate brass portrait roundel with riveted rim and small corner-boss flourishes, holding
> a painted miniature of Gizmo's faced eye-core; attached caption-bar in warm parchment with
> empty space for a name label. Silhouette-safe shapes, no fine filigree.

### HUD-02 · guard-over-HP bar pair
> Two stacked horizontal bar housings in beveled brass cartouche style: the upper, slightly
> larger bar glowing soft teal-cyan `#3fa9b6` (recoverable guard light — the guard layer is
> a licensed teal surface); the lower, smaller bar in warm vermilion `#c34f32` (mortal HP).
> Clearly two different substances: guard reads as protective light, HP reads as life. Empty
> and full states for each.
- NEVER one merged bar; never teal HP; guard/HP bars are resource readouts, NOT the M5 thread (G4). Provenance: ADR 0007, tokens `guard/hp`.

### HUD-03 · level badge
> A large violet spark-gem (violet body `#8a5bb0`, warm gold-white inner glow) framed in a
> brass quatrefoil badge with riveted edge; empty center-space for a live numeral.

### HUD-04 · objective cue card
> A small parchment caption-bar with brass corner-bosses and a tiny unlit/lit lantern icon at
> its left end (lantern lights when the Beacon is Rekindling). Space for live text.
- Copy it will carry: "Reach the Beacon" / "Rekindle the Beacon" / "Hold until the Beacon warms" — never wave/timer copy (N8).

### HUD-05 · Sparks & Scrap counters
> Two small stacked counter chips: (1) a violet spark-gem icon with warm inner glow; (2) a
> matte brass gear icon, unlit. Visibly different value-registers: light vs salvage. Brass
> bead-rule separators; space for live numerals.

### HUD-06 · Core Matrix ability bar
> A bottom bar of four brass roundel sockets with beveled cartouche housing: three open
> sockets for painted ability icons, the fourth visibly banded shut with a brass strap
> (locked, dormant — not a padlock icon). Small key-cap notches for live "1 2 3" labels.

### HUD-07 · gadget slots
> Two small square brass-cornered parchment slots side by side with L/R notch marks, matching
> the Core Matrix material family but visually subordinate to it.

### HUD-08 · Spark of Humanity meter (bottom-right)
> A ceremonial standing reliquary gauge: a tall thin brass-and-glass vessel on a parchment
> mount holding a soft warm gold-white radiance — sacred, museum-kept, deliberately unlike
> the guard/HP bars and unlike the Sparks counter in shape, angle, and material. It reads as
> a kept vow, not a fuel tank.
- Law: Spark of Humanity is theme-level; this HUD element exists in the reference HUD but its mechanics are TBD — render it distinct from every other quantity and never as depleting fuel (ADR 0001, N5).

### HUD-09 · rekindle channel indicator (near Beacon only)
> A circular brass mandorla ring that fills with warm gold flame-light around a small beacon
> icon: three states — Dormant (grey, snuffed icon), Rekindling (ring filling with warm gold,
> ember flicker), Rekindled (full warm sun-face glow). The fill is warmth spreading, not a
> countdown ring (M8 "don't").

### HUD-10 · ability icon set (spark zap / pulse / orbit / nova / dash / surge / flow / clutch)
> Eight painted miniature icons on brass roundels, each a single bold silhouette-safe symbol:
> a forked living-light arc; a soft concentric pulse bloom; three small orbiting stars; a
> radiant nova burst; a motion-streak boot; a rising surge chevron; a flowing ribbon curve
> (continuous, unbroken); a clasped small hand-guard. Warm gilt on deep ink, readable at
> 32 px. The living-light arc icon may not use saturated teal — gild it (G6 scarcity).
