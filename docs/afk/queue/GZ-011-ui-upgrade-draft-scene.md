# GZ-011 — UI: upgrade draft scene (3-card choice)

intent: The level-up ceremony the player actually sees: three themed cards, keyboard/mouse select, one pick, back to the fight. Spec FL-7/FL-11.

files in scope:
- PRIMARY (new): `godot/scenes/upgrade_draft.tscn` + `godot/scripts/upgrade_draft.gd`
- new test runner: `godot/tests/run_upgrade_draft_tests.gd`; register in `tools/godot/run_all_checks.sh` in BOTH arrays — `scripts=(...)` (adds --check-only; also add scripts/upgrade_draft.gd there) and `tests=(...)` (verified structure: two explicit bash arrays)
- DO NOT touch: simulation.gd, game_controller.gd (wiring is GZ-012), hud_theme.tres (generated witness — consume only, never hand-edit; design-system ADR 0002).

grounding:
- Choice payload from GZ-001: Array[Dictionary] `{id, title, rank, max_rank, color}`; descriptions per ts:1619 pattern (title + one-line effect), titles canon per ts:265–340.
- Look: brass cartouche panels + parchment labels from `godot/scenes/hud_theme.tres` (published design-system witness); HUD reference `design-handoff/gizmo-hud.png`.
- No wave/countdown/round language anywhere (ADR 0003; spec §7).

decisions made:
- Control-scene contract: `show_choices(choices: Array[Dictionary])` populates 1–3 cards; emits `signal upgrade_chosen(id: String)`; hides itself after pick. Input: 1/2/3 keys + click; first card grabs focus for gamepad.
- The scene does NOT pause anything itself — pausing/resume is GameController's job (GZ-012). It is pure view: payload in, signal out (ADR-0002 boundary).
- Card shows: title, current→next rank pips (e.g. "Rank 2/8"), one-line description, upgrade color as accent strip.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_upgrade_draft_tests.gd` exits 0 with tests: (a) show_choices with 3 entries → 3 visible cards with correct titles; (b) with 2 entries → 2 cards; (c) simulated "1" keypress emits upgrade_chosen with the first id and hides the scene; (d) card text contains "Rank x/y" from the payload.
2. `tools/godot/run_all_checks.sh` exits 0 (now including the new runner).

acceptance / done: draft scene instantiable standalone, themed, testable headless; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-001 (payload contract). Parallel-safe vs sim lane (new files). Blocks GZ-012.
model routing: **Sonnet** — Control-tree UI with a crisp contract.
cross-domain: 