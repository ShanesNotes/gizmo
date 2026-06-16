# Narrative — canon

Single source of truth for Gizmo's premise, world, and fiction→mechanics
mapping. Look and feel stay owned by `FUSION-CODEX.md`; the *story* lives here.

- Status: Canon (adopted 2026-06-16, ADR-013)
- Supersedes the standalone "neon spark re-illuminates an ancient codex"
  one-liner; that imagery survives as a **sub-motif** (§5).

## 1. Logline

> **Gizmo is a clanker tasked with preserving the spark of humanity — protecting
> it from the ever-encroaching dehumanized technology, across a gouache cosmos
> filled with lost tech.**

## 2. The three pillars

- **Gizmo, the clanker.** A small brass-and-bronze machine with a glowing core.
  The irony is the heart of the game: a *robot* is the last keeper of what is
  human. He is plucky, dutiful, hand-made — the opposite of the cold tech he
  fights. (Mascot art: `art/character/gizmo-walk-source.png`; vector states in
  `assets-fusion/gizmo-illuminated.svg`.)
- **The spark of humanity.** The warm light Gizmo gathers and guards. It is
  literally his glowing core, and it is the thing the cosmos is losing. In
  mechanics it is **Spark** — the XP/charge the player vacuums up. Collecting
  Spark isn't "leveling up an RPG character," it's *rescuing fragments of
  humanity* before the cold takes them.
- **The dehumanized technology.** The antagonist. Not evil masterminds —
  machinery that has forgotten the people it was built for: hollow, repeating,
  counterfeit. The enemy "shapes" are this tech, encroaching. (This reconciles
  the older "counterfeit authority" enemy framing: counterfeit *humanity*.)

## 3. The world — a gouache cosmos of lost tech

A painted, storybook cosmos (matte gouache / low-fi 1990s-cartoon look, per
`FUSION-CODEX.md` and `IMAGE-MODEL-BACKLOG.md`) strewn with **lost tech** —
dead gadgets, drifting devices, sealed machines. This is the same place the
design system calls **"The Hush"**: the quiet after humanity's warmth drained
out. Gizmo moves through the Hush relighting it, one rescued spark at a time.

- **Lost tech** is recoverable. Sealed devices = **Caches** (the design system's
  "reliquaries"). Cracking one releases preserved spark and, sometimes, an
  evolution — a fragment of human ingenuity Gizmo can fold into himself.

## 4. System → fiction mapping

The mechanics already exist in `game-src-phaser/src/game/simulation.ts`; the
premise gives each one a reason. Keep this table true to the code.

| System (code) | Fiction | Note |
|---|---|---|
| **Spark** (`xp` pickups, `xp`/`nextXp`) | fragments of the human spark, rescued | the core economy; the thing being preserved |
| **Level up → upgrade card** | Gizmo re-humanizing himself with what he saved | rarity `common→epic` = how rare the recovered human trait is |
| **Cache** (`pickup: cache`, `cacheEvolutions`) | sealed **lost tech / reliquary**; cracking it frees spark + evolutions | the "dopamine" reward gate (Balance §8.1) |
| **Heart** (`pickup: heart`) | a surviving ember of warmth | recovery, capped (Balance §3.3) |
| **Enemy shapes** (`nibbler/dasher/brute/warden`) | the dehumanized technology, in escalating forms | TTK bands (Balance §5.4) |
| **The four covenants / economies** | the facets of the spark Gizmo keeps lit | see below |
| **Bounty** | a call to rescue a threatened pocket of the cosmos | risk/streak chase |
| **Boost / Snap Boost** | Gizmo's hand-timed scoop — human skill, not automation | timing window = the human touch |
| **"Storm Cleared" (run complete)** | the Hush pushed back for one vigil | bounded ~240s run |

### The four economies, as facets of the spark

| Economy | Color | Fiction |
|---|---|---|
| **Flow** | mint `#5BE6A4` | momentum — humanity moving, not frozen |
| **Clutch** | cyan `#54D8FF` | the near-miss; grace under threat |
| **Echo** | violet `#A98BFF` | memory — the spark remembering itself |
| **Surge** | gold `#FFD24A` | the payoff bloom; reward = gold, always |

## 5. The codex sub-motif (retained, demoted)

The earlier design canon framed everything as an **illuminated manuscript** that
a neon spark re-lights ("The Lumen Codex," "wake the page," covenant sigils).
That craft is *not* discarded — it is reframed:

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
- **Does not change:** any token, color, economy name, mechanic, or existing
  asset. No rewrite of the Phaser seed, the design handoff package, or the
  design system. This is a fiction layer over a frozen system.

## 7. Voice

Plucky, warm, distilled, a little ceremonial. Gizmo is earnest; the cosmos is
sad-but-savable; victory is quiet light, not explosions. Keep the design
system's microcopy rules (`DESIGN.md` §Content voice): sentence case, one `!`
per payoff, UPPERCASE only for short callouts, functional glyphs only.
