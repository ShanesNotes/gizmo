# GZ-013 — HUD: guard-over-HP bars

intent: The survival readout per ADR 0007: a cyan/teal recoverable guard bar above a smaller warm mortal HP bar. Spec FL-11.

files in scope:
- PRIMARY: `godot/scenes/hud.tscn` + `godot/scripts/hud.gd`
- tests: `godot/tests/run_hud_tests.gd`
- DO NOT touch: simulation.gd, hud_theme.tres (consume only — published witness, design-system ADR 0002), end_screen.

grounding:
- ADR 0007 HUD change: "cyan/teal recoverable guard bar above smaller warm mortal HP bar"; path-a spec §7.
- Sim accessors from GZ-005: `guard_progress()`, `hp_progress()` (existing, simulation.gd:271).
- Colors: theme role-keys `hud.guard` / `hud.guard_lit` / `hud.hp` from `godot/scenes/hud_theme.tres` — never hard-code hex (design-system seam).
- Look reference: `design-handoff/gizmo-hud.png`.

decisions made:
- Guard bar sits directly above the HP bar in the existing HUD cartouche; HP bar height ≈ 60% of guard bar (guard is the working surface, HP the mortal fact — ADR 0007 reading). Existing single HP bar becomes the smaller warm bar; do not delete its node path if tests reference it — rename via test-updated assertions in the same diff.
- No numeric guard text in v1; keep existing HP numerals if present.
- No countdown, no exposure meter, no wave counter — add an explicit absence assertion (spec §7; ADR 0008 validator "no player-facing round-counter UI").

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_hud_tests.gd` exits 0 with NEW tests: (a) guard bar value tracks sim.guard_progress() after a scripted hit + recharge; (b) HP bar tracks hp_progress() and does not move on a guard-only hit; (c) HUD contains no node whose name or visible text matches /wave|round|countdown/i.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: one glance answers "how safe am I, how mortal am I"; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-005 (guard accessors). Parallel-safe vs GZ-006+ and vs UI lane siblings.
model routing: **Sonnet** — themed Control work with wired assertions.
cross-domain: colors/tokens from design-system published theme; consume only.
status: blocked:GZ-005
format: one issue per file (gh import later).
