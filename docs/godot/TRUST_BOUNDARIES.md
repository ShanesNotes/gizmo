# Gizmo Godot trust boundaries

This repo has multiple helpful artifacts. They are not all equal.

See `CONTEXT.md` §4–§5 for the `godot/` ↔ `answer-key/` invariant.

## Canonical sources

1. **Learner progress:** `learning-records/`
   - This is the zone-of-proximal-development source.
   - If a file says a lesson is drafted but `learning-records/` does not show the learner reached it, treat the lesson as unverified for teaching pace.

2. **Published lesson drafts:** `lessons/`
   - These are the only lesson HTML files intended for the guide.
   - Lessons ahead of `learning-records/` are teacher drafts, not completed learner progress.

3. **Learner workspace:** `godot/`
   - The learner's bare lesson-0001 project shell (ADR-012 from-zero reset): a freshly-created `project.godot` (no main scene, no input actions) plus `.gitkeep` scaffolding dirs (`scripts/`, `scripts/economies/`, `scenes/`, `tests/`, `ui/`, `assets/`, `audio/`). No `simulation.gd`/`main.gd`/`sim_space.gd`/presenters live here yet.
   - The learner builds this up one win per lesson; trust it only as far as `learning-records/` confirms.
   - The verified runtime code is NOT here — it is set aside in `docs/godot/answer-key/` (see Reference-only sources).

4. **Mechanics source:** `game-src-phaser/src/game/simulation.ts`
   - Port mechanics from here first.
   - Godot slices must be backed by headless tests before scene polish depends on them.

5. **Look and feel references:** `design-system/`, `design-handoff/`, root playable build
   - Use existing assets and tokens.
   - Do not invent replacement art.

## Reference-only sources

- `docs/godot/answer-key/` is the **verified reference port** — the finished early 2.5D implementation, set aside for unblocking and direction checks. Do not paste it wholesale into learner-facing lessons. This is where the live runtime code lives (not `godot/`):
  - `scripts/simulation.gd` owns pure mechanics/state.
  - `scripts/main.gd` adapts input and coordinates display-only presenters; `scripts/camera_rig_3d.gd` and `scripts/hud_presenter.gd` own camera/HUD presentation.
  - `scripts/sim_space.gd` is the only coordinate seam from flat simulation to 2.5D stage.
  - `scripts/player_avatar_3d.gd` displays the simulation-owned player; it does not own rules.
- `.omx/rescue-quarantine/` stores untrusted generated artifacts and prepass drafts removed from source-visible areas.

## Current baseline (post-reset)

As of the 2026-06-15 from-zero reset (ADR-012):

- `godot/` is the bare lesson-0001 shell — it imports clean as an empty project; there is no simulation/player/presentation code in it yet.
- The verified reference port (tested simulation slice, minimal player-controlled core, orthographic 2.5D presentation layer) lives in `docs/godot/answer-key/`. Its `import` + four `run_*_tests.gd` pass locally on `4.6.2.stable.mono.official`.
- That reference is ahead of the learner's recorded progress and is consulted to check direction or unblock — never pasted wholesale. Learner progress is tracked ONLY in `learning-records/`; the reference passing is not learner progress.
