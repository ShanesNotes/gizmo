# 0012 — Win / lose: close the loop

**Date:** 2026-06-20
**Lesson:** `lessons/0012-win-lose.html`
**Mode:** **model-built draft — pending learner review.** The learner said "go on 0012"; the
slice was built model-first and walked through in the lesson. Promote to "complete" once the
learner can explain it. **Status:** DRAFT (implementation verified; learner understanding pending)

## What was built (model-built)
The win/lose screen that closes the v1 loop. The Simulation already reached `PHASE_COMPLETE`
(timer out → win, `simulation.ts:490`) and `PHASE_GAMEOVER` (HP 0 → loss, `simulation.ts:737`);
0012 renders those endings.
- `scripts/end_screen.gd` (`class_name EndScreen extends CanvasLayer`):
  - `static outcome(phase)` — pure phase→`{title, flavor, win}` mapping; "playing" returns an
    empty title (defensive: a mis-call shows nothing, not a wrong banner).
  - `show_outcome(sim: Simulation)` — fills the panel (title/flavor + SURVIVED/LEVEL/SPARKS) and
    reveals it; reuses `Hud.format_clock` for the survived time, **pre-floored** (count-up ⇒ round
    down, vs the HUD clock's count-down round-up) and clamped to `run_duration` for a clean win.
  - `_on_retry_pressed` → `get_tree().reload_current_scene()` (reload *is* the reset — fresh
    `Simulation.new()`).
- `scenes/end_screen.tscn`: `CanvasLayer` (layer 3, above the HUD's 2) → `Root` (Control, hidden in
  `_ready`) → `Dim` (ColorRect) + `Center`→`Panel` (reuses `hud_theme.tres`) → title, flavor,
  `Stats` GridContainer, brass `RetryButton`. Touched widgets use unique names.
- `scripts/game_controller.gd`: `@export var hud`, `@export var end_screen`, default UI auto-instancing
  when those slots are empty, a `_prev_phase` edge check that fires `show_outcome` once, and debug-build
  F8/F9 playtest shortcuts for forcing loss/win without waiting for balance.
- `tests/run_end_screen_tests.gd`: dedicated runner for `outcome()` (6 checks).
- `tests/run_game_controller_tests.gd`: integration runner for default UI instancing and forced win/loss
  playtest paths (10 checks).

## Verified (implementation)
- `run_end_screen_tests.gd` → **PASS — 6 checks**; `run_game_controller_tests.gd` → **PASS — 10 checks**;
  `run_hud_tests.gd` still **PASS — 8** (the shared `format_clock` is unchanged).
- godot-runtime MCP `validate`: `end_screen.gd`, `game_controller.gd`, `run_end_screen_tests.gd`,
  `end_screen.tscn` all valid (`EndScreen` registered via `--import`).
- Live (MCP): `show_outcome` driven both ways — **win** = "RUN COMPLETE" / "Gizmo survived the run." /
  SURVIVED `4:00` / LEVEL 5 / SPARKS 120; **loss** = "GIZMO OFFLINE" / "Gizmo's chassis gave out." /
  SURVIVED `2:17` (137.6s floored, not 2:18) / LEVEL 3 / SPARKS 64. A win overshoot (240.05s) clamps to
  `4:00`. Brass panel + RETRY match the HUD family. `project.godot` clean of the MCP bridge afterward.

## What the slice covers (to confirm with the learner)
Pure-first design (outcome() tested before any UI); a second `CanvasLayer` stacked above the HUD;
reusing a `Theme` across scenes; the **edge-trigger** pattern (`_prev_phase`) to fire an event once on a
state transition; `reload_current_scene()` as a zero-bookkeeping reset; and reusing one pure formatter
with caller-chosen rounding.

## Integration / playtest access
No editor wiring is required now: `GameController._ready()` auto-instances `hud.tscn` and
`end_screen.tscn` when the Inspector slots are empty. Manual wiring still works later and overrides
the defaults. Debug builds also expose F8 = force `gameover`, F9 = force `complete`, so both overlays
can be tested before final difficulty tuning makes dying natural.

## Deferred (named, flagged in-lesson)
- **Level-up choice** screen (the Phaser `"levelup"` phase — pick an upgrade mid-run).
- Richer end-screen **narrative** + the real **Spark of Humanity** stakes (mechanic TBD — ADR 0001);
  the loss copy stays factual (HP ran out) rather than conflating HP with the Spark.
- **Score** / best-run record, and a **title/start** screen — each with its system, after v1 ships.

## Decision (scope)
- Avoided editing `main.tscn` directly because it is dirty in the user's parallel art stream
  (see [[parallel-workstreams]]). Instead, the controller provides safe default UI instances at runtime.
- The F8/F9 finish shortcuts are debug-build playtest affordances, not balance design; real lethality
  still belongs to the next tuning pass.
