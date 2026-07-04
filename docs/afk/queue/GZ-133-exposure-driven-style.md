# GZ-133 — E3 (game): exposure-driven world style

intent: Style IS world-state: world-kit materials shift along the drain ramp with local exposure — warm and faced in the hearth, draining toward hollowed at the beacon dais and during the siege.
files in scope: PRIMARY: a `godot/scripts/style_director.gd` (new; small — reads sim.spatial_exposure_at + beacon state, writes shader params on registered kit materials) + main.tscn node; tests: run_game_controller_tests.gd; DO NOT touch: simulation.gd; token values (consume `hud_theme.tres`/published token derivatives; drain-ramp values come from the design-system publish, never invented).
grounding: design-system canon (style shifts LIVING→HOLLOWED as exposure rises, re-humanizing at rekindle); GZ-132's ratified pipeline; sim surface per API-CONTRACT.md (spatial_exposure_at, beacon_state).
decisions made: style follows the PLAYER's local exposure smoothed over 3s (not per-object fields — one global blend v1 of this system); Rekindled snaps the ramp warm over 2s (the re-humanizing payoff); parameter names published by the lab's theme/token generator, consumed verbatim.
executable success criteria: tests assert the style parameter is monotonic in exposure across three probe positions and snaps warm on Rekindled; `tools/godot/run_all_checks.sh` exits 0; PR carries a low/high-exposure screenshot pair at the gameplay camera.
dependencies / order: blockedBy GZ-131, GZ-132, GZ-033 (real kit installed).
model routing: **Sonnet** — consumer wiring of a decided pipeline.
cross-domain: consumes design-system publishes; conflicts → their extraction ledger.
status: deferred:E3
