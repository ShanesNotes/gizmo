# answer-key — verified 2.5D reference port (we don't start here)

A finished, verified reference implementation of the early Gizmo→Godot port,
**set aside so we rebuild the port together at learning pace** instead of starting
from a completed solution. This is the snapshot of the rescue/ahead-of-learner
code that previously lived in `godot/`; on 2026-06-15 it was moved here as part of
the **full from-zero reset** (see `docs/godot/DECISIONS.md` ADR-012) so that
`godot/` is once again the bare lesson-0001 project shell.

## What it is

The verified player-core slice on the **active 2.5D path** (ADR-011): a flat,
headless `Simulation` plus an orthographic 2.5D presentation.

- `scripts/simulation.gd` — flat, headless game rules (movement core, schema, safe
  `dt` clamp). Constants match the Phaser seed: `WORLD_WIDTH=2600`,
  `WORLD_HEIGHT=1700`, `RUN_DURATION=240`, `dt` clamped to `0.05`.
- `scripts/sim_space.gd` — the sole coordinate seam: sim `x/y` → Godot `x/z`,
  Godot `y` is visual height only. No renderer fields leak into the simulation.
- `scripts/player_avatar_3d.gd`, `scripts/camera_rig_3d.gd`,
  `scripts/hud_presenter.gd` — display-only presenters (ADR-009).
- `scripts/main.gd` — translates InputMap actions into a plain input dict and
  applies simulation snapshots to the presenters.
- `scenes/main.tscn` (`Node3D` + orthographic `Camera3D`), `scenes/player.tscn`.
- `tests/run_*_tests.gd` — headless suites (simulation, player scene, presentation
  3D, UI smoke). `tests/capture_*_visual_smoke.gd` require a real display.

## Verified on Godot 4.6.2

```
godot --headless --path docs/godot/answer-key --import
godot --headless --path docs/godot/answer-key --script res://tests/run_simulation_tests.gd
godot --headless --path docs/godot/answer-key --script res://tests/run_player_scene_tests.gd
godot --headless --path docs/godot/answer-key --script res://tests/run_presentation_3d_tests.gd
godot --headless --path docs/godot/answer-key --script res://tests/run_ui_smoke_tests.gd
```

## Use

Check direction, compare, or unblock — consult it freely when stuck. **Never**
paste it in wholesale as the lesson, so the understanding gets built along with the
code. The earlier 2D version of this answer-key (pre-pivot) is preserved in the
reset backup under `.scratch/from-zero-reset-backup-2026-06-15/`.
