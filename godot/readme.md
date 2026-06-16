# godot/ — live co-development project

This is the Godot project we build together, one small lesson at a time.

## Current rescue baseline

The code is now ahead of the learner's recorded progress, but it is verified and intentionally small:

- `scripts/simulation.gd` owns pure mechanics/state and is headless-testable.
- `scripts/main.gd` owns the scene loop and InputMap adapter; `scripts/camera_rig_3d.gd` and `scripts/hud_presenter.gd` own camera/HUD presentation.
- `scripts/sim_space.gd` maps flat simulation x/y into Godot stage x/z; it is the only coordinate seam.
- `scripts/player_avatar_3d.gd` displays the simulation-owned player snapshot; it does not own XP, movement rules, upgrades, or economies.
- `scenes/player.tscn` is the first 2.5D visual player core.
- `tests/run_simulation_tests.gd`, `tests/run_player_scene_tests.gd`, and `tests/run_presentation_3d_tests.gd` protect the core.

## Boundaries

- Scenes live in `scenes/`.
- Reusable behavior scripts live in `scripts/` and are referenced with `res://scripts/...`.
- UI/theme/component work under `ui/` is secondary to tested mechanics.
- Godot caches under `.godot/` are generated and ignored.

Reference port: `../docs/godot/answer-key/`. Use it for direction checks, not wholesale lesson copying.
