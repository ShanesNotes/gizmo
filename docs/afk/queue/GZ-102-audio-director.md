# GZ-102 — E1 (game): AudioDirector deep module

intent: Replace GZ-032's minimal switcher with the real seam: one small node the sim drives from game state (pressure level, zone/state, guard+HP, beacon state), hiding all bus/stream/crossfade complexity. The interface the audio lab designed its canon around.

files in scope:
- PRIMARY (new): `godot/scripts/audio_director.gd` (+ node in main.tscn)
- also: `godot/scripts/game_controller.gd` (feed state; DELETE the GZ-032 switcher region in the same diff — one music authority only)
- tests (new): `godot/tests/run_audio_director_tests.gd`, registered in BOTH run_all_checks.sh arrays
- DO NOT touch: simulation.gd; godot/audio/ contents; audio lab canon.

grounding: interface spec at `gizmo-audio-canon/reference/` (AudioDirector spec — read during pickup; it is the contract, this ticket implements it game-side); cue semantics `canon/cue-map.yaml`; buses per GZ-103. Godot grounding: `godot-prompter:audio-system` (interactive music, ducking) — never guess the API.
decisions made: inputs are PUSHED by GameController each frame (sim stays Godot-free, ADR-0002); outputs are cue selections + bus parameter changes only; low_health ambient layer keyed to hp_progress < 0.25 (cue-map's low_health cue); headless-safe (no audible assertion — tests assert selected cue ids and bus values, evidence-honest: mix QUALITY claims stay lab-side).
executable success criteria: new runner exits 0 with tests: state matrix → expected cue id (all 16 cues reachable); low-health layer toggles at the threshold; dwell hysteresis ≥ 5s preserved; `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-101 (full cue set), GZ-103 (buses), GZ-032 (replaces it). 
model routing: **Opus** — the deep-module seam the whole audio canon exists to serve.
cross-domain: consumes audio-canon interface spec verbatim; conflicts → extraction note lab-side, not silent divergence.
status: deferred:E1
format: one issue per file (gh import later).
