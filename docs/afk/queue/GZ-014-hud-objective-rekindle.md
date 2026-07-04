# GZ-014 — HUD: objective cue + rekindle indicator

intent: The HUD asks the right question: "can you carry your guarded light to the Beacon and rekindle it?" Objective line + a rekindle channel indicator that exists only near the Beacon. Spec FL-11; path-a spec §7.

files in scope:
- PRIMARY: `godot/scenes/hud.tscn` + `godot/scripts/hud.gd`
- tests: `godot/tests/run_hud_tests.gd`
- DO NOT touch: simulation.gd (all state exists: beacon state constants simulation.gd:101–104, `beacon_channel_progress` :165, beacon_position/radius :166–167), hud_theme.tres (consume only).

grounding:
- Path-a spec §7: objective cue "Reach the Beacon" (Dormant) / "Rekindle the Beacon" (near/inside radius); rekindle indicator appears ONLY near/inside beacon radius showing state + channel fill; NO minimap/distance readout; no countdown/exposure meter.
- ADR 0005: channel fill = beacon_channel_progress 0..1; states Dormant→Rekindling→Rekindled.

decisions made:
- "Near" := gizmo within 2× beacon_radius (recorded call — spec says "near/inside"; 2× gives approach anticipation without a distance meter).
- Objective label uses theme CapsLabel style; rekindle fill reuses the theme bar styleboxes with `hud.beacon_flame` role-key.
- On Rekindled the indicator swaps to a static "Beacon Rekindled" flourish for the beat before end screen (end screen owns the aftermath, GZ-018).
- VERIFIED existing state: `hud.gd:55 rekindle_readout(beacon_state, progress)` already produces objective/rekindle TEXT via %ObjectiveLabel (hud.gd:23,43). This ticket's actual scope = (1) proximity gating (indicator/fill only within 2× radius; the plain objective line stays global), (2) a channel FILL BAR (readout is text-only today), (3) the Rekindled flourish. Reuse rekindle_readout; do not duplicate it.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_hud_tests.gd` exits 0 with NEW tests: (a) beacon Dormant + player far → objective text "Reach the Beacon", indicator hidden; (b) player within 2× radius → indicator visible; (c) Rekindling with channel 0.5 → fill at 0.5; (d) Rekindled → rekindled flourish visible; (e) absence assertion: no distance-number, no countdown text anywhere.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: player always knows the goal, never sees a clock; branch off `gizmo-3d`.
dependencies / order: none — FRONTIER (all sim state exists today). Shares hud files with GZ-013: if both are in fli