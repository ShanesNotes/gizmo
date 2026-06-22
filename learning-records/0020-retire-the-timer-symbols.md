# 0020 — Retire the timer symbols (Path A arc)

**Date:** 2026-06-22
**Lesson:** `lessons/0020-retire-the-timer-symbols.html`
**Decision:** `docs/adr/0005-beacon-rekindle-replaces-timer-survival.md` ("renamed in concept to the
pressure_clock… never shown to the player as a countdown")
**Mode:** **model-built + explained**, concept-rename driven red-first (not a find-replace).
**Status:** Verified — full gate **166** (sim 89 · balance 43 · controller 16 · hud 12 · end-screen 6);
grep confirms no `run_duration`/`time_remaining`/`run_progress` survive except in "retired" comments.

## The teaching beat — rename by failing test, not find-replace
After 0016–0019 the clock no longer ends the run, but the sim still *named* it like a survival timer
(`run_duration`, `time_remaining()`, `run_progress()`) — a lie the next reader would believe. The disciplined
move is a concept-rename, and the discipline is to let a **test demand the new world first**: assert the new
concept (`pressure_clock` exists; the getters are gone via `has_method`), watch it go red, then make it true.
A blind `sed` would have renamed the var *and* happily kept the dead countdown getters alive.

## What was built
**Red-first test (`run_simulation_tests.gd`):** `_test_run_clock` → `_test_run_clock_is_retired_to_pressure_fuel`
asserts `not sim.has_method("run_progress")`, `not sim.has_method("time_remaining")`, and that
`sim.pressure_clock` drives `pressure()` into (0,1) at a quarter horizon. Red on both counts before the rename.
Other test references renamed `run_duration → pressure_clock` (timer-no-longer-wins, i-frames, pressure-curve).

**The rename (`simulation.gd`):**
- `const RUN_DURATION` → `const PRESSURE_CLOCK` (the pressure-ramp horizon).
- `var run_duration` → `var pressure_clock` (with a comment: director fuel + debug value, not a countdown).
- **Deleted** `run_progress()` and `time_remaining()` — the player-facing countdown getters (already unused on
  any player path since 0019's HUD swap).
- `pressure()` now reads `elapsed / pressure_clock`. **`elapsed` stays** — genuine fuel, kept by ADR 0005.

**Last player-path reference (`end_screen.gd`):** the "SURVIVED" stat clamped `elapsed` to `run_duration`; with
the clock no longer bounding the run that clamp is meaningless, so it now reads raw `floorf(elapsed)`. Net:
`pressure_clock` is touched by nothing the player sees — pure director internals, as ADR 0005 intends.

## Verified
Gate 166 (sim +1 vs 0019: the new run-clock test has 3 checks vs the old 2). Grep for the old symbols returns
only explanatory/"retired" comments and the `has_method` assertions that prove their absence. Scripts compile
(all five suites load their targets).

## State after this lesson
The survive-timer is fully retired in name and concept. The clock survives only as `pressure_clock` (director
fuel) + `elapsed` (debug/tuning). No player-facing countdown anywhere. The Beacon is the win; HP-0 the loss.

## Next (named, not built)
- **0021** — pressure becomes place-aware: `pressure() = temporal_ramp × spatial_exposure(pos)`; authored
  PressureZones. **Watch major #2:** `_test_pressure_curve_ramps` still asserts `pressure()==1.0` at the horizon
  with no zones, so the new `spatial_exposure_at(no-zones)` must pass through to exactly 1.0.
- **0022** walkable region; **0023** the rekindle siege (Rekindling overrides exposure to peak).

See [[path-a-refactor-arc]] and [[v1-loop-complete-balance-pass-next]] (guardrail note: the earlier "don't rename
the timer symbols" lock was for 0016–0019; 0020 is the lesson that deliberately performs that retirement per ADR
0005/0006).
