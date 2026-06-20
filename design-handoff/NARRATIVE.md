# Narrative — canon

Single source of truth for Gizmo's premise, world, and fiction→mechanics
mapping. Look and feel stay owned by `design-handoff/ART_DIRECTION.md` (references
`godot/assets/gizmo.glb` + `design-handoff/gizmo-hud.png`); the *story* lives here.

- Status: Canon (adopted 2026-06-16)
- Supersedes the standalone "neon spark re-illuminates an ancient codex"
  one-liner; that imagery survives as a **sub-motif** (§5).

## 1. Logline

> **Gizmo is a rogue-lite in which Gizmo, a clanker, preserves the spark of
> humanity through increasingly difficult waves of enemies, elites, and bosses,
> across a gouache cosmos of lost tech — guarding it from the ever-encroaching
> dehumanized technology.**

## 2. The three pillars

- **Gizmo, the clanker.** A small brass-and-bronze machine with a glowing core.
  The irony is the heart of the game: a *robot* is the last keeper of what is
  human. He is plucky, dutiful, hand-made — the opposite of the cold tech he
  fights. (Model: `godot/assets/gizmo.glb`; look target: `design-handoff/gizmo-hud.png`.)
- **The spark of humanity.** The warm light Gizmo gathers and guards. It is
  literally his glowing core, and it is the thing the cosmos is losing — the
  **Spark of Humanity** meter you must keep alive ("Keep it safe. Keep it
  alive."), carried through objectives like *Carry the Spark to the Beacon*. In
  mechanics the rescued fragments are **Sparks**, the primary currency the player
  vacuums up (with **Scrap** as the secondary). Collecting Sparks isn't "leveling
  up an RPG character," it's *rescuing fragments of humanity* before the cold
  takes them.
- **The dehumanized technology.** The antagonist. Not evil masterminds —
  machinery that has forgotten the people it was built for: hollow, repeating,
  counterfeit. The enemy "shapes" are this tech, encroaching. (This reconciles
  the older "counterfeit authority" enemy framing: counterfeit *humanity*.)

## 3. The world — a gouache cosmos of lost tech

A painted, storybook cosmos (matte gouache / low-fi 1990s-cartoon look — deep
violet and indigo, teal, warm nebula orange, a battlefield of floating platforms
and debris) strewn with **lost tech** — dead gadgets, drifting devices, sealed
machines. This is **"The Hush"**: the quiet after humanity's warmth drained out.
Gizmo moves through the Hush relighting it, one rescued spark at a time.

- **Lost tech** is recoverable. Sealed devices = **Caches** ("reliquaries").
  Cracking one releases preserved spark and, sometimes, an evolution — a fragment
  of human ingenuity Gizmo can fold into himself.

## 4. System → fiction mapping

The mechanics already exist in `game-src-phaser/src/game/simulation.ts`; the
premise gives each one a reason. Keep this table true to the code.

| System (code) | Fiction | Note |
|---|---|---|
| **Sparks** (`xp` pickups, `xp`/`nextXp`) | fragments of the human spark, rescued | the primary currency; the thing being preserved |
| **Scrap** (secondary currency) | salvage stripped from broken tech | spent alongside Sparks |
| **Level up → upgrade draft** | Gizmo re-humanizing himself with what he saved | rarity `common→epic` = how rare the recovered human trait is |
| **Core Matrix** (ability loadout, keys 1/2/3) | the human reflexes Gizmo has relit, ready to fire | the build's active abilities |
| **Gadgets** (L/R activated items) | salvaged tools of human ingenuity | situational, hand-triggered |
| **Cache** (`pickup: cache`, `cacheEvolutions`) | sealed **lost tech / reliquary**; cracking it frees spark + evolutions | the "dopamine" reward gate (Balance §8.1) |
| **Heart** (`pickup: heart`) | a surviving ember of warmth | recovery, capped (Balance §3.3) |
| **Waves → elites → bosses** (`nibbler/dasher/brute/warden`) | the dehumanized technology, encroaching in escalating forms that crest into elites and bosses | TTK bands (Balance §5.4) |
| **The four covenants / economies** | the facets of the spark Gizmo keeps lit | see below |
| **Bounty** | a call to rescue a threatened pocket of the cosmos | risk/streak chase |
| **Boost / Snap Boost** | Gizmo's hand-timed scoop — human skill, not automation | timing window = the human touch |
| **All waves cleared (run complete)** | the Hush pushed back for one vigil | bounded wave-based run |

### The four economies, as facets of the spark

| Economy | Color | Fiction |
|---|---|---|
| **Flow** | mint `#5BE6A4` | momentum — humanity moving, not frozen |
| **Clutch** | cyan `#54D8FF` | the near-miss; grace under threat |
| **Echo** | violet `#A98BFF` | memory — the spark remembering itself |
| **Surge** | gold `#FFD24A` | the payoff bloom; reward = gold, always |

## 5. The codex sub-motif (retained, demoted)

An earlier framing cast everything as an **illuminated manuscript** that a neon
spark re-lights ("the Lumen Codex," "wake the page," covenant sigils). That craft
is *not* discarded — it survives here purely as fiction, reframed:

- The **Codex** is the record of every human spark Gizmo has preserved. Each
  rescued fragment is "illuminated" into it. So "illumination" (the gold-leaf
  payoff, the level-up verdict) still means *a fragment of humanity made bright
  again* — now it's the gameplay reward, not the premise.
- Manuscript craft (deckle frames, gold leaf, Cormorant verdicts, covenant
  roundels) stays the **UI/ceremony language**. The *world* you fly through is
  the gouache cosmos of lost tech; the *interface* that records your wins is the
  Codex. Two layers, no conflict.

## 6. What this changes (and doesn't)

- **Changes:** the public one-liner; the *meaning* of Spark (now humanity, not
  "light for a book"); enemy framing (dehumanized tech); the world's headline
  (gouache cosmos of lost tech).
- **Does not change:** any economy name or mechanic in the Phaser seed
  (`simulation.ts`). This is a fiction layer over a frozen system; the visual
  look is owned by `ART_DIRECTION.md` (target: `gizmo-hud.png`).

## 7. Voice

Plucky, warm, distilled, a little ceremonial. Gizmo is earnest; the cosmos is
sad-but-savable; victory is quiet light, not explosions. Microcopy rules:
sentence case, one `!` per payoff, UPPERCASE only for short callouts, functional
glyphs only.
