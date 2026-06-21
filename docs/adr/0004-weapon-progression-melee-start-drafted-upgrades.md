# 0004 — Weapon progression: melee start, drafted upgrades

**Status:** accepted · 2026-06-21

## Decision
Gizmo **starts** every run with a single **rudimentary melee auto-attack** — short
reach, "fending for his life." As he levels he **drafts** upgrades that add and
evolve weapons: a **ranged Spark Chain** first, then **fireball / void / explosives**
and similar. The attack stays an **auto-attack preset** the whole time (Megabonk /
Brotato style — auto-targeted, not manually aimed); only the *kit* grows.

The ranged Spark Chain ported in 0009/0013 is **retained, not scrapped** — it simply
moves from "the starting weapon" to "the first draftable upgrade."

## Why
- **Fiction + reference fit.** The hero concept art (`design-handoff/concept art/gizmo-concept.png`)
  shows Gizmo *cradling a spark in its open palm* — a gentle channeler that grows into
  power, not a unit that begins fully armed. A bare-handed melee start that blossoms
  into spark/elemental weapons matches that arc.
- **A real opening.** With the 5 m ranged auto-fire, the opening took **zero damage**
  even standing still (enemies died at range before contact) — there was no first-level
  fight to tune. A short melee reach makes the opening an actual, winnable-but-tense
  scrap: a lone trash mob is a clean kill, but standing still gets you swarmed.
- **Progression has stakes to give.** Starting rudimentary means each drafted weapon is
  a felt power spike, which is the point of a rogue-lite draft loop.

## Consequences
- **`simulation.gd`:** the default `attack_range` is `MELEE_RANGE` (1.6 m); `ATTACK_RANGE`
  (5 m) is kept as the Spark Chain's reach once drafted. The combat seam (`_update_weapon`)
  is unchanged — swapping/adding weapons is a config change, not a rewrite.
- **Balance is split.** The **opening** (melee start) is pinned now: a single mob dies
  before it lands a hit; standing still is lethal in the opening window
  (`run_balance_tests.gd`). The **full run under melee-only** is *intentionally
  unbalanced and NOT asserted* — it can't be fair until drafts exist, because melee-only
  can't clear a late swarm. The 0013 full-run profiles still run, but explicitly pinned at
  `ATTACK_RANGE` so they keep guarding the **draftable** ranged weapon's curve.
- **The draft system is now on the critical path.** "Choose an upgrade on level-up" (the
  Core Matrix) graduates from a deferred nicety to the thing that makes the full run fair.
  Until it lands, runs are a prototype that feels right early and thins out late.
- The prototype Spark-Chain level auto-scale (0013) remains a temporary bridge until the
  real draft choices replace it.

## Related
- ADR 0002: Simulation owns the rules; the scene renders.
- ADR 0001: Sparks ≠ HP ≠ Spark of Humanity (currencies/meters stay distinct).
- `game-src-phaser/src/game/simulation.ts`: the Spark Chain canon (`title: "Spark Chain"`, ranged).
- Lesson `0015`, learning record `0015-*`.
