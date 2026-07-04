# GZ-032 — Game: minimal state-driven music playback

intent: The loop gets a voice: one AudioStreamPlayer switching among the five installed cues on game state — no full AudioDirector (that interface spec lives lab-side; deferred epic E1). Spec: dressing, not behavior.

files in scope:
- PRIMARY: `godot/scripts/game_controller.gd` (a small `_update_music(state)` region) + `godot/scenes/main.tscn` (one AudioStreamPlayer node)
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd; godot/audio/ contents (installed by GZ-031's handoff; read-only here); bus layout work deferred.

grounding: cue→state intent per path-a spec §9 + audio lab cue-map: spawn_awakening (run start), first_steps_roam (pressure < 0.5), trial_pressure (pressure ≥ 0.5), rekindle_siege (beacon Rekindling), sanctuary_bed (inside sanctuary zone, overrides roam/trial only). Pressure accessor: sim.pressure() (GZ-006 combined value).

decisions made:
- Plain crossfade (0.8s tween on volume_db between two players is acceptable; a single player with hard switch is the floor). Hysteresis: 5s minimum dwell per cue to prevent boundary flapping (recorded call).
- If godot/audio/ lacks a cue file at runtime, skip silently (degrade, never crash) — mirrors asset-lab "missing display degrades proof" ethos.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) state transitions select the mapped cue name; (b) dwell hysteresis holds a cue ≥ 5s under oscillating pressure; (c) missing file → no error, player idle.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: a run sounds like its arc: wake, roam, crest, siege, breath; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-031 (files), GZ-006 (pressure), GZ-015 (sanctuary zones registered). NOT parallel-safe with GZ-012/015/017 (shared controller/main.tscn).
model routing: **Sonnet** — small wiring with explicit mapping.
cross-domain: cue ids are audio-canon vocabulary; consume verbatim, never rename.
status: blocked:GZ-031,GZ-006,GZ-015
format: one issue per file (gh import later).
