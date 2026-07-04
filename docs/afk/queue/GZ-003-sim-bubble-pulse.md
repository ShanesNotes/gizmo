# GZ-003 — Simulation: Bubble Pulse weapon

intent: Second weapon — periodic AoE blast around Gizmo that pops nearby enemies. Rewards being surrounded; the horde answer. Spec FL-2/FL-8.

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: scenes/VFX (presentation is a later consumer of the emitted event), other scripts.

grounding:
- Source: ts:840–857 (pulse fires when `upgrades.pulse > 0` and its timer elapses; damages all enemies within radius; emits event with radius/color for rendering).
- Defs: ts:274–281 (maxRank 6, unlockLevel 2, weight 0.96, color #59dbff).
- Balance: pack-DPS weapon per balance ref §2 archetypes ("AoE/aura: low ST, high pack DPS"); keep single-target value below spark's.

decisions made (recorded v1 numbers, metres/seconds):
- Rank r ≥ 1: radius `2.0 + 0.35*(r-1)`, damage 1, period `2.6 * 0.94^(focus_rank)` scaled also by focus via current cooldown law of GZ-002; period reduced 0.15s per pulse rank above 1, floor 1.4s. Basis: balance §5.4 trash band + §2 AoE guardrail (radius² watch).
- Emits `{"type": "pulse", "radius": R}` into `last_events` (existing event channel, simulation.gd:188) so a later VFX ticket can render it without sim changes.
- Pulse damage respects enemy HP/death/XP-drop path via the existing `_hit_enemy`-adjacent kill flow — do not duplicate death logic.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) rank 0 → never fires; (b) rank 1 → after period elapses, enemies inside radius take 1 damage, outside take none; (c) kills via pulse increment kills and drop Sparks; (d) higher rank → larger radius, shorter period (monotonic); (e) pulse event present in last_events on fire.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: pulse rank drafted → periodic AoE demonstrably clears adjacent trash in tests; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-002 (apply dispatch + focus law). Blocks GZ-004.
model routing: **Sonnet** — contained port, one mechanic, clear analog.
cross-domain: none.
status: blocked:GZ-002
format: one issue per file (gh import later).
