# GZ-018 — UI: end-screen copy + run stats

intent: The aftermath tells the right story: "Beacon Rekindled" / "Gizmo's light failed", with level reached, kills, Sparks banked — never "time survived". Spec FL-12.

files in scope:
- PRIMARY: `godot/scenes/end_screen.tscn` + `godot/scripts/end_screen.gd`
- tests: `godot/tests/run_end_screen_tests.gd`
- DO NOT touch: simulation.gd (level/kills/xp accessors exist: level simulation.gd:130, kills :177, xp :131), hud_theme.tres (consume only).

grounding:
- ADR 0005 consequences: end-screen copy win = "Beacon Rekindled", lose = "Gizmo's light failed" — exact strings; no elapsed-time stat (that's pressure_clock, director fuel + debug only).
- Copy tone: warm, ceremonial, sentence case, at most one exclamation per payoff (lore lab generated-writing rules as projected into NARRATIVE-adjacent copy; do not invent new lore terms).
- Completed by the 2026-07-05 value pass: outcome() titles render "Beacon Rekindled" / "Gizmo's light failed"; the old survived-clock rendering, `SurvivedCap`/`SurvivedValue` nodes, and "Gizmo survived the run." flavor text are gone.

decisions made:
- Stats block: "Level N · M kills · S sparks" (single line, Spectral numerals via theme NumericLabel). No score (score system is deferred epic E5). No time.
- Restart affordance unchanged if present.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_end_screen_tests.gd` exits 0 with NEW tests: (a) win path renders exact string "Beacon Rekindled"; (b) lose path renders exact string "Gizmo's light failed"; (c) stats line shows the sim's level/kills/xp values; (d) absence assertion: no text matching /survived|time|[0-9]+:[0-9]{2}/ on either screen.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: end screens carry Beacon/HP truth and no timer-survival framing; branch off `gizmo-3d`.
dependencies / order: none — completed. Parallel-safe with sim and HUD lanes; touched only end-screen files.
model routing: **Haiku** — copy/stat cleanup with explicit tests.
cross-domain: lore tone only; no lore-canon edits.
status: done
completed: 2026-07-05 value-pass; focused end-screen suite and `tools/godot/run_all_checks.sh` green.
format: one issue per file (gh import later).
