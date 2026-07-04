# GZ-005 — Simulation: guard-over-HP (ADR 0007)

intent: Survival becomes a recoverable guard over fixed mortal HP. Damage hits guard first; HP is one-way attrition; guard recharges after a delay since last damage. Spec FL-9.

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: hud.gd/hud.tscn (bars land in GZ-013), zone/sanctuary logic (GZ-006/008 — leave a named seam only).

grounding:
- ADR 0007 (docs/adr/): guard recharges after delay-since-last-damage; sanctuary shortens delay / raises rate; TRUE HP NEVER REGENERATES by default; recovery capped; anti-camp is structural via rising temporal pressure.
- Recovery-cap law: reference/game-balance-reference.md §3.3 ("Shield recharge — time since hit — delay-based") and §3.1 (barrier layer: strong vs burst, weak vs chip).
- Existing damage path to modify: `take_damage(amount)` simulation.gd:282 (keep HIT_INVULN i-frames, :24).

decisions made (recorded v1 numbers — placeholders, tunable later, do not re-derive):
- `max_guard := 3`, guard starts full; `guard_recharge_delay := 4.0` s since last damage; `guard_recharge_rate := 0.6` guard/s; recharge hard-capped at max_guard (no overcharge).
- A hit larger than remaining guard overflows the remainder into HP in the same hit (SPEC edge cases).
- `heart` upgrade (GZ-002) keeps affecting HP only — guard sizing is not upgrade-driven in v1 (ADR 0007's "if guard pool too large for first commit" caution; guard upgrades = deferred epic E5).
- Sanctuary seam: a public `set_guard_recharge_modifier(rate_mult: float, delay_mult: float)` no-op-by-default hook; GZ-008 will drive it from zone roles. Never bake "sanctuary heals HP" (ADR 0007 canon).
- HUD accessors: `guard_progress() -> float`, `hp_progress()` (exists :271) untouched in meaning.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) first hit reduces guard, not HP; (b) overflow hit splits guard→HP correctly; (c) guard does not recharge before 4.0s since last damage, then recharges at 0.6/s to cap; (d) HP never rises across any sequence without heart; (e) taking damage mid-recharge resets the delay; (f) PHASE_GAMEOVER still fires at HP 0 through depleted guard.
2. `tools/godot/run_all_checks.sh` exits 0 (HUD/balance suites must not regress — hp_progress semantics unchanged).

acceptance / done: hits visibly route guard-first in tests; the run gets more mortal as HP attrits; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-004 (sim-lane serialization). Blocks GZ-006. GZ-013 (HUD bars) unblocks when this merges.
model routing: **Opus** — touches the damage seam every enemy and future system flows through; ordering/reset subtleties.
cross-domain: HUD colors for the two bars come from published theme tokens (hud: guard, hp) — consume `hud_theme.tres`, never redefine (design-system ADR 0002). That work is GZ-013's, not this ticket's.
status: blocked:GZ-004
format: one issue per file (gh import later).
