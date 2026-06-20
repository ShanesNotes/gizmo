# 0010 — Pressure director: the clock is the boss

**Date:** 2026-06-20
**Lesson:** `lessons/0010-pressure-director.html`
**Mode:** **model-built draft — pending learner review.** The learner directed the
design (continuous ramp, NOT waves) and will review; promote to "complete" only
once they can explain the slice.
**Status:** DRAFT (implementation verified; learner understanding pending)

## What was built (model-built)
Replaced 0008's fixed-cadence spawn with a **director-driven pressure curve**
(ADR 0003 — not discrete waves):
- `scripts/simulation.gd`: a public `heat()` — time-driven difficulty scalar, the
  time term of `heatCurve` (simulation.ts:1727-1730): `clampf(1 - (1-t)^2.15, 0, 1.42)`
  with `t = elapsed / run_duration`. A **spawn budget** director in `_update_enemies`:
  `budget_rate = BUDGET_BASE + heat()^1.52 * BUDGET_HEAT_GAIN` (faithful core of
  updateDirector, simulation.ts:666-689); `_spawn_budget += budget_rate * dt`; spend
  `NIBBLER_COST` (1.1) per spawn up to `max_enemies`, batch-capped at
  `MAX_SPAWNS_PER_TICK` (14). New consts cite the source lines. Removed
  `spawn_interval`/`_spawn_timer` (the v1 seed); added `spawn_enabled` (default true;
  unit tests set false to place enemies by hand).
- `tests/run_simulation_tests.gd`: replaced the fixed-cadence tests
  (`_test_enemy_spawns_on_cadence`, `_test_enemy_cap`) with director tests —
  `_test_heat_curve_ramps` (3), `_test_director_ramps_spawn_rate` (2),
  `_test_director_respects_cap` (1), `_test_no_spawn_when_disabled` (1). The 0008
  control tests (chase/contact/grace/separate) now use `spawn_enabled = false` +
  `_spawn_nibbler(...)`; the 0009 tests' disable idiom moved from
  `spawn_interval = 9999.0` to `spawn_enabled = false`. Net **69 total** (was 66).
- No scene change: `game_controller._sync` already renders N enemies, so a growing
  crowd appears for free.
- Lessons are historical snapshots: 0008/0009 keep their `spawn_interval`-era code;
  this 0010 lesson documents replacing it with the director + `spawn_enabled`.

## Verified (implementation)
- `godot --headless --path godot --script res://tests/run_simulation_tests.gd` →
  **PASS — 69 checks**, exit 0.
- Live (godot-runtime MCP): the project runs; a calm opening, then the crowd of red
  nibblers thickens over the run — the ramp is visible, no wave banners. Screenshot
  captured. The rate-rises-with-heat and cap-holds invariants are proven headless.

## What the slice covers (to confirm with the learner)
The heat curve ("the clock is the boss", balance §5.2) and its easing; the spend-a-
budget director (heat → budget_rate → spawns) vs a fixed timer; why this is a
continuous pressure curve, not "WAVE x/5" rounds (ADR 0003); how `spawn_enabled`
keeps unit tests deterministic.

## Deferred (named hooks, flagged in-lesson)
- **Player-power** budget terms (`pScore`, late/power pressure) — no upgrade/power
  system yet (simulation.ts:666-672).
- **Enemy intensity** scaling: HP/speed/XP rising with heat (simulation.ts:1088-1116).
- **Multiple enemy kinds** unlocking over time (dasher @30s, brute @66s, warden @98s;
  ENEMY_SPECS 258-263) and **elites/bosses** — their own lessons.
- The `+ level*0.014 + kills*0.00135` heat refinements (we don't track kills yet).
