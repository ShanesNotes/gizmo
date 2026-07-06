# HZ-104 — AudioDirector runtime seam (room-state music)

**Status:** in-progress · **Worker:** Codex · **Deps:** HZ-061 (shipped)
**Parallel-safety fence:** owns `godot/scripts/audio/` (new), `project.godot` (SOLE worker
allowed to edit it this wave), `default_bus_layout.tres`, and `app_shell.gd` hookup. May
NOT touch `room_graph/`, `enemies/`, `player/`, `run.tscn`, or `godot/audio/` assets.

Contract authority: `/home/ark/gizmo-audio-canon/canon/audio-contract.yaml` (read-only —
sibling canvas owns it). No audio files land in `godot/audio/` in this ticket; the lab's
gate pipeline owns conversion. The seam must run silent-but-correct with placeholder
streams so the asset handoff later is drop-in by cue_id.

## Scope
1. Bus layout per handoff contract: Music, Ambience, SFX, UI, VoiceReserved.
2. `AudioDirector` autoload: cue registry keyed by `cue_id` (register_cue(cue_id, stream)),
   music-state machine (HUB, COMBAT, CLEARED at minimum) with crossfade between states
   (Tween on bus/stream volume; exported fade time), `set_music_state()` public seam,
   graceful no-op when a state has no registered cue (headless-safe, zero errors).
3. `app_shell.gd` hookup: HUB state on hub show; run surface swap → COMBAT. Room-level
   CLEARED transitions need orchestrator signals — print the wiring note, do not edit
   room_graph files.
4. New headless test suite `run_audio_director_tests.gd`: state transitions, crossfade
   direction, unknown-cue no-op, duplicate-state idempotence, autoload registration.

## Acceptance
Red-first for the state machine; suite green + app_shell suite green; --check-only clean.
