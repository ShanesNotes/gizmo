# Gizmo → Godot lesson roadmap

This is a planning map, not learner progress. `learning-records/` decides the next lesson.

## Status legend

- **Demonstrated:** learner has shown understanding in this workspace.
- **Draft:** lesson HTML exists, but the learner has not reached it yet.
- **Verified code ahead:** rescue code passes tests, but must be taught back before it becomes learner-owned.

## Current status

| Lesson | Status | Note |
|---|---|---|
| 0001 — Create the project | Demonstrated | See `learning-records/0002-first-project-created.md`. |
| 0002 — First 2.5D stage + Play | Draft | Next learner-facing step per current ZPD. |
| 0003 — First GDScript | Draft | Keep editor-first and small. |
| 0004 — First game state | Draft | Teach the subset before the full rescue schema. |
| 0005 — First headless test | Draft | Verification concept. |
| 0006 — The tick | Draft | `update_state` and safe dt. |
| 0007 — State on screen | Draft | Connect `Main` to `Simulation`. |
| 0008 — The player moves | Draft — **split required** | Post-ADR-012 reset: build from the shell, split into 5 micro-lessons (InputMap → Simulation movement → SimSpace → PlayerAvatar3D → Main wiring). Reference: answer-key. |

## Near-term teaching sequence

1. Resume at the learner's current ZPD: first scene + Play.
2. Teach first GDScript with a visible editor win.
3. Introduce headless simulation state and tests.
4. Teach the rescued player-controlled core as a sequence:
   - input actions in Project Settings,
   - `Simulation.update_state()` owns movement,
   - `SimSpace` maps flat simulation x/y to stage x/z,
   - `PlayerAvatar3D.apply_snapshot()` displays state,
   - `Main._physics_process()` adapts input and applies state.

## Planned beyond the player core (0009–0012)

Mapped in `docs/godot/DESIGN_TO_LESSON_HANDOFF.md` (asset/integration table), pending until the player core is rebuilt and understood:

- **0009 — Pickups & XP** — Spark pickup; one rule + one headless test.
- **0010 — Level-up choice (sim)** — logic only, no art yet.
- **0011 — Level-up choice UI** — Theme + `Panel`/`UpgradeCard` family.
- **0012 — Emblem title screen** — the Illuminated-G emblem + optional KA-1 key art.

## Guardrails

- Do not front-load full systems into the learner path.
- Do not treat `docs/godot/answer-key/` or `.omx/rescue-quarantine/` as lesson source.
- Keep future pickups, level-up UI, economies, and HUD/theme as pending until the player core is understood and tested.
