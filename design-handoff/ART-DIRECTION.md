# GIZMO — Art Direction (v1.0)

**Primary direction: "Lumen & Static."** *A spark relighting the dark.*
Portable text companion to `Shape-Storm-Art-Bible.html`. Everything below is the canonical spec for claude.ai/design and Claude Code.

---

## 1. The game in one breath

A kid-friendly **bullet-heaven / survivors-like** built in Phaser. The player dodges a storm of shapes, vacuums XP "Sparks," levels up to pick roguelite upgrades, pops big shapes for loot "Caches," and feeds **four parallel reward economies** (Flow, Clutch, Echo, Surge) plus Bounty chains and a timing-based Boost. The loop is proven and fun. Only the art needs replacing — it is currently placeholder.

## 2. Concept

- **World — "The Hush":** a vast, dormant machine-cosmos drained of color. **Shape Storms** (waves of charged geometric debris) roll through and briefly wake it.
- **Hero — "Gizmo":** a tiny, plucky spark-bot — a glowing cyan core in a friendly chassis. Strong silhouette; reads at 16px.
- **The thesis:** *the fiction is the design philosophy.* A disciplined dark, minimal void where **light = reward**. Every dopamine burst is earned and distilled against calm negative space. The player literally brings color back to the dark.

## 3. Design pillars

1. **Distilled dopamine** — calm readable core, bright loud payoffs. Minimalism makes the pop land.
2. **Juice is the design** — feedback (shake, squash, particles, escalating numbers) is the product, not polish.
3. **Confident, friendly geometry** — flat vector, rounded but not babyish, bold outline + soft glow. Premium-mobile restraint on a neon-dark field.
4. **Every shape is alive** — enemies have faces and attitude. The anti-generic move.
5. **Read it in a glance, at couch distance** — color-code every system; surface meters only when they matter.

## 4. Color system

Jewel-neon, not candy. Deep indigo void, warm-white light, four locked "charge" hues, tight accents.

### Base & surface
| Token | Hex | Role |
|---|---|---|
| Void | `#0C0A16` | Space base / deepest bg |
| Field | `#15102A` | Raised playfield |
| Dark Glass | `#181334` @ ~72% α | HUD panels (with backdrop-blur + 1px luminous edge `rgba(255,247,232,.14)`) |
| Lumen | `#FFF7E8` | Warm-white text/ink |
| Lumen-dim | `rgba(255,247,232,.62)` | Secondary text |

### The four charge hues — locked to the feedback economies
| System | Hue | Hex |
|---|---|---|
| **Flow** | Mint | `#5BE6A4` |
| **Clutch** | Cyan | `#54D8FF` |
| **Echo** | Violet | `#A98BFF` |
| **Surge** | Gold | `#FFD24A` |

### Accents
| Name | Hex | Role |
|---|---|---|
| Coral | `#FF6B7E` | Health · Bounty · danger |
| Pink | `#FF79C6` | Epic rarity · Flow-hot |
| Orange | `#FF9D5C` | Heat · big-shape burn |

### Usage rules
- **Enemies are cool & matte, low-glow** (indigo, dusty coral, charcoal). They are the storm; they keep the field calm.
- **Pickups & the player are bright & high-glow.** Sparks, Caches, Gizmo's core own the light → instantly read as "good / get this."
- **Each system keeps its hue everywhere** — meter, icon, callout, particle, and the upgrade that feeds it.
- **Gold is sacred** — Surge, Caches, score, best/evolve only. Don't dilute it on chrome.

### Rarity ladder
Common `#9892B4` (flat) → Uncommon `#5BE6A4` (subtle glow) → Rare `#54D8FF` (medium glow + sheen) → Epic `#FF79C6` (strong glow, lifts on hover) → Evolve `#FFD24A` (max glow, double frame, corner flourish).

## 5. Typography

Two rounded-geometric Google Fonts. Friendly for kids, confident enough to read premium.

- **Display & numbers — Fredoka** (600–700): wordmarks, screen titles, card names, and every dopamine number (score, combos, `+250` pops). Hero numbers get a tonal gradient + glow and should scale-up-and-settle on change.
- **UI & body — Nunito** (800–900): labels, stats, descriptions, eyebrows. Heavy weights for presence on dark.
- **Eyebrows/labels:** Nunito 900, UPPERCASE, letter-spacing 1.5–2px, dimmed — they frame the value, never star.
- Minimum 11px. Tabular figures for anything that ticks. Sentence case for body; ALL-CAPS only for short callouts.

## 6. Form language

