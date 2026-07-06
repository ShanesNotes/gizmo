# HZ-070 — Combat feel & survivability pass (post-v1 frontier #1)

**Status:** in-progress · **Worker:** Codex · **Deps:** HZ-061 (shipped)
**Evidence:** live ceremony runs 2026-07-06 — player died at 0:14 and 0:39; enemies spawn
inside melee range of the room entry with zero telegraph.

## Defects (ranked)

1. **Spawn proximity.** `run_orchestrator.gd::_spawn_position_for` places enemies on a
   golden-angle ring of radius 4–6 around `CameraAnchor` (room center) — the same place the
   player enters. Hades never spawns inside the player's threat bubble.
2. **No spawn telegraph.** Enemies are live (chasing, damaging) on the frame they enter the
   tree. Hades telegraphs every spawn (~0.5–1s emergence) before the enemy can act or be
   meaningfully body-blocked.
3. **Survivability.** With guard_max ≈ small and chaff dmg 1 at 2.1 speed, sustained contact
   melts the player in seconds. Balance ref §5.4 bands: trash TTK ≤0.5s *to the player's
   attacks*; the player should comfortably clear early rooms and die to *mistakes*, not spawn
   geometry. Target: a cautious first run survives ≥3 rooms / ≥90s.

## Acceptance
- Min spawn distance from the player's current position (exported, default ≥ 8.0), with
  deterministic fallback when the room can't satisfy it (farthest valid ring point).
- Spawn telegraph state on the enemy (exported windup, default ~0.8s): no movement, no
  contact damage, not yet counted for kill purposes only if that keeps director bookkeeping
  simple — otherwise counted but inert. Killable during telegraph is fine (Hades allows it).
- Tuning pass on enemy damage cadence and/or guard values so the ≥3-room target holds in a
  scripted headless survivability probe (drive the real orchestrator, autopilot player
  motionless vs. moving-away, assert time-to-death bands).
- Red-first tests for 1 and 2; full battery green; --check-only clean on touched scripts.
