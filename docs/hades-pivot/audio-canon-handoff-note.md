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

## Audition-pending pacing model (long-form rework, 2026-07-06 playtest)
Shane's playtest verdict on the first wiring: shifts were far too frequent — the
composition never got to build. Reworked to a **per-run musical arc** (Fable); every
assignment stays the audio lab's to overturn in the audition pass:

**Arc:** `begin_run_silence()` rolls the run's arc once — SEG A (JAZZ) → BRG bridge
(JAZZ, plays once) → SEG B (JAZZ, loops out the stretch). SEG pool: ROAM/RUINS/KEEPER/
GILDED/TRIAL JAZZ files; bridge pool: BRG_04/BRG_08/BRG_09 JAZZ. Combat stretches live
in JAZZ; ORCH belongs to hub/rest-UI/afterglow contexts.

**Milestones (the only music switches):**
| milestone | behavior |
|---|---|
| run start | authored silence → arc SEG A on engagement (pressure > 0) or ~15 s |
| room transitions (COMBAT/SHOP/REST) | never retrigger — arc holds (`v2_arc_hold`); zone request still recorded on the seam |
| mid-run beat | a room transition after SEG A has played ≥ 65% of its length advances SEG A → bridge → SEG B (minimum-play guard) |
| BOSS room | immediate cut to REKINDLE_SIEGE (SEG_11 JAZZ); ends the arc |
| defeat / victory | ui_context sequences unchanged (2.5 s silence → SEG_06 ORCH once / SEG_12 ORCH); end the arc |
| hub return | SANCTUARY (AMB_02) ORCH |

**Retired by the rework:** per-pressure ORCH↔JAZZ hysteresis flipping (engage/relax
thresholds + 20 s dwell) — `set_pressure` now only releases the run-entry silence; the
45 s idle fade-out (it flapped between rooms). Critical-vitals AMB_03 overlay unchanged
(variant follows the arc: JAZZ in-run, ORCH in hub). Pressure scalar unchanged
(tier-weighted live enemies, chaff .15 / bruiser .35 / elite .8 / boss .9, clamped 0..1).

Deferred (recorded): AudioStreamInteractive bar-sync .tres authoring (crossfade
approximation shipped); BRG cues on menu→run/defeat→hub edges beyond the arc bridge and
the three ui sequences; loudness gates.