- Built from circles, rounded triangles, rounded squares, hexagons, diamonds. Generous corner radii.
- **Confident outline** (cool dark, ~6px at 200px size) for cel definition; **soft outer glow** only on energized things, matte for inert.
- Single soft top light → top sheen + cool underside. One bright focal core per hero element.
- Enemies get **faces** (eyes + brow set attitude). Flat fills + one tonal gradient; no rendered realism.

## 7. The four economies (signature system)

| System | Hue | Icon | Feeling | Payoff |
|---|---|---|---|---|
| Flow | Mint | current/waves | uninterrupted sweeping | Flow Rush — field-wide pull |
| Clutch | Cyan | pulse spike | daring near-misses | Clutch Burst — detonate, snap-boost |
| Echo | Violet | concentric rings | a power window open | Echo Rush — extend & chain |
| Surge | Gold | lightning bolt | charge building | Surge Burst — big stored discharge |

Plus **Bounty** (coral chase chains) and **Cache** (gold loot). The HUD stacks these in a bottom cluster so a glance reads the whole board.

## 8. Screens (built as faithful HTML/CSS)

- **Title** (`mockup-title.html`) — wordmark gradient + glow, Gizmo on a surge arc, distant storm.
- **HUD** (`mockup-hud.html`) — dark-glass panels; four-economy cluster; `+250 CLUTCH!` number pop; score/hearts/stats/bounty/build/XP+run meters/Boost.
- **Level-up** (`mockup-levelup.html`) — rarity ladder (Rare/Epic/Evolve), hotkeys, reroll.
- **Results** (`mockup-results.html`) — big score, records, color-coded run awards, "Run it back."

## 9. Motion, juice & VFX (most important)

**Always-on game feel:** squash & stretch (thrust, pops, deaths); screen-shake scaled to event weight; particles in the system's hue; hit-stop (1–3 frame freeze) on big pops.

**The big beats:**
- **Level-up Nova** — field dims a beat, then a hue-shifting shockwave relights it (the minimalism → payoff moment).
- **Cache crack** — gold flash, light beam, reward arcs out, chunky number.
- **Economy bursts** — each detonates in its own color so the player knows *which* joy fired.

**Audio-visual sync (the Balatro lesson):** numbers escalate in pitch *and* size together; a scoring chain feels like a slot-machine cascade — every tick lands a sound + scale-bump + shake in lockstep.

**Accessibility:** honor `prefers-reduced-motion` (keep color/scale, drop shake/heavy particles). Never rely on color alone — pair every hue with an icon and motion.

## 10. Alternate directions

- **A · Paper Tinkerer (warmer):** elevate the original watercolor "inventor" world into a premium storybook craft look. Warm paper, ink, gouache. Charm over arcade punch.
- **B · Pure Neon Vector (cooler):** strip the faces — Gizmo a pure glyph, enemies clean signed shapes. Maximal Geometry-Wars minimalism.

The primary (**Lumen & Static**) sits between: characterful but disciplined.

## 11. References (the blend)

Balatro (juice-is-design, audio-synced escalation) · Geometry Wars (neon-on-dark geometric storms) · Vampire Survivors / 20 Minutes Till Dawn / Brotato (survivors-like loop) · Alto's Odyssey / Monument Valley (flat-vector premium restraint) · Hades (striking but non-intrusive HUD) · Astro Bot (lovable robot mascot, expressive silhouette).

## 12. Handoff notes for Claude Code

**Continuity = a cheap pass.** The charge hues map ~1:1 to the existing CSS vars. Real work: deepen base to Void, swap cream "paper" panels for **dark glass**, add the **type + glow** system, apply the asset language.

| Existing var | Was | New |
|---|---|---|
| `--ink` / bg | #17121f / #24172d | **#0C0A16** (field #15102A) |
| `--paper` | cream | **Dark glass #181334 .72α** |
| `--mint` | #70e6a8 | #5BE6A4 (Flow) |
| `--cyan` | #59dbff | #54D8FF (Clutch) |
| `--violet` | #b78cff | #A98BFF (Echo) |
| `--gold` | #ffd35a | #FFD24A (Surge) |
| `--coral`/`--pink` | #ff6584 / #ff79c6 | #FF6B7E / #FF79C6 |
| font | Arial | **Fredoka + Nunito** |

**Asset production checklist:** Gizmo states (idle/thrust/hit/death/boost + squash loop); 2–3 more enemy archetypes + a "Storm Core" boss; ~24 per-upgrade icons in the chip style; particle atlas (sparks, confetti, Nova rings, hue bursts ×4); Cache tiers; wordmark as outlined SVG + favicon from emblem.
