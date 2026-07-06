# HZ-106 — Pause menu + export pipeline

**Status:** in-progress · **Worker:** Codex · **Deps:** HZ-061 (shipped)
**Parallel-safety fence:** owns `godot/scenes/pause_menu.tscn`, `godot/scripts/ui/pause_menu.gd`
(new), `godot/scenes/run.tscn` (instancing the overlay), `export_presets.cfg` (new), export
docs. May NOT touch `project.godot` (HZ-104 owns it), `app_shell.gd`, `room_graph/`,
`enemies/`, `player/`. Use the built-in `ui_cancel` action — no input-map edits.

## Scope
1. Pause menu: CanvasLayer overlay instanced in `run.tscn`; `ui_cancel` toggles
   `get_tree().paused` (overlay `process_mode = PROCESS_MODE_WHEN_PAUSED`; run content
   default pausable). Resume + Quit-to-desktop buttons, brass-UI-flavored greybox (match
   end_screen.gd styling idiom). Pausing must not fire during the end-screen overlay
   (guard: only when a run surface is live — check via group or parent duck-typing that
   stays inside run.tscn's own tree).
2. `export_presets.cfg`: Linux/X11, Windows Desktop, Web presets per
   godot-prompter:export-pipeline conventions; exclude tests and design docs from export
   filters.
3. `docs/hades-pivot/export.md`: one-page export/run instructions (headless export command
   per preset).
4. Headless test suite `run_pause_menu_tests.gd`: toggle pauses/unpauses tree, overlay
   visibility follows pause state, resume button unpauses, no pause when overlay absent.

## Acceptance
Red-first for pause behavior; suite green; --check-only clean; export presets validate
(`godot --headless --export-debug` dry-run acceptable to document, not required to produce
binaries if templates are missing — record what happened).
