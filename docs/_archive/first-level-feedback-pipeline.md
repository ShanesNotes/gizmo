# First-Level Feedback Pipeline

Date: 2026-06-21

Scope: OMX G006 — attack/event sounds and simple VFX tied to simulation events.

## Event seam

`Simulation.last_events` remains the rules-side event source. `GameController`
now copies that frame's events after `sim.tick()` and emits:

```gdscript
signal simulation_events_emitted(events: Array)
```

`FeedbackFx` listens to that signal in `main.tscn`, so feedback stays scene-side
and does not push rendering/audio responsibilities into the simulation.

## SFX

The five event WAVs now use grounded clockwork/brass/spark material cues instead
of arcade-short placeholders while keeping the stable prototype paths:

- `godot/audio/sfx/spark_attack.wav` — brass spring snap + glass spark.
- `godot/audio/sfx/spark_hit.wav` — muted stone/brass impact.
- `godot/audio/sfx/spark_defeat.wav` — broken clockwork scatter.
- `godot/audio/sfx/spark_pickup.wav` — gentle glass chime.
- `godot/audio/sfx/spark_levelup.wav` — warm clockwork arpeggio.

`GameAudio` owns an 8-player SFX pool on the runtime-created `SFX` bus and maps
simulation event names (`attack`, `hit`, `defeat`, `pickup`, `levelup`) to those
WAVs. The assets are reproducible with `tools/audio/generate_clockwork_sfx.py`;
see `docs/first-level-sfx-redesign.md` for the sound-design notes.

## VFX

`godot/scenes/feedback_fx.tscn` / `godot/scripts/feedback_fx.gd` spawns simple
one-shot `GPUParticles3D` bursts at event positions:

- attack — cyan spark at the shot midpoint.
- hit — warm impact burst at enemy position.
- defeat — violet scrap pop at enemy death.
- pickup — green Spark collection glint.
- levelup — gold burst around Gizmo.

This is deliberately small and readable from the fixed camera; it is a foundation
for later bespoke shader trails or authored particle scenes.

## Verification

- Fresh no-cache Godot import: no script errors.
- `run_game_audio_tests.gd`: SFX assets, pool, event mapping, and playback count.
- `run_feedback_fx_tests.gd`: manual events and real `GameController` event signal
  both trigger SFX + VFX.
- Full suite: 11 Godot suites / 516 checks pass.
