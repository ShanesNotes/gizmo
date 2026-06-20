# godot/ — live co-development project

This is the Godot project we build together, one small lesson at a time via `/teach`.

## Current state

A near-bare shell — the 3D direction starts here. What exists:

- `assets/gizmo.glb` — the 3D character (static mesh: no rig, no animation yet).
- `project.godot`, `icon.svg`, and the standard folders (`scenes/`, `scripts/`,
  `tests/`, `ui/`, `audio/`, `assets/`).

What we build first (v1, see `../CONTEXT.md`): a fixed Diablo-style `Camera3D` over
Gizmo; the `.glb` slid around with code; enemies, fighting, death, win/lose. The
mechanics port from `../game-src-phaser/src/game/simulation.ts` into
`scripts/simulation.gd`, headless-tested under `tests/`.

## Boundaries

- Scenes live in `scenes/`; reusable behavior scripts in `scripts/` (`res://scripts/...`).
- UI/theme work under `ui/` is secondary to tested mechanics.
- Godot caches under `.godot/` are generated and ignored.
