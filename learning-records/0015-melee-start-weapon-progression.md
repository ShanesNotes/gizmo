# 0015 — The melee start (weapon progression pivot)

**Date:** 2026-06-21
**Lesson:** `lessons/0015-melee-start-weapon-progression.html`
**Decision:** `docs/adr/0004-weapon-progression-melee-start-drafted-upgrades.md`
**Mode:** **design conversation → model-built (probe-grounded TDD).** The learner proposed a melee
first attack + "tune first-level difficulty"; Claude grounded it in the concept art + a probe, reframed
the task, the learner approved ("yes please"), Claude implemented + pinned it.
**Status:** Verified — probe-grounded; balance harness PASS 38; full suite green.

## The reframe (the teaching beat)
The ask was "tune the ranged opening so Gizmo kills the single trash mob before too much damage." A probe
showed there was **nothing to tune**: with the 5 m ranged auto-fire, a stationary Gizmo took **zero damage
in 30 s** — enemies died at range before contact. The opening difficulty the learner pictured only *exists*
once Gizmo's reach is short. So **the melee start and the first-level tuning are the same task** — and the
hero concept art (Gizmo cradling a spark, growing into power) backs a rudimentary start that drafts into
range. Lesson: don't tune a knob that isn't connected to the problem; find where the difficulty actually lives.

## What was built
A weapon-progression pivot (ADR 0004), scoped to `simulation.gd` + `run_balance_tests.gd` + the ADR/lesson/record.
- **Melee start:** new `MELEE_RANGE = 1.6`; default `attack_range` is now `MELEE_RANGE`. `ATTACK_RANGE` (5 m)
  is **kept** as the Spark Chain's reach once drafted — ranged logic retained, not scrapped. The swappable
  `_update_weapon` seam (built deliberately in 0013) made this a config change, not a rewrite.
- **Opening pinned (TDD):** new balance tests — Gizmo starts at melee reach; a lone trash mob (contact live,
  past grace) dies **with 0 HP lost** (non-tautological: a too-short reach would let it touch first); standing
  still naturally loses in the **20–45 s** opening window (movement now matters).
- **0013 guard preserved honestly:** the full-run profiles (stationary / mistake-kite / decent-kite / pressure
  probe / Spark-Chain leveling) now set `attack_range = Sim.ATTACK_RANGE` so they keep pinning the **draftable
  ranged** weapon's curve. Full-run balance under **melee-only is intentionally NOT asserted** — it can't be fair
  without drafts, and the harness header says so rather than loosening bands to pass.

## Verified
- `run_balance_tests.gd` → **PASS 38** (was 32; +6 melee checks). `run_simulation_tests.gd` 71 (combat tests use
  reach *relative* to `attack_range`, so they held), controller 10, playable-slice 766. `--check-only` clean.
- Probe numbers (throwaway, removed): single mob killed 4.9 s / 0 HP lost; stationary melee gameover ~32–40 s
  (dt-dependent); light kite survives 30 s+ on chip.

## Consequence captured
The **Core Matrix draft system** (level-up → choose ranged spark / fireball / void / explosives) graduated from
a deferred nicety to **the thing that makes a full run fair** — melee-only thins out late by design. That's the
natural next build. The prototype Spark-Chain auto-scale stays a temporary bridge until real draft choices replace it.

## Deferred (named, not built)
- The Core Matrix draft UI + upgrade pool, then a full-run rebalance with drafts in play.
- A visible melee swing animation (rig has no clips yet) — later polish, not a v1 blocker.

See [[v1-loop-complete-balance-pass-next]] (next step is now the draft system) and [[design-canon-fidelity]]
(the pivot was grounded in the concept art + simulation.ts, pinned as ADR 0004 — not invented).
