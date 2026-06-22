# 0017 — The rekindle channel, in isolation (Path A arc)

**Date:** 2026-06-21
**Lesson:** `lessons/0017-the-rekindle-channel.html`
**Decision:** `docs/adr/0005-beacon-rekindle-replaces-timer-survival.md` (+ the 0017 grill, recorded in
[[path-a-refactor-arc]])
**Mode:** **grill → model-built + explained (TDD red-first).** A `/grill-me` session first settled the
leave-radius design; then Claude wrote the six isolation tests red-first, implemented, and walked the diff.
**Status:** Verified — sim **PASS 86** (+15); full gate **151** (86 · 38 · 13 · 8 · 6); balance unchanged at 38.

## The design we grilled first (the teaching beat)
The novel risk in Path A is the **area-hold**, not the win assignment. Before code, the grill settled the one
behaviour that defines it — what happens when Gizmo **leaves** the radius mid-channel:
- **PAUSE for 0017; DECAY is the agreed real target, deferred.** Decay ("cold world pushes back") is more
  interesting, but it's a *number rule on top of* a working pause — not a different machine.
- **Leaving touches ONLY the number; `Rekindling` is a one-way door** (never reverts to `Dormant`). This is the
  load-bearing choice: it makes decay-later a free upgrade (`progress -= rate*dt` while outside), with the proven
  state machine unchanged.
- **Linear fill; `BEACON_CHANNEL_SECONDS = 8.0` placeholder** (retuned vs the real siege in 0018/0023).

## What was built (TDD red-first, all inside `Simulation` — ADR 0002)
- **State + constants:** `BEACON_DORMANT/REKINDLING/REKINDLED`, `BEACON_CHANNEL_SECONDS`; fields
  `beacon_state`, `beacon_channel_progress` (0..1), `beacon_position`, `beacon_radius`.
- **`_update_beacon(dt, pos)`** called from `tick()` after enemies/weapon/pickups. Two early returns encode the
  two design decisions: (1) `beacon_radius <= 0` ⇒ **inert** (and `Rekindled` is terminal); (2) outside the
  radius ⇒ **PAUSE** (hold the bank, keep `Rekindling`). Inside: open the one-way door, fill linearly, set
  `Rekindled` at ≥ 1.0. **The win is NOT wired here** — `phase` is never touched (that's 0018).
- **Six isolation tests** (hand-ticked positions; "inside" = origin, "outside" = far): inert-by-default,
  entry-never-instant (`0 < progress < 1` after one tick), fills-to-Rekindled, pauses-and-one-way (bank held
  ±0.0001, state unchanged), resumes-after-returning, and **no-win-yet** (`Rekindled` but `phase == PLAYING`).

## Why the gate math matters
- Sim 71 → **86** (+15 beacon checks). **Balance stayed at 38** — `beacon_radius` defaults to `0.0`, so the
  open-floor harness (no beacon) skips the channel entirely, same discipline as empty `obstacles`. A new system
  that silently moved the balance numbers would be a smell; this provably doesn't.
- The **no-win-yet** test pins the thing we deliberately *didn't* do, so a future edit can't wire the win early
  unnoticed — the un-winnable invariant from 0016 is still guarded.

## State after this lesson
The Beacon machine exists and is proven, but the run is **still intentionally un-winnable**: `Rekindled` is a
beacon-state only; nothing sets `PHASE_COMPLETE`. No beacon is authored in any committed scene yet (the
controller places it in 0019). Timer symbols still present (0020 retires the concepts).

## Next (named, not built)
- **0018** — `Rekindled → phase = PHASE_COMPLETE` (HP-0 still loses). **Re-pin the balance driver:** the current
  `_run_decent_kite_profile` is pure *evasion* (steers away) and cannot dwell in a radius, so 0018 authors a
  **seek-and-hold** profile to prove a fair run can rekindle (this is major #1 from [[path-a-refactor-arc]]).
- Decay layers on in 0018/0023 as the one-line rule swap set up here.

See [[path-a-refactor-arc]] (the 8-lesson plan + 0017 knob resolution) and
[[v1-loop-complete-balance-pass-next]] (guardrails: machine lives inside `Simulation`; no visible countdown).
