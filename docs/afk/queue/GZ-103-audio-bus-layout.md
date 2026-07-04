# GZ-103 — E1 (game): audio bus layout

intent: Music / Ambience / SFX buses with sensible ducking, resurrected deliberately from the quarantined pre-refactor reference.

files in scope: PRIMARY (new/restored): `godot/default_bus_layout.tres`; reference read-only: `godot/_quarantine/2026-06-21-pre-art-refactor/default_bus_layout.tres` + `game_audio.gd` (read for intent; do NOT copy code blindly — it predates the art refactor).
grounding: audio lab canon requires SFX/Voice buses beyond default (their survey flagged buses missing); `godot-prompter:audio-system` for bus/ducking API.
decisions made: 4 buses — Master ← Music, Ambience, SFX; siege ducking (music −4 dB while rekindle_siege active) implemented later in GZ-102, not baked into the layout.
executable success criteria: `${GODOT_BIN:-godot} --headless --path godot --import` exits 0; a new assertion in run_game_controller_tests.gd (or GZ-102's runner if landed) verifies AudioServer reports the 4 named buses; `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-031 (audio exists to route). Blocks GZ-102.
model routing: **Haiku** — one resource file + one assertion.
cross-domain: none.
status: deferred:E1
format: one issue per file (gh import later).
