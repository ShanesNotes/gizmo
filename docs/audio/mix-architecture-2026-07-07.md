# Mix architecture handoff — 2026-07-07

Branch: `audio/mix-architecture-2026-07-07`

## Game-side changes

- `godot/default_bus_layout.tres` now carries the game mix buses:
  - `Master` with `AudioEffectHardLimiter` (`ceiling_db -0.5`, `pre_gain_db -1.0`).
  - `Music` at the inherited resting level with two sidechain compressors:
    - strong/fast duck keyed from `Voice`.
    - moderate duck keyed from `SFX`.
  - `Ambience`, `SFX`, `UI`, and `Voice` buses.
- Voice playback in `AudioDirector.play_voice_line()` now routes to the `Voice` bus. Music gain is no longer edited in code for voice ducking; bus-sidechain compression owns ducking.
- UI click playback is split out of the SFX pool and routes through a dedicated UI event lane on the `UI` bus.
- `sting_room_clear.ogg` is wired as a music-side event sting:
  - game code emits `notify_event(&"room_clear")` on room clear;
  - `AudioDirector` maps `room_clear` to `res://audio/music/sting_room_clear.ogg` on a dedicated `MusicStingLane`;
  - `set_zone_state(CLEARED)` remains pressure/zone bookkeeping and does not itself fire the sting.

## Contract notes

- A13 preserved: scene/gameplay code sends event ids (`room_clear`, `gizmo_chirp_happy`, etc.) through `AudioDirector.notify_event`; it does not name audio files, buses, or dB values.
- New identifiers use room/pressure vocabulary. This lane did not add wave/round/countdown framing.
- The `VoiceReserved` canon placeholder is resolved game-side as bus name `Voice` for the active layout.

## Audio lab still owes

Finished assets should come from the audio lab handoffs, not from this branch:

- `handoff/2026-07-07-voice-finishing` — finished voice lines/loudness pass. Expected game landing area after promotion: `godot/audio/voice/` plus import/provenance updates.
- `handoff/2026-07-07-sfx-grammar-regen` — regenerated/finished SFX grammar assets. Expected game landing area after promotion: `godot/audio/sfx/` plus import/provenance updates.

Remaining audio-lab/game integration work after those handoffs land:

- Re-measure whole-program loudness against the promoted production target; this branch only sets the mix architecture.
- Validate the `Voice` bus gain against finished voice assets; current bus gain is a starting mix value to counter the reported buried demo VO, not final mastering proof.
- Audition sidechain thresholds/ratios in live play and adjust only via the bus layout, never by raising Music to compensate.
