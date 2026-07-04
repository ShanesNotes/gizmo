# GZ-010 — Scene: dash/dodge for Gizmo

intent: The moment-to-moment escape verb. Dash = brief speed burst on an input action, cooldown-gated. Pure scene-side (ADR-0002: player movement is not sim-owned). Spec FL-1.

files in scope:
- PRIMARY: `godot/scripts/gizmo.gd`
- also: `godot/project.godot` (add `dash` input action: Space + gamepad button, matching existing action conventions)
- tests: `godot/tests/run_game_controller_tests.gd` (or a focused helper within it)
- DO NOT touch: simulation.gd (no i-frames — recorded call below), hud (cooldown UI deferred).

grounding:
- Source feel: ts:467–468 (dashCooldown/dashTimer decay), ts:652 (dash speed ≈ ×2.4 of run for a short window), DASH_COOLDOWN 4.35s (ts constants). Ignore ts nova-on-dash, clutch, surge, score (SPEC Non-goals).
- Movement baseline: gizmo.gd (CharacterBody3D, speed 3.6 m/s per simulation.gd:39 comment).

decisions made:
- v1 dash: ×2.4 speed for 0.22s, cooldown 4.35s, direction = current move input (no input → facing). NO i-frames: keeps sim untouched and this ticket parallel-safe; contact i-frames already exist sim-side (HIT_INVULN 1.58, simulation.gd:24). Basis: SPEC FL-1 recorded call.
- Implemented as a small state in gizmo.gd (`_dash_timer`, `_dash_cooldown`), multiplying velocity before move_and_slide. No new nodes.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) simulated dash press → displacement over 0.22s exceeds walk displacement × 1.8; (b) second press inside 4.35s does nothing; (c) after cooldown, dash fires again.
2. `${GODOT_BIN:-godot} --headless --path godot --check-only --script res://scripts/gizmo.gd` exits 0; `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: kiting has a panic button; feels like the Phaser build's dodge; branch off `gizmo-3d`.
dependencies / order: none — FRONTIER. Parallel-safe (touches no sim-lane file).
model routing: **Sonnet** — input + CharacterBody3D state; small but feel-sensitive.
cross-domain: none.
status: ready-for-agent
format: one issue per file (gh import later).
