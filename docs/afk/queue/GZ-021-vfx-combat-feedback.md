# GZ-021 — Scene: combat feedback VFX from sim events

intent: The fight must be legible: pulse blasts draw a ring, hits flash the victim, deaths pop a burst, level-ups glow. All driven by the sim's existing event channel — sim stays untouched. Spec FL-2/FL-14 (legibility half of "moment-to-moment combat").

files in scope:
- PRIMARY: `godot/scripts/game_controller.gd` — fill the `_apply_game_feel(frame_events)` stub (VERIFIED no-op today, game_controller.gd:164; events already duplicated + re-emitted at :132–139)
- also: `godot/scenes/main.tscn` (a `FeelLayer` Node3D holding pooled one-shot visuals), `godot/scenes/enemy.tscn` (hit-flash material hook) if needed
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd (event PRODUCERS exist/land in the sim lane; this is a pure consumer), hud.

grounding:
- Event channel: sim.last_events (simulation.gd:188) → controller :132–139 → `simulation_events_emitted` signal (:14). Pulse event shape from GZ-003: `{"type":"pulse","radius":R}`. Hit/death/level events: consume whatever the sim already emits — builder's first step is `grep -n '"type"' godot/scripts/simulation.gd` and render ONLY existing types plus GZ-003's pulse; inventing new event types is out of scope.
- Look: gouache-friendly, parameter-animated primitives (expanding torus/disc mesh for pulse, emission flash for hits) — NO shader authoring (deferred E3), colors from theme role-keys / UPGRADE_DEFS colors carried in events.
- Fixed camera is the judge: effects must read at the Diablo angle without occluding Gizmo (design-system inherited canon).

decisions made:
- Pooled, fire-and-forget Tween effects; hard cap 24 live effect nodes, oldest recycled (perf guardrail, balance ref §6.1 frameTimeP95 concern).
- Hit flash: 0.08s emission spike on the mirrored enemy visual; death: 0.3s expanding+fading disc; pulse: ring expands to event radius over 0.25s; level-up: 0.4s vertical glow on Gizmo.
- Headless-safe: effect spawning must not crash without a display; tests assert node counts, not pixels.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) injecting a pulse event spawns exactly one ring node scaled to radius; (b) N simultaneous death events with N > 24 keeps live effect nodes ≤ 24; (c) effects self-free (node count returns to baseline after their duration); (d) unknown event types are ignored without error.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: a bystander watching the screen can tell what killed what; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-003 (pulse event shape). NOT parallel-safe with GZ-012/015/017/032/033 (shared controller/main.tscn) — land per LANDING-ORDER.md.
model routing: **Sonnet** — consumer-side effects with explicit shapes and caps.
cross-domain: colors via theme/UPGRADE_DEFS; no new visual canon.
status: blocked:GZ-003
format: one issue per file (gh import later).
