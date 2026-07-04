# GZ-122 — E9 (game): AnimationTree wiring for Gizmo's verbs

intent: Installed clips become behavior: walk/idle blend by velocity, attack fires on the sim's weapon cadence, hit-react on damage events. Presentation only — the sim never waits for animation.

files in scope: PRIMARY: `godot/scenes/gizmo.tscn` (AnimationTree node) + `godot/scripts/gizmo.gd` (parameter feed); tests: run_game_controller_tests.gd; DO NOT touch: simulation.gd (animation is a consumer; attack timing reads current_attack_cooldown, hit reads damage events — API-CONTRACT.md).
grounding: `godot-prompter:animation-system` (AnimationTree/StateMachine, blend spaces) — never guess node paths; installed AnimationLibrary from GZ-121; event channel per GZ-021.
decisions made: velocity-threshold walk/idle blend (0.2 m/s); attack is a one-shot layer over locomotion (upper-body if the rig mask allows, full-body otherwise — builder verifies the rig, records which); animation NEVER gates gameplay (no root motion — ADR-0002 keeps movement code-driven).
executable success criteria: new tests assert AnimationTree parameters respond to scripted velocity/attack/damage sequences (parameter values, not pixels); `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-121, GZ-021 (event consumption pattern established). Shares gizmo.tscn/gizmo.gd — not parallel-safe with GZ-010/016 leftovers (both long-merged by then).
model routing: **Sonnet** — documented AnimationTree wiring with a stated contract.
cross-domain: consumes asset-lab installs read-only.
status: deferred:E9
format: one issue per file (gh import later).
