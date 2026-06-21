# 0006 — The director is place-aware: pressure zones and a walkable region

**Status:** accepted · 2026-06-21

## Decision
Enemy pressure stops being placeless. The director becomes **place-aware**, and the
sim learns the shape of the island — both *without* moving movement truth out of the
headless simulation (ADR 0002).

**1. Spatial exposure shapes pressure.**
- `pressure = temporal_ramp × spatial_exposure(gizmo_position)` (plus local modifiers
  and the beacon-siege override of ADR 0005). Exposure is **authored along the spine**,
  not raw Euclidean distance.
- Exposure is encoded as **`PressureZone` nodes** — promoted from the existing
  `LevelZones` markers in `main.tscn` — each carrying
  `zone_id / role / radius / exposure (0..1) / relief_multiplier`.
- The sim reads them via `add_pressure_zone(pos, radius, exposure, role)` and
  `spatial_exposure_at(pos)`: a **smooth distance-weighted blend** of nearby zones,
  with a plain spawn→beacon distance **fallback** when Gizmo is between zones.
- Exposure is a **modifier, not a zero-floor**: time always matters; the island only
  shapes *how cruel* time becomes. Warm hub dampens, trial/beacon amplify, sanctuary
  relieves; `Rekindling` overrides to peak.

**2. A walkable region keeps combat on the island.**
- The sim gains an authored **XZ walkable footprint** (`WalkableRegion`), exported
  beside the greybox.
- Ring-spawns validate against it: **sample candidates around Gizmo → reject points
  outside the region → reject obstacle overlaps → nearest-valid fallback** if none fit.
- After movement, enemies are **soft-clamped/projected back inside** the region.
  Obstacles remain simple push-out circles. **No scene-side `NavigationServer3D`** —
  that would split movement truth (ADR 0002). Swarm bunching around ruins/landmarks is
  accepted for Path A; smart pathfinding is not needed for a swarm.

## Why
- Today `pressure()` is purely temporal (`simulation.gd:221`) and spawns ring around
  the player on an unbounded plane (`:450`) — danger has no relationship to *where
  Gizmo is*. On a big, irregular island that spawns enemies into the painted void and
  makes location meaningless. The journey needs danger to **rise as you push out and
  fall as you retreat**.
- Canon: *"The swarm follows Gizmo, yet the island decides how cruel the swarm
  becomes,"* and *"The island owns where combat may exist; the sim still owns how the
  swarm moves."*
- A navmesh would make the scene a second source of enemy movement, contradicting
  ADR 0002; the cost buys pathfinding a swarm doesn't need.

## What this rules out
- Pressure that ignores location, or exposure that hard-zeroes spawns (the sanctuary
  calms, it never makes you invincible).
- Enemies spawning off the walkable island, or drifting over the void.
- Scene-authored navmesh as a parallel movement truth.
- True world-emitter `EnemyPressureAnchors` **for now** — anchors are authored as data
  the exposure field reads (B-ready stubs); emitter-based spawning is a deferred upgrade.

## Consequences
- **`simulation.gd`:** add pressure-zone + walkable-region structures (mirroring the
  `Obstacle` idiom at `:111`/`:392`); refactor `pressure()` to `temporal × spatial`;
  add spawn-validation in `_spawn_enemy` (`:445`) and the post-move clamp.
- **`game_controller.gd`:** register `PressureZone`s and the footprint alongside the
  existing obstacle registration.
- The **baker** emits zones + footprint + anchor stubs (ADR 0008).

## Related
- ADR 0002 (sim owns rules); ADR 0003 (director pressure); ADR 0005 (rekindle climax,
  peak override); ADR 0007 (sanctuary is a relief-role zone).
- `docs/path-a-shattered-meridian-spec.md`.
- `simulation.gd:221`/`:256`/`:392`/`:445`; `main.tscn` `ArenaTiles/LevelZones`.
