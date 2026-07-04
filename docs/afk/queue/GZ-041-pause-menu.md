# GZ-041 — UI: minimal pause menu

intent: Shipping hygiene: Esc pauses the run behind a small themed overlay — Resume / Restart / Quit. Nothing else (settings = deferred E10).

files in scope:
- PRIMARY (new): `godot/scenes/pause_menu.tscn` + `godot/scripts/pause_menu.gd`
- also: `godot/scripts/game_controller.gd` (Esc handling + instance), `godot/project.godot` (`pause` input action)
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd; upgrade_draft (GZ-012 owns draft pausing — pause menu must not open while a draft is showing, and vice versa).

grounding: same pause mechanism as GZ-012 (`get_tree().paused`, menu `PROCESS_MODE_WHEN_PAUSED`) — one law for all pausing. Theme: hud_theme.tres (consume only). Copy: "Resume" / "Restart" / "Quit" — plain, sentence case (lore copy-rules projection; no new terms).

decisions made:
- Restart reloads main.tscn (fresh sim); Quit calls `get_tree().quit()`.
- Draft-vs-menu arbitration: if sim.awaiting_choice, Esc is ignored (the draft IS the pause). Recorded: simplest rule that can't deadlock.
- End screens ignore Esc (they own the terminal state).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) pause action → tree paused, menu visible; (b) Resume → unpaused, hidden; (c) Esc during awaiting_choice does nothing; (d) sim.elapsed frozen across a pause span.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: a human can put the game down; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-012 (shared pause law + arbitration). NOT parallel-safe with the controller cluster — land per LANDING-ORDER.md.
model routing: **Sonnet** — small UI + input arbitration edge.
cross-domain: theme consumption only.
status: blocked:GZ-012
format: one issue per file (gh import later).
