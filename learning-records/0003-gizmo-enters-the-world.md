# 0003 — Gizmo enters the world

**Date:** 2026-06-20
**Lesson:** `lessons/0003-gizmo-enters-the-world.html`
**Mode:** hands-on
**Status:** complete — verified running

## What was built
`gizmo.glb` instanced into `scenes/main.tscn` as a child of `Main` (named
`Gizmo`), placed at `(0, 0, 0)`; the placeholder `Box` deleted (0 references
remain).

## Verified
- Ran via godot-runtime MCP; screenshot shows the brass clanker (glowing cyan
  eye — on-palette with the art direction) standing feet-on-floor under the
  Diablo camera. Floor now reads as lit ground.

## What this establishes (for ZPD)
The learner understands: an imported `.glb` is a reusable **PackedScene** (mesh +
materials + 53-bone rig), instanced into the world, not edited in place; and that
a node's **origin** decides how it seats (Gizmo's origin at his feet → y=0 stands
him on the ground, vs the box's centered origin needing y=0.5).

## Notes
- Lighting is single-directional (Sun straight down) — fine for now; proper
  scene lighting deferred. Facing direction handled in 0005.
- Next (0004): give Gizmo a CharacterBody3D body + a movement script. World-
  relative movement (no `transform.basis`) so WASD maps to screen directions
  under the fixed camera.
