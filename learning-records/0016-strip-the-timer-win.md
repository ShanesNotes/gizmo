# 0016 — Strip the timer-win (Path A arc, Phase 0)

**Date:** 2026-06-21
**Lesson:** `lessons/0016-strip-the-timer-win.html`
**Decision:** `docs/adr/0005-beacon-rekindle-replaces-timer-survival.md`
**Mode:** **model-built + explained** (learner chose "I build + explain"). Claude made all three edits,
ran the gate red→green at each step, and walked through the why.
**Status:** Verified — full committed gate **136 green** (sim 71 · balance 38 · controller 13 · hud 8 · end-screen 6).

## The teaching beat — red-first *deletion*, and finding all the pins
This is the opening move of the Path A arc (0016→0023): survive-the-timer → traverse-and-rekindle-a-Beacon.
The disciplined first step is to **delete the old win before building the new one** — ADR 0005's "code gravity
pulls back toward the arena unless the win condition itself moves." TDD usually adds a feature red-first; here
red-first guards a **removal**.

Key idea: a win condition is a **rule + every test that pins it**. We located all three before touching anything:
- **RULE** `simulation.gd:204` — `if elapsed >= run_duration: phase = PHASE_COMPLETE`
- **PIN A** `run_simulation_tests.gd` `_test_run_completes`
- **PIN B** `run_balance_tests.gd:303` `_test_decent_kite_can_complete_the_run`

Deleting the rule turned the gate into a tripwire: **exactly** those two pins went red (sim 69/2, balance 37/1),
nothing else — proof the deletion was complete and load-bearing. An *unexpected* red would have meant a hidden
dependency on the timer-win.

## What was built (3 edits, surgical)
- **`simulation.gd`:** deleted lines 204–205 (the two-line win); corrected the now-lying `tick()` docstring to
  "the clock no longer ends the run — `elapsed` is now only pressure fuel; the win returns as the Beacon channel
  (0018)." Symbols `elapsed`/`run_duration`/`pressure()`/`time_remaining()` **kept** (0020 retires the *concepts*).
- **PIN A → `_test_timer_no_longer_wins`:** crossing `run_duration` now asserts `PHASE_PLAYING`. Its old
  "tick is a no-op once the run is over" tail was meaningless (the run never ends now) — **rewritten, not flipped**.
- **PIN B → `_test_decent_kite_survives_the_clock`:** no win (no Beacon yet), but a competent kite must still
  **survive the full clock**. With the win gone the profile runs to the 6000-tick / **300 s** cap instead of
  stopping at the 240 s win — 60 s longer under peak pressure.

## The honesty catch (the real lesson)
The Pin B rewrite first **silently dropped** the old "takes some but not lethal damage (2–6 events)" fairness band
— a genuine regression guard. Rather than guess whether it still held over the longer run, **measured** with a
throwaway probe: `damage_events = 4`, `hp = 3`, `elapsed = 300`. The 2–6 band still holds at 300 s, so it was
**restored at full strength** (balance back to 38), not loosened to fit the refactor. Don't let a refactor quietly
erode a guard — measure and re-pin to reality. [[design-canon-fidelity]] in spirit: don't fake green.

## Verified
- `run_simulation_tests.gd` 71 · `run_balance_tests.gd` 38 · controller 13 · hud 8 · end-screen 6 = **136**.
- Controller/HUD win-path tests still pass because they force `PHASE_COMPLETE` directly (debug F9 path), not via
  the clock — so only the two timer pins were affected, as predicted.

## State after this lesson
The run is **intentionally un-winnable**: HP-0 loss still works; there is no Beacon yet. HUD still shows its
countdown (demoted in 0019). The `elapsed`/`run_duration` symbols persist as pressure fuel until 0020.

## Next (named, not built)
- **0017** — rekindle channel proven headless in pure RefCounted isolation (`Dormant → Rekindling → Rekindled`;
  hold fills, leaving pauses, entry never instant). Still un-winnable. **Open knob:** leave-radius behaviour =
  PAUSE (simplest first green) vs slow-decay (on-theme) — recommend PAUSE, defer decay.
- **0018** — channel-complete *becomes* the win; the balance driver re-pins its own seek-and-hold (the current
  decent-kite profile is pure evasion and cannot dwell in a radius).

See [[path-a-refactor-arc]] (the 8-lesson plan + the 3 majors to fold in) and
[[v1-loop-complete-balance-pass-next]] (refactor guardrails: keep the timer symbols, zones, `_update_weapon`
seam, HP/leveling, the ADR-0002 tick/last_events seam; no visible countdown for the beacon win).
