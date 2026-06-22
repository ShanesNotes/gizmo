# First-Level Audio Pipeline

Date: 2026-06-21

Scope: OMX G005 — wire ambience sounds and a first-level music playlist into the
Godot level.

## Runtime structure

- `godot/scenes/game_audio.tscn`
  - `GameAudio` root with `game_audio.gd`.
  - `MusicPlayer` on the runtime-created `Music` bus.
  - `AmbienceLayers/*` on the runtime-created `Ambience` bus.
  - Runtime-created `SFX` bus reserved for G006 combat sounds.
- `godot/scenes/main.tscn`
  - Instances `GameAudio` so the first level starts music and ambience with the scene.

## Music playlist

The downloaded soundtrack was in `.mp4` containers, so the first-level subset was
converted to OGG Vorbis for Godot playback:

1. `godot/audio/music/first_level_01_clockwork_heartbeat.ogg`
   - Source: `/home/ark/gizmo-audio-canon/sources/soundtrack/1.1-Clockwork_Heartbeat.mp4`
   - Duration: ~82.64s
2. `godot/audio/music/first_level_02_sunlight_on_brass.ogg`
   - Source: `/home/ark/gizmo-audio-canon/sources/soundtrack/1.2-Sunlight_on_Brass.mp4`
   - Duration: ~64.74s
3. `godot/audio/music/first_level_03_clockwork_wanderer.ogg`
   - Source: `/home/ark/gizmo-audio-canon/sources/soundtrack/2.1-Clockwork_Wanderer.mp4`
   - Duration: ~112.90s

`GameAudio` plays the first track on scene start and advances/wraps the playlist
when a track finishes.

## Ambience stack

The first-level ambience was redesigned on 2026-06-21 to avoid distracting always-on noise.
The default autoplay bed now uses only two quiet layers:

- `loops/first_level_sanctuary_bed.ogg` — broad quiet atmosphere converted from `/home/ark/gizmo-audio-canon/sources/soundtrack/Ambient-B-Map-Sanctuary_of_Fallen_Stars.mp4`.
- `core-matrix-long.mp3` — low mechanical room tone.

Beacon/proximity sounds are staged as non-autoplay accent layers instead of constant bed noise:

- `beacon-proximity-long.mp3`
- `beacon-proximity-long-2.mp3`
- `loops/first_level_beacon_pulse.ogg`

The script duplicates loaded streams and enables loop flags in memory so ambience
bed layers repeat without changing source import settings. Accents play only through
`GameAudio.play_ambience_accent(index)`. See `docs/first-level-audio-redesign.md`.

## Verification

- Fresh temp-project Godot import: no script errors.
- `run_game_audio_tests.gd`: verifies nodes, buses, playlist paths, loaded streams,
  autoplay, ambience loops, playlist wrapping, and main scene wiring.
- Full suite rerun includes the game-audio suite before checkpointing.
