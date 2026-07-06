# GZ-101 — E1 (audio-canon lab): convert remaining 12 cues

intent: Complete the sonic arc: the 8 path_a cues and 4 ambient cues not covered by GZ-031, converted per the same promoted law.

files in scope: gizmo-audio-canon lab only; game-repo writes solely via that lab's scripted handoff into `godot/audio/`.
grounding: `canon/cue-map.yaml` (12 path_a + 5 ambient; GZ-031 took spawn_awakening, first_steps_roam, trial_pressure, rekindle_siege, sanctuary_bed — this ticket takes the rest), `canon/godot-handoff.yaml` (OGG 48kHz 16-bit, −18 LUFS measured, loop-authored, provenance sidecar, 9 CI gates).
decisions made: same pipeline, no new law; audition notes honest (`not auditioned` acceptable, loudness measured mandatory).
executable success criteria: lab `python3 validators/validate_all.py --root .` exits 0; game `${GODOT_BIN:-godot} --headless --path godot --import` exits 0 and `tools/godot/run_all_checks.sh` exits 0 with 17 OGGs + sidecars present in godot/audio/.
dependencies / order: blockedBy GZ-031 (pipeline proven once). Parallel-safe with all game lanes.
model routing: **Haiku/Sonnet** — mechanical repetition of a proven scripted pipeline → Haiku if the GZ-031 scripts landed clean, else Sonnet.
cross-domain: audio_canon lane; run inside the lab.
status: deferred:E1
format: one issue per file (gh import later).
