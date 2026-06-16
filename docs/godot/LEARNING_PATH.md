# Gizmo Godot learning path

Each lesson follows: explain one concept → do one tiny thing in the Godot editor → see the win → record learner understanding in `learning-records/`.

> The Phaser/TypeScript seed is the teacher's grounding, not learner homework. Use it to choose the next accurate slice, then teach the Godot concept in small editor-first steps.

## Trust rules

- `learning-records/` is the learner-progress source of truth.
- `lessons/` contains publishable lesson drafts. A drafted file is not completed progress until `learning-records/` says the learner demonstrated it.
- `docs/godot/answer-key/` is reference-only.
- `godot/` is the bare lesson-0001 shell (ADR-012, full from-zero reset). The verified reference port lives at `docs/godot/answer-key/`; rebuild it into `godot/` from zero, one win per lesson, consulting the answer-key only to check direction — never pasting it wholesale.
- Mechanics belong in `godot/scripts/simulation.gd`; scene scripts adapt input/rendering and must not duplicate game rules.

## Phase 1 — Create the project in the Godot editor
- Learning objective: open Godot, create a new project, and land in the editor.
- Godot target: `godot/project.godot` exists because Godot created it.
- Verification: `${GODOT_BIN:-godot} --headless --path godot --import`.

## Phase 2 — First 2.5D stage and first Play
- Learning objective: a game is a tree of nodes saved as a scene; Gizmo uses a flat-rules 2.5D stage from the start.
- Godot target: `godot/scenes/main.tscn` with `Main` as `Node3D`, a tiny ground/marker, orthographic `Camera3D`, and a screen-space HUD label.
- Verification: main scene is selected and F5 opens a game window.

## Phase 3 — First GDScript behavior
- Learning objective: a script is behavior attached to a node; `_ready()` runs once and `_process(delta)` runs every frame.
- Godot target: a small script attached in the editor.
- Verification: Godot check-only passes and the editor Output panel shows the expected print/motion.

## Phase 4 — Headless simulation state
- Learning objective: represent game state as data before visuals get complicated.
- Source anchor: `game-src-phaser/src/game/simulation.ts` `createGameState()`.
- Godot target: `godot/scripts/simulation.gd`.
- Verification: `godot --headless --path godot --script res://tests/run_simulation_tests.gd`.

## Phase 5 — The simulation tick
- Learning objective: `update_state(state, input, dt)` changes data over time with a safe `dt` clamp.
- Source anchor: `simulation.ts` `updateGameState()`.
- Godot target: `Simulation.update_state()` and tests.
- Verification: elapsed/timer/phase assertions pass headlessly.

## Phase 6 — Player-controlled core
- Learning objective: input is translated by `Main`; the pure simulation owns position; `SimSpace` maps flat x/y into the stage; `PlayerAvatar3D` displays the snapshot.
- Source anchor: `simulation.ts` player movement around `updatePlayer`.
- Godot target: `project.godot` input actions, `scripts/main.gd`, `scripts/sim_space.gd`, `scripts/player_avatar_3d.gd`, `scenes/player.tscn`.
- Verification: `godot --headless --path godot --script res://tests/run_player_scene_tests.gd`.

## Later phases
- Pickups/XP/level-up: add one rule and one headless test at a time.
- Economies: Flow, Clutch, Echo, Surge, Cache, Bounty, Boost; one economy per lesson cluster.
- HUD/theme/assets: use `design-system/` and `design-handoff/` only after mechanics are test-backed.
- Juice/audio/playtest: compare against the root playable web build after the core loop exists.

## Naming guidance

Use snake_case files/folders and PascalCase node names/`class_name` identifiers.
