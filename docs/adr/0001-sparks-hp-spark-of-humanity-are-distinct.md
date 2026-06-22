# 0001 — Sparks, HP, and the Spark of Humanity are three distinct things

**Status:** accepted · 2026-06-20

## Decision
The player has **three separate quantities**. Never collapse them in code, lessons,
or HUD copy:

1. **HP (health)** — `hp` / `maxHp` in `game-src-phaser/src/game/simulation.ts`.
   The cyan/teal health bar in the HUD (mockup reads e.g. 126 / 150). Taking
   damage lowers it; reaching 0 is a death/lose state.
2. **Sparks** — the `xp` currency in the code (`xp` / `nextXp`, `xp` pickups).
   The primary collected currency; banking it drives **leveling = re-humanizing**
   (the upgrade draft). **Scrap** is the secondary currency. Shown as the
   Sparks/Scrap counters in the HUD.
3. **Spark of Humanity meter** — a **separate objective / survival meter**, shown
   bottom-right in the HUD ("Keep it safe. Keep it alive."), tied to objectives such
   as guarding the Spark through the run. (The concrete beacon objective is now the
   rekindle channel of ADR 0005; the meter's fuel and mechanics remain TBD.)

## Why
The design artifacts treat these as distinct:
- `design-handoff/ART_DIRECTION.md` (HUD anatomy) lists the **HP bar**, the
  **Sparks & Scrap counters**, and the **Spark of Humanity meter** as separate
  HUD elements.
- `design-handoff/NARRATIVE.md` §2/§4 frames the Spark of Humanity as the thing
  Gizmo *guards and keeps alive*, while **Sparks** are the rescued fragments he
  *collects* — explicitly "not leveling up an RPG character."

A lesson 0006 draft wrongly equated the Spark of Humanity meter with HP. This ADR
exists to stop that conflation from cascading into later lessons and code.

## What this rules out
- Implementing or describing the **Spark of Humanity** as the player's HP.
- Using the phrase "Spark of Humanity" to mean health anywhere in lessons/code.
- Treating **Sparks** (currency) as health or as the Spark of Humanity meter.

If v1 ever intentionally fuses HP and the Spark of Humanity for simplicity, that
requires a **new ADR** superseding this one — it must be a deliberate decision,
not lesson copy.

## Consequences for the roadmap
- 0006 ports **Sparks & leveling** only (done).
- 0007 may port the **run timer** and **HP** (damage / death / lose-on-death)
  from `simulation.ts`, but **not** the Spark of Humanity meter, whose mechanics
  remain TBD until a dedicated design pass.
