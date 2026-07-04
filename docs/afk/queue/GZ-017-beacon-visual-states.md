# GZ-017 — Scene: beacon visual states (Dormant / Rekindling / Rekindled)

intent: The hearth must read at the fixed camera: cold and dark when Dormant, stirring light while Rekindling (scaled by channel progress), warm and alive when Rekindled. Presentation only. Spec FL-14.

files in scope:
- PRIMARY: `godot/scenes/main.tscn` (beacon visual subtree: MeshInstance3D + OmniLight3D) + a small handler in `godot/scripts/game_controller.gd` (state → visual mapping)
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd; hud (GZ-014 owns the HUD half).

grounding:
- Sim state exists: beacon constants simulation.gd:101–104, beacon_channel_progress :165.
- Palette: warm brass / violet spark / deep indigo (path-a spec §2 HEARTH palette); pull hexes from `godot/scenes/hud_theme.tres` role-keys (`hud.beacon_flame`, `hud.beacon_spark`) or theme-derived constants — no invented colors (design-system seam).
- Camera is the judge: fixed Diablo angle (camera_rig.gd) — readability at that angle is the bar (design-system inherited canon).

decisions made:
- Dormant: emission ≈ 0, light energy 0.1 cool indigo. Rekindling: light energy lerp 0.5→3.0 with channel progress, color warms indigo→brass. Rekindled: steady 3.5 warm brass + emission on. One material, animated by parameters — no shader authoring (render-target work is deferred epic E3).
- Greybox beacon mesh acceptable (cylinder/spire); swapped by GZ-033 when asset q02 installs.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) forcing beacon states changes the light energy monotonically Dormant < Rekindling(0.5) < Rekindled; (b) Rekindling light energy scales with channel progress.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: at the gameplay camera you can read the beacon's state from across the dais; branch off `gizmo-3d`.
dependencies / order: none — FRONTIER (state exists). NOT parallel-safe with GZ-012/GZ-015 (shared main.tscn/game_controller.gd) — coordinate landing order; rebase is acceptable.
model routing: **Sonnet** — scene + light work, small mapping logic.
cross-domain: colors via design-system theme role-keys; consume only.
status: ready-for-agent
format: one issue per file (gh import later).
