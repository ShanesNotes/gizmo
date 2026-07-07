# Codex Notes 1 - HUD night design pass

## Changed

- Restyled `godot/scenes/hud.tscn` with reusable brass/leather StyleBoxFlat resources for the nameplate, Sparks readout, Spark Surge meter, and ability frame.
- Kept `%ShieldBar` as a `ProgressBar` and added a thin `%ShieldTopGlow` ProgressBar child for a luminous teal top-edge read.
- Strengthened `%HpBar` with a brass-backed cell frame and added runtime HP cell flash overlays in `godot/scripts/hud.gd` when bar value decreases.
- Added three violet Spark Surge pips under the meter and update their lit/unlit state from `render_spark(charge, charge_max)`.
- Restyled dynamic ability slots and boon rows as brass-framed slots while preserving existing public method signatures and tested child order.
- Rebuilt the region toast as a parchment caption-bar PanelContainer with 30px ink text and the existing fade timing.
- Raised gameplay-critical HUD font sizes to meet couch-readability constraints.

## Verification

- `godot --headless --path godot --user-data-dir /tmp/godot-night-design-cx1 --check-only --script res://scripts/hud.gd` passed with HOME/XDG redirected to `/tmp`.
- `godot --headless --path godot --user-data-dir /tmp/godot-night-design-cx1 --script res://tests/run_hud_tests.gd` passed: 84 checks.
- `godot --headless --path godot --user-data-dir /tmp/godot-night-design-cx1 --script res://tests/run_simulation_tests.gd` passed: 89 checks.
- `godot --headless --path godot --user-data-dir /tmp/godot-night-design-cx1 --import` exited 0 with HOME/XDG redirected to `/tmp`; Godot printed sandbox-local TCP listen warnings, but no HUD or script test failed.
