# Codex Notes 3 - Screens Sweep

## Summary

- Restyled title, pause, settings, end screen, and controls card into the brass/parchment/violet storybook shell language.
- Kept existing tested node paths, unique names, public methods, and signals intact.
- Title now uses the cosmos panorama backdrop and a slow alpha pulse on the START affordance.
- Pause/settings now use dark ink-leather panels, brass borders, brighter focus states, 48px buttons, and settings control accents.
- End screen now switches presentation by outcome: parchment tally page for victory, ink/crimson hearth-return treatment for death. Optional keeper rank/meta progress keys are feature-detected with `.get(...)` and tweened when present.
- Controls card is parchment with action/key columns and InputMap-derived bindings, falling back to the existing `CONTROL_ROWS` keyboard labels.

## Verification

- Baseline checked before edits: title/settings, pause, end screen, opening/controls, app shell, game controller, and integration gate were green.
- `godot --headless --path godot --user-data-dir /tmp/godot-night-design-cx3 --import` exited 0. Godot emitted nonfatal sandbox/editor socket/settings warnings.
- Syntax checked edited scripts with `--check-only`: `title_screen.gd`, `pause_menu.gd`, `settings_panel.gd`, `end_screen.gd`, `controls_card.gd`.
- Final screen suites passed:
  - `run_title_settings_tests.gd` - 46 checks
  - `run_pause_menu_tests.gd` - 48 checks
  - `run_end_screen_tests.gd` - 32 checks
  - `run_opening_tests.gd` - 92 checks
  - `run_app_shell_tests.gd` - 77 checks
  - `run_game_controller_tests.gd` - 16 checks
  - `run_integration_gate_tests.gd` - 1296 checks on rerun

## Notes

- The first final integration run hit one non-UI stochastic spawn-height probe failure; rerun passed without code changes. I did not touch combat, room graph, project settings, HUD theme, opening, speaker panel, or objective banner files.
