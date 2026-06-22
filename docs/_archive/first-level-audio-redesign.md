# First-level audio redesign — quiet wonder pass

Date: 2026-06-21
Scope: OMX G003 — reduce distracting ambience while preserving the existing Godot audio seam.

## Design change

The first playable slice now treats ambience as **quiet environmental air**, not constant machinery.

Previous default ambience started four simultaneous loops:

- core matrix bed
- energy wisp wind
- machine swarm
- beacon pulse

That made the scene feel noisy before the player did anything. The new default is a calmer two-layer bed:

1. `first_level_sanctuary_bed.ogg` — converted from `Ambient-B-Map-Sanctuary_of_Fallen_Stars.mp4`; broad quiet atmosphere.
2. `core-matrix-long.mp3` — low mechanical room tone, kept much quieter.

Beacon/proximity sounds are now staged as **accent layers** instead of autoplay layers:

- `beacon-proximity-long.mp3`
- `beacon-proximity-long-2.mp3`
- `first_level_beacon_pulse.ogg`

`GameAudio.play_ambience_accent(index)` can trigger one of these when the player nears a beacon or enters a marked zone. They no longer mask the first impression of the level.

## Mix defaults

- `Music` bus: `-14 dB`
- `Ambience` bus: `-28 dB`
- `SFX` bus: `-5 dB`
- music player: `-4 dB`
- ambience bed players: `-10 dB`
- ambience accent player: `-16 dB`
- SFX players: `-5 dB`

This is intentionally conservative: music carries emotion, ambience supports place, and accents are saved for authored moments.

## Runtime structure

- `GameAudio` still owns buses, music playlist, ambience players, SFX pool, and stream release.
- `AmbienceLayers` is now the always-on bed only.
- `AmbienceAccentPlayer` is a single non-autoplay player for beacon/proximity accents.
- SFX event mapping remains unchanged for the next story to replace the underlying WAVs.

## Verification

- `run_game_audio_tests.gd` locks the two-layer ambience bed, three staged accent layers, quiet ambience bus, and on-demand accent playback.
- `run_playable_slice_tests.gd` verifies the main scene keeps the quiet bed and staged accents.
