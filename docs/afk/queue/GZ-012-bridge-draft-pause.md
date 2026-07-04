# GZ-012 — Bridge: GameController draft pause/resume wiring

intent: Close the loop's hinge: sim says awaiting_choice → controller freezes gameplay, shows the draft scene, routes the pick back, resumes. Spec FL-7.

files in scope:
- PRIMARY: `godot/scripts/game_controller.gd`
- also: `godot/scenes/main.tscn` (instance upgrade_draft.tscn under the UI layer, hidden by default)
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd, upgrade_draft internals.

grounding:
- Sim contract (GZ-001): `awaiting_choice`, `choices`, `choose_upgrade(id)`; sim tick already inert while awaiting — the controller freeze is about SCENE actors (player input, enemy mirroring, camera drift), not rules.
- Draft contract (GZ-011): `show_choices(...)`, `upgrade_chosen(id)`.
- ADR-0002: controller is the only bridge; scenes never reach into sim internals.

decisions made:
- Freeze mechanism: `get_tree().paused = true` with the draft scene `process_mode = PROCESS_MODE_WHEN_PAUSED`; gizmo/enemies/camera left in default (pausable) mode. Basis: engine-idiomatic, one switch, no per-node bookkeeping. (Builder: confirm existing nodes don't override process_mode.)
- Flow: physics frame detects sim.awaiting_choice rising edge → pause + show_choices(sim.choices); on upgrade_chosen → sim.choose_upgrade(id) → unpause → hide. Multiple queued level-ups (SPEC edge cases): rising edge re-fires next frame; controller loops naturally.
- While paused, elapsed/pressure do not advance (sim tick gated already; assert it).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) forcing sim into awaiting_choice → tree paused and draft visible with 3 cards; (b) emitting upgrade_chosen → sim rank incremented, tree unpaused, draft hidden; (c) sim.elapsed identical across the paused span; (d) two queued level-ups → draft shows twice sequentially.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: play → level → pick → play, hands never leaving the loop; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-001, GZ-011. Parallel-safe vs GZ-002+ (different files).
model routing: **Sonnet** — multi-node wiring but fully specified.
cross-domain: none.
status: blocked:GZ-001,GZ-011
format: one issue per file (gh import later).
