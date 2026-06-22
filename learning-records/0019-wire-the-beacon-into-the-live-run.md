# 0019 — Wire the Beacon into the live run (Path A arc)

**Date:** 2026-06-21
**Lesson:** `lessons/0019-wire-the-beacon-into-the-live-run.html`
**Decision:** `docs/adr/0005-beacon-rekindle-replaces-timer-survival.md` (HUD/end-screen consequences) +
`docs/adr/0006` (NorthBeaconDaisZone as objective anchor)
**Mode:** **model-built + explained**, headless TDD per part + a live godot-runtime MCP verification.
**Status:** Verified — full gate **165** (sim 88 · balance 43 · controller 16 · hud 12 · end-screen 6) **and**
a live playthrough (HUD readout + real-scene beacon registration + win screen) confirmed on the greybox.

## The teaching beat — the seam, not new mechanics
0017–0018 finished the rekindle rules headless. 0019 is the bridge where the `Simulation` meets the running
scene (ADR 0002): four small wirings turn "the mechanic is proven" into "you can play it." No new game logic.

## What was built (four parts)
1. **Controller authors the Beacon (`game_controller.gd`).** New `@export var beacon_radius := 3.0`;
   `_register_beacon_under(root)` finds `NorthBeaconDaisZone` and sets `sim.beacon_position` +
   `sim.beacon_radius`; called from `_ready()` via `_register_beacon()`. Mirrors the obstacle-registration seam;
   no marker → inert. **The radius is controller-side on purpose** (major #3): the markers are bare `Marker3D`
   with no radius metadata, and adding one would edit the off-limits art-stream scene.
2. **HUD drops the countdown (`hud.gd` + `hud.tscn`).** New pure `rekindle_readout(state, progress)` →
   `REKINDLE BEACON` / `REKINDLING n%` / `BEACON REKINDLED`. `render()` drives it instead of
   `format_clock(time_remaining())`. The `.tscn` node `TimerPanel/TimerLabel` → `ObjectivePanel/ObjectiveLabel`
   (widened, font 24→18, default text). `format_clock` kept (end-screen "survived" stat still uses it).
3. **Faithful forced win (`game_controller.gd`).** F9 `_force_finished_phase_for_playtest(COMPLETE)` now sets
   `beacon_channel_progress = 1.0` + `beacon_state = REKINDLED` instead of the vestigial `elapsed = run_duration`.
4. **End-screen copy (`end_screen.gd`).** `outcome()`: COMPLETE → "BEACON REKINDLED" / "The hearth catches; the
   cold world holds back."; GAMEOVER flavor → "Gizmo's light failed." (ADR 0005).

Tests updated (red-first where logic): controller +3 (beacon reg reads dais marker; inert without; force-complete
now asserts `REKINDLED` + win title "BEACON REKINDLED"); hud +4 (`rekindle_readout`); end-screen title flip.

## Live verification (godot-runtime MCP)
`validate` clean on all 5 changed files. `run_project` (background) → HUD reads **REKINDLE BEACON** (no clock).
A `run_script` probe confirmed the sim received `beacon_radius 3` at `(0,0,-13)` straight from `main.tscn`;
teleporting Gizmo onto the dais drove `REKINDLING%` → `PHASE_COMPLETE`, and the screenshot showed the end-screen
banner **BEACON REKINDLED**. (`stop_project` produced a teardown crash backtrace — a known MCP background-mode
exit artifact per `docs/godot-mcp-runtime-hazards.md`, NOT a gameplay/code defect; the game ran correctly to the
win before exit.)

## Honest notes / deferred
- The win is **easy**: the Beacon sits in low pressure, so rekindling is a short stroll. Making it a real journey
  is the arc's back half (0021 spatial pressure, 0023 siege). Said out loud, not dressed up.
- The end-screen still shows a **"SURVIVED 0:16"** run-length stat (neutral, not a win-framing countdown). ADR 0005
  only bars time-survived *win framing*; relabel/drop is a later nicety, not a 0019 blocker.

## State after this lesson
A played run is winnable the Path A way end-to-end on the greybox. Timer **symbols** still exist
(`elapsed`/`run_duration`/`time_remaining`/`run_progress`) — 0020 retires those concepts into `pressure_clock`.

## Next (named, not built)
- **0020** retire timer symbols (concept-rename via failing test); **0021** temporal×spatial pressure;
  **0022** walkable region; **0023** the rekindle siege.

See [[path-a-refactor-arc]] and [[v1-loop-complete-balance-pass-next]] (guardrails honored: sim owns the rule;
no player-facing countdown; obstacle/zone seam reused).
