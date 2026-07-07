# Codex Notes 2

## Brief 2 - Keepsake Draft Manuscript Screen

- Restyled `godot/scenes/boon_draft.tscn` and `godot/scripts/boon_draft_ui.gd` as a warm parchment-page draft overlay against the violet cosmos, matching the objective-card language from `design-handoff/gizmo-hud.png`.
- Kept all existing public `BoonDraftUI` methods/signals and the test-owned node paths/types intact: `SafeArea/Content/OfferRow/Card1..Card3` remain `Button`s with `Margin/VBox/*Label` children.
- Added local manuscript card styling: parchment ground `#fae5cc`, ink `#352c2b`, brass/gold frames, rarity title flourish, legendary outer frame, visible focus style, and hover/focus lift.
- Added rarity reveal presentation for epic/legendary cards: scale-in tween from `0.92` to `1.0` with `TRANS_BACK`, border-flash frame, and existing reveal lock/sting behavior preserved.
- Added thorned-frame detection for trade-off/cursed/cost offers using defensive helpers. Dictionaries are read with `.get(key, default)` and Resources are feature-detected through property-list and `has_method` guards.

## Verification

- `godot --headless --path godot --user-data-dir /tmp/godot-night-design-cx2 --import` completed with exit 0. Godot 4.7 printed sandbox noise about editor sockets/settings, but import finished.
- `godot --headless --log-file /tmp/godot-night-design-cx2/check.log --path godot --check-only --script res://scripts/boon_draft_ui.gd` passed.
- Exact test command without `--log-file` crashed before script load on `user://logs/godot2026-07-07T02.57.41.log`. This installed Godot 4.7 binary does not advertise `--user-data-dir`; adding `--log-file` avoids the broken default log path.
- `godot --headless --log-file /tmp/godot-night-design-cx2/boon-test.log --path godot --user-data-dir /tmp/godot-night-design-cx2 --script res://tests/run_boon_draft_ui_tests.gd` passed: `PASS - 113 checks`.
