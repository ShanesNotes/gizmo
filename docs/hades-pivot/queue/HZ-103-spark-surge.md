# HZ-103 — Spark of Humanity meter: the Spark Surge (Call-gauge analog)

**Status:** in-progress · **Worker:** Codex · **Deps:** HZ-070/102/104/106 (shipped)
**Design authority:** `docs/adr/0012-spark-of-humanity-meter-is-the-surge-gauge.md` — binding.
ADR 0001 distinctness is law: the meter is not HP/guard, not Sparks currency, no fail state.

## Scope
1. **Charge accounting** (vitals/abilities side): exported charge rates — small on damage
   dealt, large on guard damage taken (Hades parity). Charge persists across rooms,
   empties on use and on death. Never restored by REST fixtures.
2. **Surge ability** through the ability-kit seam (ADR 0011 router): new `surge` action
   (default key F — this ticket owns the input-map addition; project.godot is unowned this
   wave), full-gauge gate, radial burst damaging + briefly staggering every enemy in the
   room (stagger = brief brain/motion suppression on the enemy side, reuse the windup
   inertness pattern if it fits).
3. **HUD**: `render_spark(charge, charge_max)` payload seam — brass flame gauge greybox,
   bottom-right per ART_DIRECTION HUD anatomy. HUD never reads game state.
4. **Orchestrator wiring**: surge needs the living enemy set; wire through the existing
   orchestrator seams (this ticket MAY touch run_orchestrator.gd — it is unowned this wave).
5. Red-first tests: charge bands (dealt vs taken rates), full-gauge gate (partial spend
   refused), empty-on-use, empty-on-death, room-persistence, REST-does-not-refill, radial
   burst hits all living enemies exactly once, stagger suppresses attacks for its window,
   HUD payload rendering.

## Fence (concurrent-safe)
Owns: player_vitals.gd, abilities/ (incl. ability_input_router.gd), hud.gd + hud.tscn,
run_orchestrator.gd, project.godot (input map only), enemies/enemy.gd + enemy_brain.gd
(stagger hook only), and suites: player/ability_input/ability_kit/hud/orchestrator/enemy.
Must NOT touch room_graph generation files, app_shell.gd, audio/, pause/export files.

## Acceptance
Failing-test-first for the gauge rules and burst; fence suites green; --check-only clean.
Copy rule (ADR 0012): UI/copy says "the Spark flares/surges", never "spend the Spark".
