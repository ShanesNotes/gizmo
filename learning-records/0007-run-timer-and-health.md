# 0007 — The run timer & health

**Date:** 2026-06-20
**Lesson:** `lessons/0007-run-timer-and-health.html`
**Mode:** model-built-and-explained, then learner-reviewed (review fixes applied)
**Status:** complete — verified green (32 checks)

## What was built
Grew `scripts/simulation.gd` (headless `RefCounted`) with the run lifecycle,
ported faithfully from `simulation.ts`:
- `tick(dt)` — run clock; no-op unless `playing`; `dt` clamped to `[0, 0.05]`
  (anti-hitch **and** anti-rewind); `elapsed >= run_duration` → `complete` (win).
  (sim.ts:459-494, safeDt 463, complete 489-493)
- `run_progress()` / `time_remaining()` — sim.ts:533 / 535.
- `take_damage(amount)` — rejects `amount <= 0` first (no free i-frames), else
  HP−=dmg (floor 0), 1.58s i-frames, `hp<=0` → `gameover` (lose). sim.ts:722-738.
- `hp_progress()` — HP-bar fill for the HUD.
- Phase machine: `playing → complete | gameover`.
- Test suite grew to **32 checks** (run clock, dt clamp both ends, win, damage,
  i-frames, zero/negative-damage guard, death, hp_progress).

## Verified
- Reproducible: `godot --headless --path godot --script
  res://tests/run_simulation_tests.gd` → `PASS — 32 checks`, exit 0.
- Real skeleton RED (19 passed / 13 failed) → full GREEN (32).
- Two adversarial workflows: source-fidelity + ADR-0001 + coverage (round 1);
  balance-§ citation accuracy + full review-fix list (round 2) — both pass, zero
  problems.

## What this establishes (for ZPD)
A win/lose run lifecycle as a tiny phase machine; faithful porting that also
maps each mechanic to the **design intent** (balance §3 defense, §5.2/§12.1
scaling axis, §13.1 run length), not just the code; and boundary-guarding public
methods (reject bad damage/dt) with tests. The logic layer can now host enemies.

## Notes & decisions
- ADR 0001 honored throughout: **HP** (health bar) is distinct from **Sparks**
  (currency) and the **Spark of Humanity** meter (objective, deferred).
- `RUN_DURATION = 240` is the Phaser/v1 seed, **not** the genre target (balance
  §13.1: horde runs 20–30 min); real length tuned later with spawn/XP/waves.
- Deferred (flagged in-lesson): enemy-contact geometry, the 7s opening grace,
  knockback, and the `secondWind` one-time save (sim.ts:732-736); i-frames will
  need visible/audible feedback later.
- Two review-caught fidelity slips fixed: a `462→463` off-by-one (round 1) and a
  `take_damage(0)`-grants-i-frames exploit (round 2).
- Next (0008): **enemies spawn** and move toward Gizmo — the first caller of
  `take_damage`.
