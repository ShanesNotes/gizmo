# 0006 — Sparks & leveling, test-first

**Date:** 2026-06-20
**Lesson:** `lessons/0006-headless-logic-test-first.html`
**Mode:** model-built-and-explained (learner chose to have the model implement
this slice; a full line-by-line walkthrough was given so it isn't a black box)
**Status:** complete — verified green

## What was built
The first slice of game logic, ported test-first from
`game-src-phaser/src/game/simulation.ts`:
- `scripts/simulation.gd` — a headless `RefCounted` `Simulation` with:
  - `next_xp_for_level(lvl)` (static) — the polynomial Sparks curve, faithful to
    `nextXpForLevel` (simulation.ts:1721-1725).
  - `add_xp(amount)` — banks Sparks, levels up carrying the remainder
    (simulation.ts:1029-1038), guards negative input (`maxi`).
  - `xp_progress()` — Sparks-bar fill 0..1 (simulation.ts:534).
- `tests/run_simulation_tests.gd` — a dependency-free `SceneTree` runner
  (`preload`s the module so `--script` works without an editor import), `_check`
  + `_check_eq` (prints got/expected), 14 checks, exit 0/1.

## Verified
- Ran the documented command headless: **PASS — 14 checks, exit 0**.
- Walked the real red→green during authoring: skeleton stubs → 10 failing checks
  → full impl → all green.
- Exact curve vectors pinned and confirmed: level 1/2/3/5/10 = 92/188/291/595/1811.
- Reproducible check (anyone can run): `godot --headless --path godot --script
  res://tests/run_simulation_tests.gd` → `PASS — 14 checks`, exit 0. The vectors
  were independently re-derived from the formula in simulation.ts:1721-1725.

## What this establishes (for ZPD)
The project now has: a headless logic module pattern (`RefCounted`, pure, no
scene), a working dependency-free test runner + the red→green TDD loop, and the
faithful-port discipline (copy from simulation.ts; design intent = Balance §5;
fiction = NARRATIVE §4). Foundation for porting the rest of the loop.

## Notes
- Fiction: code `xp` = **Sparks** (NARRATIVE §4), the collected currency. Three
  distinct things, never conflated (ADR 0001): **Sparks** (currency) · **HP**
  (health) · the **Spark of Humanity** meter (a separate objective/survival meter,
  mechanics TBD). 0006 ports only Sparks/leveling.
- This slice was model-built per the learner's request; understanding is to be
  reinforced as 0007 extends `simulation.gd` (the learner should be able to add
  the next test/method themselves).
- `next_xp_for_level` is `static`; the runner uses `preload` (not the class_name)
  for import-independent headless runs.
