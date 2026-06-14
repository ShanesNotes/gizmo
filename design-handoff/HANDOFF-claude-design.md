# Handoff → claude.ai/design

This is the action sheet. Goal: take **Gizmo** from locked direction to finished assets, then to Claude Code for integration.

**What to attach in claude.ai/design:** `Shape-Storm-Art-Bible.html` (or `ART-DIRECTION.md`), plus the reference SVGs in `assets/` and the four screen PNGs in `screens/`. Lead with the master brief below, then run the per-asset prompts.

---

## 0 · Master style brief (paste first, keep pinned)

```
STYLE: "Lumen & Static" — a kid-friendly bullet-heaven called Gizmo.
Flat-vector game art with confident dark outlines and soft neon glow, on a deep indigo
near-black void (#0C0A16). Premium-mobile restraint (Alto's Odyssey, Monument Valley)
meets neon-geometric arcade (Geometry Wars) meets dopamine juice (Balatro). Rounded,
friendly geometry — never babyish. Mixed ages.

PHILOSOPHY: disciplined dark minimal field; light = reward. Enemies are cool, matte,
low-glow with simple expressive faces. Pickups and the hero are bright and glowing.

PALETTE (jewel-neon): Void #0C0A16, Field #15102A, warm-white Lumen #FFF7E8.
Charge hues — Flow/mint #5BE6A4, Clutch/cyan #54D8FF, Echo/violet #A98BFF, Surge/gold #FFD24A.
Accents — Coral #FF6B7E, Pink #FF79C6, Orange #FF9D5C.

TYPE: Fredoka (display + numbers), Nunito (UI). Rounded geometric.

DELIVER: clean vector / transparent background, resolution-independent, game-ready.
```

## 1 · Hero mascot — Gizmo (master sheet)

```
Using the master style, design a turnaround + expression sheet for "Gizmo," the player
mascot: a tiny plucky spark-bot — a friendly rounded teardrop chassis (warm-white #FFF7E8
into cool violet shadow), one big glowing cyan core-lens (#54D8FF) as the eye, gold thruster
fins, a small spark antenna, and a cyan thruster plume. Strong silhouette, readable at 16px.
States: idle, thrusting (squash-stretch), hit/stunned, boost (bright streak), happy.
Match the reference gizmo.svg exactly in style; keep the dark outline + soft glow.
```

## 2 · Enemy family — the Shape Storm

```
Using the master style, expand the enemy family. Keep them COOL, MATTE, LOW-GLOW with
simple expressive faces (eyes + brow = attitude). Existing three: Drifter (indigo rounded
triangle, basic), Bumper (dusty-coral rounded square, heavy knocker, gold rivets), Behemoth
(charcoal rounded hexagon with glowing orange fault-cracks + hot core — a big target to
"burn for a Cache"). Add: a fast Splitter (diamond that halves), a Weaver (elongated, snaky),
and a boss "Storm Core." Consistent 6px dark outline, flat fills, one tonal gradient each.
```

## 3 · Pickups & FX props

```
Using the master style, finalize the pickup set, all BRIGHT + GLOWING: Spark (mint→cyan
4-point sparkle XP shard), Cache closed (dark gem, gold corner brackets, glowing cyan core
diamond, gold clasp), Cache cracked-open (gold light burst, beam, reward star, rays), Heart
(glossy coral). Add Cache tiers (common→rare→gold), a Bounty marker (coral target + gold
star), and a Magnet pickup. Match pickup-*.svg references.
```

## 4 · Per-upgrade icon set (~24)

```
Using the master style, design a cohesive icon set for roguelite upgrades, each as a single
bold glyph on a dark-glass rounded chip (#181334) with a thin colored edge + soft glow in the
system's hue. Reference icons.svg (Boost double-chevron, Flow waves, Clutch pulse-spike, Echo
rings, Surge bolt, Bounty target). Need ~24 covering: fire-rate, multishot, pierce, area/Nova,
magnet/vacuum, heal/armor, crit, slow, chain, reroll, and the four economy boosters. One glyph
each, instantly legible at 48px.
```

## 5 · Logo & key art

```
Using the master style, produce: (a) the GIZMO wordmark in Fredoka 700, gradient fill
white→mint→cyan→violet with a dark stroke and neon glow, "GIZMO SURGE" gold subtitle; (b) a
hero key-art piece — Gizmo riding a surge arc through a storm of glowing shapes over the dark
void, distant Sparks and a cracked Cache, for the title screen and store/marketing. Also a
square app-icon from the emblem (storm ring + central gold surge bolt). Reference emblem.svg
and mockup-title.html.
```

## 6 · Screen polish

```
Using the master style and the four reference mockups (title, HUD, level-up, results), refine
each to final fidelity. Keep dark-glass panels, the four-economy color coding, and the Fredoka
number style. Optimize HUD readability against the busiest field. Produce both desktop (16:9)
and mobile/portrait layouts (the game ships with touch controls + a joystick).
```

---

## Then → Claude Code (integration phase)

1. **Tokens:** add the palette as CSS variables (see `ART-DIRECTION.md` §12 map — mostly a recolor of existing `--mint/--cyan/--violet/--gold` + swapping cream `--paper` for dark glass). Add Fredoka + Nunito.
2. **HUD:** lift CSS structure from `mockup-hud.html` onto the existing DOM HUD (run-chip, stat-panel, bounty-chip, build-panel, progress-panel, the four juice chips, Boost). The element structure already matches the live game.
3. **Canvas art:** drop the SVGs in as textures (or rasterize to a sprite atlas at 2×). Wire enemy/pickup/Gizmo art.
4. **Juice:** implement §9 — squash/stretch, scaled screen-shake, hue particles, hit-stop, the Level-up Nova, Cache-crack, and audio-synced number pops.
5. **Pass order:** tokens → fonts → HUD → Gizmo + enemies + pickups → VFX/juice → menus (title/level-up/results) → mobile layout → reduced-motion.

**Definition of done for this design phase:** finished mascot, enemy family, pickups, ~24 icons, logo + key art, and four polished screens — all in "Lumen & Static," ready to wire.
