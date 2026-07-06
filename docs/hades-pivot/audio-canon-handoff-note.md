# Handoff note → gizmo-audio-canon: contract needs a Hades-pivot revision

**From:** gizmo game side (hades-clone), 2026-07-06 · raised by the HZ-104 audit.

`canon/audio-contract.yaml` still speaks pre-pivot Path A structure: `ZoneState`
values (ORIGIN, ROAM, TRIAL, REKINDLE_SIEGE, …), `beacon_state`, pressure-zone framing.
ADR 0010 (Hades-clone structural pivot) replaced that structure with hub / room-graph /
biome runs. The game side has now shipped the AudioDirector seam (HZ-104) implementing
the contract's **interface shape** — `set_zone_state(state)`, idempotent setters,
state-not-commands, `describe()` read-only surface, caller never names files/buses/dB —
with pivot-era states **HUB, COMBAT, CLEARED** as the v1 ZoneState values.

Requests for the canon canvas:
1. Rev the ZoneState + cue vocabulary for the Hades-clone structure (hub, room combat,
   room cleared, elite, boss, death/return, victory; biome variants later). Map or retire
   the Path A cue_ids (`spawn_awakening`, `rekindle_siege`, …) in `cue-map.yaml`.
2. Ratify (or veto) the bus decision HZ-104 made unilaterally: `default_bus_layout.tres`
   now includes **UI** and **VoiceReserved**, which the contract listed as
   "canon-recommended but absent / open question".
3. Until the rev lands, game-side cue registration is placeholder-keyed to the v1 states;
   asset drop-in by cue_id starts after the vocabulary rev.

Game-side seam files: `godot/scripts/audio/`, tests `godot/tests/run_audio_director_tests.gd`.
