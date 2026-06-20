# 0004 — Move Gizmo with code

**Date:** 2026-06-20
**Lesson:** `lessons/0004-move-gizmo-with-code.html`
**Mode:** hands-on (with model help: input map pre-built, Phase C unblocked)
**Status:** complete — verified moving

## What was built
Gizmo became a controllable character:
- `scenes/gizmo.tscn` — a `CharacterBody3D` (`Gizmo`) wrapping the model
  (`Model`, the `gizmo.glb` instance) and a `CollisionShape3D` (capsule, r=0.4,
  centered at y=1). Its own reusable scene.
- `scripts/gizmo.gd` — `_physics_process` reads `Input.get_vector` and drives
  world-relative `velocity` on X/Z with `move_toward` accel/friction, then
  `move_and_slide()`. Uses `&"…"` StringName literals in the per-frame call.
- `main.tscn` instances `gizmo.tscn` as `Gizmo` (replacing the raw .glb).
- Input Map: `move_left/right/up/down` bound to keyboard (WASD + arrows) **and**
  Xbox controller (left-stick axes + D-pad), device −1, deadzone 0.2.

## Verified
- Headless validation of `gizmo.gd`, `gizmo.tscn`, `main.tscn`: all pass.
- Live runtime: simulated holding `move_right` ~0.7s → Gizmo moved from origin to
  `x ≈ 4.0`, `y` stayed `0` (grounded), and `velocity` returned to `0` after
  release (friction braked him). World-relative mapping confirmed (right = +X).

## What this establishes (for ZPD)
The learner can: build a character as its own scene (body + collision + visual),
define rebindable Input Map actions (keyboard + gamepad), write a
`_physics_process` movement loop, attach a script, and instance the character
into the level. Understands why movement is world-relative under a fixed camera
(no `transform.basis`), and the body/visual split.

## Notes & gotchas captured
- Two-scene confusion (main vs gizmo) and an "invalid path" wall on Attach Script
  (Godot won't create a missing `scripts/` folder) — both surfaced and fixed; the
  lesson now creates the folder first and states the script lives on `gizmo.tscn`.
- The godot-runtime MCP injects an `[autoload] McpBridge` into `project.godot` at
  run time; it must be stripped before committing (a clean checkout has no
  `mcp_bridge.gd`). `mcp_bridge.gd` is gitignored.
- Next (0005): turn Gizmo to face travel direction; camera follows his position
  while keeping the fixed angle.
