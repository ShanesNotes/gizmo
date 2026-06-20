# 0005 — Face movement + camera follow

**Date:** 2026-06-20
**Lesson:** `lessons/0005-face-movement-and-camera-follow.html`
**Mode:** hands-on (learner + reviewer iterated on a jitter fix)
**Status:** complete — verified moving, facing, and following

## What was built
- **Facing** (`gizmo.gd`): while moving, rotate the `Model` child to
  `atan2(direction.x, direction.z)` via `lerp_angle`, with framerate-independent
  smoothing `1 - exp(-turn_speed * delta)`. Facing is cosmetic; movement stays
  world-relative.
- **Camera follow** (`camera_rig.gd` on `Camera3D`): each render frame, ease
  `global_position` toward `target.get_global_transform_interpolated().origin +
  offset (0,12,10)`; rotation never touched. Camera opts out of physics
  interpolation in `_ready` (it's driven manually). Target = `Gizmo`.
- **project.godot**: `common/physics_interpolation=true` so the physics body
  renders smoothly between ticks.

## Verified
- Headless validation of both scripts: pass.
- Live runtime: drove NE → Gizmo reached `(3.7, 0, -3.7)`, model yaw = 135°
  (faces travel exactly), camera held the `(0,12,10)` offset (fixed angle kept).
  Screenshot showed Gizmo from behind, near screen-center.

## What this establishes (for ZPD)
The learner understands: turning a direction into a yaw (`atan2`) and smoothing
angles (`lerp_angle`); the "fixed angle, movable position" camera (set position,
never rotation); and why a render-time follow of a physics body needs the
interpolated transform plus framerate-independent smoothing. The **player** now
feels complete — the next arc is game logic, not character.

## Notes & gotchas captured
- Jitter root cause: following a physics body from `_process` with raw
  `global_position` while interpolation was off. Fix per Godot docs:
  `physics_interpolation` on, read `get_global_transform_interpolated()`, smooth
  with `1 - exp(-speed*delta)`, and set the manually-driven camera's
  `physics_interpolation_mode = OFF`.
- Reminder: the godot-runtime MCP re-injects `[autoload] McpBridge` into
  `project.godot` on every run — strip before committing.
- Next (0006): pivot to **game logic**, test-first — port the first slice of
  `game-src-phaser/src/game/simulation.ts` into `scripts/simulation.gd` with a
  headless test runner under `tests/` (TDD).
