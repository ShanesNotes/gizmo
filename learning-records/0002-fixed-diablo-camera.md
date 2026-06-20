# 0002 — The fixed Diablo camera

**Date:** 2026-06-20
**Lesson:** `lessons/0002-fixed-diablo-camera.html`
**Mode:** hands-on
**Status:** complete — verified running

## What was built
The `Camera3D` in `scenes/main.tscn` was set to the locked ARPG view:
`position (0, 12, 10)`, `rotation X = −50°`, perspective projection, `fov = 50`.
The learner also tried orthographic (the stored `size = 16` is the leftover from
that experiment) and chose perspective.

## Verified
- Ran via godot-runtime MCP; screenshot showed the steep down-angle — the floor
  reads as receding ground (trapezoid) with the box seated on it, clearly the
  Diablo look versus 0001's near-horizon framing.
- Camera basis confirms a clean −50° X rotation (cos/sin 50°).

## What this establishes (for ZPD)
The learner understands: the camera angle defines the genre; angle and position
are one coupled decision (`pos = (0, d·sinθ, d·cosθ)`, `rot = −θ`); perspective
(FOV) vs orthographic (Size) as a feel choice; and the key design rule —
**fixed angle, movable position**, achieved by parenting the camera to the world
(Main), not to the character.

## Notes
- Explain-back skipped by the learner's choice; correct hands-on build stands as
  evidence. Camera follow (slide to track Gizmo, keep the angle) is deferred to
  0005, after movement.
- Measured `gizmo.glb` for 0003: ~2 m tall, origin at the feet (min_y ≈ 0), so it
  seats on the floor at `y = 0` with no scaling.
