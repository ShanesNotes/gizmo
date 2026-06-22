# 0018 — The Beacon becomes the win (Path A arc)

**Date:** 2026-06-21
**Lesson:** `lessons/0018-the-beacon-becomes-the-win.html`
**Decision:** `docs/adr/0005-beacon-rekindle-replaces-timer-survival.md`
**Mode:** **model-built + explained (TDD red-first).** Two-part slice (major #1 from the plan): a deterministic
sim-side win wire, then a balance reachability proof.
**Status:** Verified — sim **88**, balance **43**, full gate **158** (88 · 43 · 13 · 8 · 6).

## The teaching beat — one win condition needs two proofs
"Set `phase = COMPLETE` when the channel fills" is one line, but a green unit test only proves the *mechanism*
fires when you hand-feed a perfect hold. It says nothing about whether a *player* can get there. The existing
balance proof — `_run_decent_kite_profile` — is **pure evasion** (steers AWAY from the nearest enemies every
tick), so it would never walk into a beacon and stand in it. Hence two proofs: the sim-side wire (deterministic)
and a **seek-and-hold** driver (reachability). This is major #1 the adversarial pass flagged.

## What was built (red-first, two parts)
**Part 1 — sim-side win wire (`simulation.gd`):**
- `_update_beacon`: on `beacon_channel_progress >= 1.0`, set `BEACON_REKINDLED` **and** `phase = PHASE_COMPLETE`
  (ADR 0005: Beacon Rekindled IS the win).
- **Phase guard / loss-wins-the-race:** `_update_beacon` runs after `_update_enemies` in the same tick, so a
  tick that both drains the last HP and completes the channel is a collision. Added `phase != PHASE_PLAYING` to
  the early return so a death earlier this tick (GAMEOVER) is never overwritten by a same-tick win.
- **Living test rewritten:** 0017's `_test_rekindled_beacon_does_not_win_yet` → `_test_rekindled_beacon_wins`
  (Rekindled → `PHASE_COMPLETE`). The 0017 lesson HTML stays a historical snapshot; the test runner is the one
  living file ([[lessons-are-historical-snapshots]]). Added `_test_beacon_present_death_still_loses` (heavy mob
  on the beacon centre kills before the channel fills → `GAMEOVER`).

**Part 2 — balance reachability (`run_balance_tests.gd`):**
- `_run_seek_and_hold_profile`: places a beacon at `(0,0,5)` r=3, walks Gizmo to the centre at `GIZMO_SPEED`,
  holds, with `attack_range = ATTACK_RANGE` (the draftable ranged Spark Chain). `_summary` extended with
  `beacon_state` + `beacon_progress`.
- `_test_seek_and_hold_can_rekindle`: pins `PHASE_COMPLETE`, `Rekindled`, channel full, HP ≥ 1, and that the
  finish lands on the **channel timer** (elapsed 8–20 s; measured **8.6 s**), never instant.

## Honest scope (said out loud, not faked)
The rekindle lands at **8.6 s**, when pressure is ~0 — so this proves the win is **reachable by fair play**,
NOT that it's a hard finale. The real **siege** (swarm at peak pressure IS the boss; `Rekindling` overrides
spatial exposure to peak) is **0023**. The test name and lesson both say "reachability, not climax."

## State after this lesson
The win mechanic is fully wired and proven, but **no committed scene authors a beacon**, so a *played* run still
can't win until **0019** places one (`NorthBeaconDaisZone`) + HUD indicator + end-screen "Beacon Rekindled."
HP-0 loss unchanged. Timer symbols still present (0020 retires the concepts).

## Next (named, not built)
- **0019** — controller authors the live Beacon into the sim; HUD rekindle indicator (no countdown); end-screen
  copy; debug-force rekindle. First lesson where a *played* run can win the Path A way.
- **0020** retire timer symbols; **0021** spatial pressure; **0022** walkable region; **0023** the rekindle siege.

See [[path-a-refactor-arc]] and [[v1-loop-complete-balance-pass-next]] (guardrails: sim owns the rule; no visible
countdown for the beacon win).
