# First-Level SFX Redesign

Date: 2026-06-21
Scope: OMX G004 — replace arcade-like event sounds with grounded first-level feedback.

## Direction

The first playable slice should sound like a tiny brass/wood machine moving through
a cosmic workshop, not like generic arcade pickups. The five event sounds keep the
same Godot resource paths for stable wiring, but their contents are now longer,
softer, and more material-specific:

- `spark_attack.wav` — brass spring snap + glass spark, 0.34 s.
- `spark_hit.wav` — muted stone/brass impact with grit, 0.28 s.
- `spark_defeat.wav` — broken clockwork scatter and falling violet energy, 0.82 s.
- `spark_pickup.wav` — gentle glass chime with a small gear tick, 0.38 s.
- `spark_levelup.wav` — warm clockwork arpeggio, 1.05 s.

All five are mono 44.1 kHz PCM WAVs so `GameAudio` can play them with low latency
through the pooled `SFX` bus.

## Reproducible generator

`tools/audio/generate_clockwork_sfx.py` procedurally rebuilds the WAVs using only
Python's standard library. It layers struck-bell partials, filtered mechanical
noise, low body thumps, and seeded tick clusters, then soft-clips and normalizes
for safe peaks.

Run from repo root:

```sh
python3 tools/audio/generate_clockwork_sfx.py
```

The script intentionally overwrites the existing stable paths instead of creating
a new naming layer; that keeps `FeedbackFx`, tests, and any future event timeline
references intact.

## Verification hooks

`GameAudio.get_sfx_duration_seconds(event_type)` exposes asset duration for tests.
`run_game_audio_tests.gd` now checks that each event sound is present, playable,
and falls within the intended one-shot duration band so future accidental arcade-
short replacements are caught.
