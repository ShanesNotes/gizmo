# Soundtrack v2 handoff — dual-variant score wiring (audio-canon → game)

`derived from audio canon; do not edit as source`

Canon lives in `C:/Users/Shane/gizmo-audio-canon` (`canon/style-variants.yaml`,
`canon/audio-contract.yaml`, `canon/cue-map.yaml`). Media source of truth:
`C:/Users/Shane/gizmo-soundtrack` (61 MP4 sources; sha256+durations in audio-canon
`sources/soundtrack-v2/external-media-manifest.json`). Machine-readable map for
implementation: `docs/audio/soundtrack_cue_map_v2.json`. **Nothing is auditioned;
raw MP4s never ship — convert per audio-canon `godot-handoff.yaml`.**

## The one-paragraph contract

The score exists twice: **JAZZ** (Future Jazztronica — 808 drops, trap-like drive) is
the world under pressure — roam-under-encroachment, trial, beacon approach, rekindle
siege. **ORCH** (Original Orchestral) is the world at ease — menus, sanctuary, hubs,
calm roam, afterglow. (Polarity corrected to producer intent 2026-07-04; the steward
flags it as not universally true, so every per-zone assignment is provisional until the
audition pass.) Which style is playing is itself world-state information. Silence is a
third authored state. The simulation never knows any of this: it speaks only the six `AudioContract`
methods (`set_zone_state`, `set_pressure`, `set_beacon_state`, `notify_vitals`,
`notify_event`, `describe`); variant choice, presence, bridges, buses, and files are
all AudioDirector-internal (gate A13).

## What the AFK agent implements

1. **AudioDirector autoload** per audio-canon `audio-contract.yaml` (native Godot:
   `AudioStreamInteractive` for SEG/BRG transitions authored as `.tres`,
   `AudioStreamSynchronized` for pressure stems, bus mix from
   `default_bus_layout.tres`). Set BPM/Bar-Beats at import or bar sync silently fails.
2. **Variant selection**: `variant = f(zone_state, pressure_band, ui_context)` with
   hysteresis (engage ≥ 0.25, relax < 0.15, 20 s min dwell). Default polarity: JAZZ
   under pressure, ORCH at ease — provisional per zone until auditioned. No
   `set_variant()` on the seam — reject.
3. **Presence grammar**: ORIGIN spawns into authored silence (music enters on first
   movement or ~15 s); idle lulls fade music out after 45 quiet seconds at low pressure
   (beds + locomotion keep breathing); `any → REKINDLE_SIEGE` is an immediate cut;
   everything else ambient-enters over 2–4 bars.
4. **Bridges**: the 12 BRG cues fire on the edges listed in the JSON (menu→run,
   ORIGIN→ROAM, calm↔engage bands, defeat→hub, …, afterglow→credits). Each has a JAZZ
   twin used when both endpoints resolve JAZZ.
5. **Menus/UI are scene-layer**: main menu = SEG_01 ORCH loop (the ORIGIN theme at
   ease; JAZZ alternate is an audition taste call); upgrade UI = AMB_01 ORCH; shop =
   AMB_04 ORCH (JAZZ Merchant's_Pendulum alternate); defeat reflection = 2–4 s silence
   then SEG_06 ORCH once; victory = SEG_12 ORCH; credits = Brass_Cradle then BRG_12
   loopback. The diegetic zone enum is untouched.
6. **Vitals overlay**: AMB_03 enters only on sim-declared critical vitals via
   `notify_vitals`; never a zone; resources stay sonically distinct (gate A4).

## Gates that reject a wrong build

No wave-round/countdown audio states (A3/A7); guard ≠ HP ≠ Sparks ≠ Scrap sounds (A4);
siege is a fought climax, not a victory sting (A9); music leaves room for combat reads
(A12); sim-facing code naming a file/bus/dB/clip index (A13); raw MP4 imported as a
runtime asset (A10/A14).

## Open before ship

Audition pass — this finalizes the variant polarity per zone (steward: the JAZZ =
pressure default is "not universally true"), cue fit, the SEG_01 JAZZ duplicate pick,
and JAZZ↔ORCH crossfade compatibility — plus loop-point authoring (file-end =
loop-return, offset 0) and loudness measurement to −18 LUFS / −1 dBTP.
