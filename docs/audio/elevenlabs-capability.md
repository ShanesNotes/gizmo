# ElevenLabs Capability — game-side integration map

`derived from audio canon; do not edit as source`

Written 2026-07-04. Canon and generation law live in `C:/Users/Shane/gizmo-audio-canon`
(`reference/elevenlabs-production.md` — full API surface + spend directive;
`reference/elevenlabs-character-voices.md` — per-character prompts). This doc is the
game-repo map: what ElevenLabs-generated audio plugs into *here*, so agent slices wire the
right seams instead of inventing new ones.

## Directive

Coding agents have **full autonomous ElevenLabs API access** (key: `ELEVENLABS_API_KEY`,
git-ignored `.env`; official MCP `elevenlabs-mcp` or REST). No per-call approval, no budget
ceiling — the board wants the world fully immersive: sound effects, ambient beds,
environmental sound, music variants, character voice, dialogue, trailers, cinematics.
Accounting stays strict: ledger-before-use, provenance sidecar, no-retry-spend on a gate
reject. Generated audio is a source candidate in the audio lab; **only converted, gate-passed
files (OGG loops / WAV SFX per its `godot-handoff.yaml`) land in `godot/audio/`.**

## Where sound attaches (the seams — do not widen them)

1. **Per-event SFX:** the sim emits `last_events` each tick; `game_controller.gd` re-emits
   them via the `simulation_events_emitted` signal — that signal is the one clean hook for
   event-driven SFX. Sim-facing code never names a file, bus, dB, or clip index (gate A13).
2. **Continuous/reactive audio:** the planned `AudioDirector` autoload behind the six-method
   AudioContract (`set_zone_state`, `set_pressure`, `set_beacon_state`, `notify_vitals`,
   `notify_event`, `describe`) — see `docs/audio/soundtrack-map-v2.md`. The legacy
   null-guarded `GameAudio` seam in `game_controller.gd` (`set_swarm_intensity`,
   `duck_music`) is the stopgap until the director exists.
3. **Locomotion:** code-driven from velocity (`gizmo.gd`), so footsteps hook the same
   velocity threshold as `walk_bob` — as the modular split (body loop + surface contact +
   state overlay), never one baked walk sound.
4. **Animation clips:** future authored clips carry `AudioEvent` markers at frames
   (asset-pipeline law); until clips exist, all combat SFX are sim-event-driven.

## SFX vocabulary to cover (generation targets)

Current Godot sim (`godot/scripts/simulation.gd`): attack, hit, defeat (+ Spark drop),
pickup, levelup, player hurt + knockback, gameover; enemy family sounds (nibbler, dasher,
brute, warden — household-sounds-pitched-wrong doctrine); Beacon Dormant → Rekindling
(area-hold channel under peak pressure) → Rekindled.

Full target vocabulary (Phaser source of truth, `game-src-phaser/src/game/simulation.ts`
`GameEvent` union): `attack, hit, defeat, pickup, cacheRush, combo, flowSave, flowBurst,
echoBurst, bountyStart, bountyExpired, bountyComplete, boostScoop, snapBoost, dashThread,
enemyTell, closeCall, clutchBurst, recoveryDrop, surge, levelup, reroll, upgrade, evolve,
hurt, secondWind, dash, elite, complete, gameover` — plus per-upgrade select/rank-up cues
(Spark Chain, Bubble Pulse, Orbit Stars, Snack Magnet, Sneaker Mode, Extra Heart, Quick
Fingers, Jackpot Sparks, Level-Up Nova) and pickup kinds (Spark/xp, cache, heart). Resource
sounds stay distinct: HP ≠ guard ≠ Sparks ≠ Scrap ≠ the Spark of Humanity (blocked until
ADR 0001).

## UI, VO, and screens

- **HUD:** level-up flash, XP fill, objective transitions (`REKINDLE BEACON` →
  `REKINDLING %` → `BEACON REKINDLED`). Diegetic pressure only — no timer ticks, no meter
  beeps.
- **End screen:** win sting ("BEACON REKINDLED" — quiet light, not fireworks) vs loss
  ("GIZMO OFFLINE"), retry click, and optional VO for the two flavor lines (Marginalia).
- **Planned UI contexts** (`soundtrack_cue_map_v2.json`): main_menu, upgrade_ui, map_ui,
  shop_ui, defeat_reflection, victory_sequence, credits, low-HP vitals overlay — build
  screens against these reserved contexts.
- **Voice:** Marginalia (narrator/ceremony), Wick (Sanctuary companion) via Voice Design;
  Gizmo and the swarm are wordless (vocalizations via SFX). Lines obey
  `gizmo-lore/witnesses/voice-and-dialogue-brief.md`. VO lands on the VoiceReserved bus
  when the bus layout is authored.

## Trailers & cinematics

- **Intro/trailer VO:** Marginalia narration (TTS/Voice Design; Voice Changer over a human
  performance for the highest-quality read). Text to Dialogue for multi-voice authored
  scenes (Wick + Marginalia). Dubbing for localization post-v1; Forced Alignment for
  subtitle timing (and future lip/gesture sync data).
- **Music:** Eleven Music composition plans (intro/loop/outro sections mapped to the cue
  map's ORCH/JAZZ variant axis) as a hedge lane beside AIVA; inpainting to repair a loop
  seam or re-score one movement. Instrumental, original, motif-faithful.
- **Environmental storytelling:** region soundscapes per
  `gizmo-level-design/docs/elevenlabs-region-soundscapes.md` — the island's cruelty is
  heard, not displayed.

## Gates (restated so no slice forgets)

No retired round/countdown framing in audio states or filenames (A3/A7); resources sonically
distinct (A4); Gizmo small and handcrafted, never industrial or cartoon (A5); modular
locomotion (A6); Sanctuary breathes, Rekindling is a fought climax not a victory sting
(A8/A9); music leaves room for combat reads (A12); sim never names files/buses (A13); raw
generations never ship — deterministic finishing with recorded hashes only (A10/A14).
