# Refactor prep — Path A beacon-rekindle invariants

Status: guardrail checklist for the next implementation refactor. This is not an
implementation plan; it records the non-negotiable domain and architecture boundaries
that the refactor must preserve or deliberately replace with tests.

## Source artifacts

- `CONTEXT.md` — active Path A direction and truth map.
- `AGENTS.md` — workspace operating rules and no-wave rule.
- `docs/adr/0001-sparks-hp-spark-of-humanity-are-distinct.md` — HP/Sparks/Spark of Humanity separation.
- `docs/adr/0002-simulation-owns-rules-scene-renders.md` — simulation owns rules; scene renders.
- `docs/adr/0003-director-pressure-not-discrete-waves.md` — no player-facing wave rounds.
- `docs/adr/0005-beacon-rekindle-replaces-timer-survival.md` — Path A win = Beacon Rekindled.
- `docs/adr/0006-spatial-director-pressure-zones-walkable-region.md` — place-aware pressure and walkable-region seam.
- `docs/adr/0007-guard-over-hp-survival-sanctuary-recharge.md` — later guard-over-HP survival seam.
- `docs/adr/0008-stagehand-baker-not-world-generator.md` — author-time stagehand/baker boundary.

## Non-negotiable invariants

1. **True 3D Godot remains the target.** Use `Node3D`, `CharacterBody3D`, `Camera3D`, `MeshInstance3D`, and `godot/assets/gizmo.glb`; do not revive 2.5D/sprite/orthographic gameplay architecture.
2. **Simulation owns game rules.** Beacon state, channel progress, HP loss, director pressure, enemy spawning, pickups, and phase transitions belong in `godot/scripts/simulation.gd` and headless tests; scene/controller code renders and feeds authored anchors.
3. **No wave-round model.** Do not add Wave 1/5 counters, round-cleared win states, or wave-gated boss ladders. Enemy escalation remains director pressure and special threats.
4. **Win condition changes, loss does not.** Timer completion must stop winning the run; `PHASE_COMPLETE` should come from Beacon Rekindled. `HP <= 0` still sets gameover.
5. **Clock becomes pressure fuel.** The existing `elapsed`/`run_duration` concepts can survive as `pressure_clock`/ramp horizon, but must not be exposed as a player countdown or win deadline.
6. **Beacon rekindle is not Spark-of-Humanity fuel.** HP, Sparks currency, Spark of Humanity meter, and beacon channel remain distinct.
7. **Rekindle is an area-hold encounter.** Entering the beacon radius starts/advances a channel; leaving pauses or slowly decays; instant-win on entering is ruled out.
8. **Rekindling forces climax pressure.** While the channel is active, spatial exposure/pressure should read as peak siege per ADR 0005/0006.
9. **Scene anchors feed the sim.** Controller/scene code may register `ObjectiveBeaconAnchor`, `NorthBeaconDaisZone`, pressure zones, obstacles, and walkable boundaries, but should not own win logic.
10. **Intentional forward hooks stay until replaced.** Preserve `_audio`, `simulation_events_emitted`, and existing event seams unless the refactor replaces them with tested paths.
11. **No Phaser or NARRATIVE rewrite.** Port/compare where useful, but do not rewrite `game-src-phaser/` or `design-handoff/NARRATIVE.md` during this refactor.
12. **ADR 0008 stagehand discipline.** Do not run whole-block layout generators as active authority without manifest/provenance and tests.

## Current old-loop pins to replace deliberately

These are not hygiene failures; they are known refactor targets that should go red first:

| Current seam | Why it must change |
|---|---|
| `simulation.gd:190-205` completes the run when `elapsed >= run_duration`. | ADR 0005 moves completion to Beacon Rekindled. |
| `simulation.gd:207-215` exposes run progress/time remaining for countdown UI. | Keep pressure progress if needed, but HUD must not show countdown. |
| `run_simulation_tests.gd:_test_run_completes` expects timer-elapsed win. | Replace with beacon-channel completion tests. |
| `hud.gd` renders `%TimerLabel` from `sim.time_remaining()`. | Replace with rekindle/proximity/channel indicator near Beacon. |
| `run_hud_tests.gd` locks countdown `format_clock()`. | Either remove or demote to debug-only formatter; add rekindle indicator tests. |
| `end_screen.gd` returns `RUN COMPLETE` / `Gizmo survived the run.` | Replace win copy with `Beacon Rekindled`; keep loss copy aligned with ADR 0005. |
| `run_end_screen_tests.gd` expects `RUN COMPLETE`. | Update to Beacon Rekindled win copy. |
| `game_controller.gd:force_complete_for_playtest` clamps elapsed to run duration. | Debug force-complete should force beacon-complete phase/copy without teaching timer win. |

## Minimum red-green test shape for the refactor

- Simulation: timer elapsed alone does **not** complete the run.
- Simulation: entering/remaining in beacon radius advances `beacon_channel_progress`.
- Simulation: leaving the radius pauses or decays channel progress according to chosen tuning.
- Simulation: completing the channel sets `phase = PHASE_COMPLETE`.
- Simulation: HP 0 still sets `PHASE_GAMEOVER`.
- Simulation/director: pressure still rises from the pressure clock and reaches peak during rekindling.
- Controller: authored beacon/zone anchors are registered into the simulation seam.
- HUD: no player-facing countdown; rekindle/proximity/channel state is shown instead.
- End screen: win copy is `Beacon Rekindled`; loss copy remains clear and non-wave.

## Stop condition for the upcoming refactor

A refactor slice is complete only when the timer-win/countdown behavior is removed or
demoted to debug-only, Beacon Rekindled is proven by headless tests, HUD/end-screen copy
matches ADR 0005, and the committed Godot gate imports/tests cleanly from a clean tree.
