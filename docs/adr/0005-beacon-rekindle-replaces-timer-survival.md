# 0005 — The run is won by rekindling the Beacon, not by surviving a timer

**Status:** accepted · 2026-06-21

## Decision
Path A's win condition is **traverse-to-objective**, not survive-the-clock.

- **Win = Beacon Rekindled. Lose = HP 0** (loss is unchanged).
- Reaching the `ObjectiveBeaconAnchor` (co-located at the existing `NorthBeaconDaisZone`;
  emitted by the baker, ADR 0008) starts a **rekindle channel**. The Beacon is a small
  state machine: **`Dormant → Rekindling → Rekindled`**. While Gizmo is inside the beacon
  radius, `beacon_channel_progress` fills; while outside it pauses or slowly decays (a
  tuning knob — slow decay is the on-theme "cold world pushes back" default). It is an
  **area-hold**, not a stand-still button — Gizmo keeps moving and fighting inside the
  radius. When the channel completes, `phase = PHASE_COMPLETE`.
- The run clock (`run_duration` / `elapsed`) **no longer ends the run**. It is
  renamed in concept to the **`pressure_clock`** and survives only as the temporal
  fuel for the director (ADR 0003) and a debug/tuning value. It is **never shown to
  the player as a countdown**.
- While `Rekindling`, spatial exposure is **overridden to peak** — the climax siege
  (see ADR 0006). The existing swarm at peak pressure *is* the Path A boss.

## Why
- The old model — `if elapsed >= run_duration: phase = PHASE_COMPLETE`
  (`godot/scripts/simulation.gd:204`) — teaches a Vampire-Survivors *arena*: stand
  and outlast a clock. The direction is a *journey*: carry a guarded light across a
  wounded island and relight a cold hearth. A finish-line timer and a destination
  are different games, and code gravity pulls back toward the arena unless the win
  condition itself moves.
- A visible countdown is the round-counter the project already ruled out (ADR 0003;
  `CONTEXT.md` no-wave correction; world-graph `validation_priority`: "no
  player-facing round counter UI").
- Canon: *"The Beacon is not a finish line; it is a hearth that must be rekindled
  while the cold world pushes back."* The channel makes the destination an
  **encounter**, not a line you walk over.
- Symbolic (HEARTH's corruption form): the swarm reads as **hollow care-machines** —
  devices repeating care-like motions *without care*; the Beacon is care that must be
  **actively restored**, not idly maintained. This is the "why" beneath the mechanic.

## What this rules out
- A player-facing countdown/timer, or any "time survived" win/score framing
  (debug overlay only).
- Instant-win on entering the beacon radius — the siege must matter.
- Defining the rekindle's **fuel** as the Spark of Humanity, or as spent Sparks.
  The channel is mechanically neutral ("hold the light / stabilize the Beacon");
  any thematic fuel is deferred to ADR 0001's pending Spark-of-Humanity pass.

## Consequences
- **`simulation.gd`:** retire the elapsed-based win (line 204); rename
  `run_duration` → `pressure_clock` as the ramp horizon; add beacon state +
  `beacon_channel_progress`; `PHASE_COMPLETE` now fires from the channel. `pressure()`
  keeps its eased ramp but is decoupled from a win deadline (ADR 0006).
- **HUD / end-screen:** remove the countdown; add a rekindle indicator near the
  Beacon only; end-screen copy → **"Beacon Rekindled"** / **"Gizmo's light failed."**
  Timer assertions in `run_hud` / `run_end_screen` tests are stale canon and are
  rewritten deliberately.

## Related
- ADR 0003 (director pressure, not waves); ADR 0002 (sim owns rules, scene renders);
  ADR 0006 (place-aware director); ADR 0007 (guard-over-HP survival).
- `docs/path-a-shattered-meridian-spec.md`.
- `godot/scripts/simulation.gd:204` (win), `:221` (pressure); `game_controller.gd`
  win/lose path.
