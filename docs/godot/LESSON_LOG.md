# Gizmo Godot lesson log

This log is trust-scoped.

- **Learner progress source:** `learning-records/`.
- **Published lesson files:** `lessons/`.
- **Non-counting rescue/reference entries:** allowed here, but they do not advance the learner's lesson number.

## Learner-demonstrated checkpoints

### 2026-06-14 — Lesson 0001: create the Godot project in the editor
- Concept: a Godot project is created from the editor; Godot owns `project.godot`.
- Verified artifact: `godot/project.godot` existed and imported cleanly.
- Snag captured: the New Project dialog can accidentally create `godot/gizmo/`; the guide now warns against nesting.
- Current learner ZPD after this checkpoint: project exists, but the learner has not yet demonstrated a scene, main scene, Play, or scripts in this workspace.
- Source record: `learning-records/0002-first-project-created.md`.

## Non-counting rescue/reference checkpoints

These entries describe the repository state after AI rescue work. They are not learner-completed lessons.

### 2026-06-15 — Trust rescue baseline
- Cleaned generated/local drift: `.scratch/`, `.claude/`, untracked hashed web bundle, duplicate generated hero SVGs, Godot caches, Phaser `dist/`, and generated KA image outputs were quarantined or ignored.
- Reverted unrelated Phaser/design/root build drift so the web seed remains a reference, not part of the Godot rescue diff.
- Added explicit trust boundaries in `docs/godot/TRUST_BOUNDARIES.md`.

### 2026-06-15 — Godot mechanics first slice verified
- Live `godot/scripts/simulation.gd` now has the tested opening schema from the Phaser source/answer-key direction: player velocity/facing/HP/cooldowns, upgrades/evolved, timers, director, economy counters, message fields, and completion event.
- `godot/tests/run_simulation_tests.gd` covers schema, initial values, safe `dt`, negative `dt`, phase guard, completion, and player movement math.
- Verification: Godot import, check-only, and simulation tests passed.

### 2026-06-15 — Minimal player-controlled core verified
- Live Godot now has input actions, `Main` running `_physics_process`, simulation-owned player movement, `SimSpace` as the flat-to-stage seam, `PlayerAvatar3D` as a thin display-only visual adapter, orthographic `Camera3D`, quiet 3D ground, and HUD label.
- `godot/tests/run_player_scene_tests.gd` and `godot/tests/run_presentation_3d_tests.gd` verify InputMap actions, `player.tscn`, `main.tscn`, SimSpace mapping, the orthographic camera, and the input adapter moving the simulation player.
- Teaching note: this is verified code, not verified learner understanding. Teach it back through small editor-first lessons before building on it.


### 2026-06-15 — Orthographic 2.5D presentation pivot verified
- Live `godot/scenes/main.tscn` now uses `Node3D`, quiet 3D ground, `CameraRig/Camera3D` in orthographic mode, `PlayerAvatar3D`, and the existing `CanvasLayer` HUD.
- `godot/scripts/simulation.gd` remains flat/headless; `godot/scripts/sim_space.gd` owns the x/y → x/z mapping.
- Teaching note: lesson drafts 0002, 0007, and 0008 now present this as “flat rules, 2.5D stage” instead of a 2D-scene detour.

### 2026-06-15 — Full from-zero reset (ADR-012)
- After the learning-process audit (`docs/godot/LEARNING_AUDIT.md`, overall RED with two red dimensions: contract adherence + forward path), all ahead-of-learner code described in the three entries above was **moved out of `godot/` into the answer-key**, and `godot/` was reset to the bare lesson-0001 shell (`project.godot` stripped of main scene + input actions; only `.gitkeep` scaffolding remains). Verified: `godot --headless --path godot --import` is clean (exit 0).
- The answer-key was **re-pivoted** from its stale 2D shell to the verified 2.5D snapshot; `import` + all four `run_*_tests.gd` pass at `docs/godot/answer-key/`.
- Effect on learner progress: **unchanged** — the learner has still demonstrated only Lesson 0001. Lessons 0002–0008 remain drafts to rebuild from zero during co-development; 0008 must split into five micro-lessons. The three rescue/reference entries above are retained as history but now describe the answer-key, not `godot/`.
- Backup of the complete pre-reset state: `.scratch/from-zero-reset-backup-2026-06-15/`.
