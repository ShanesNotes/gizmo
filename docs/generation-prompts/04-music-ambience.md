# 04 — Music & Ambience

`derived from ecosystem canon; do not edit as source`

Tool law (audio-canon `canon/production-standards.yaml`, `canon/godot-handoff.yaml`, and
`reference/tools-matrix.md`): shippable music requires an approved production route with
recorded license/provenance; hosted-generator outputs are source candidates until reviewed.
Ambience = generated loop candidates finished through the same handoff gates. Prompt discipline
(A11): descriptive, original, **instrumental**, no living-artist names, no accidental vocals,
no copyrighted melody asks.

**Variant polarity (corrected 2026-07-04, provisional per-zone until audition):**
**ORCH = ease** (interiors, sanctuary, calm roam, afterglow, menus) · **JAZZ (Future
Jazztronica: 808 drops, trap-like drive) = pressure** (encroachment, trial, beacon approach,
siege). Variant selection is AudioDirector-internal only (A13). Silence is a deliberate third
state.

**Motif pitch material** (`canon/motifs.yaml`) — weave, don't quote mechanically:
- gizmo_clockwork C#–E–G#–A–G#–E (pizzicato strings, bassoon, celesta, marimba, muted horn)
- living_light E–F#–G#–A#–B–C# (celesta, glockenspiel, harp, solo violin, glass harmonics) — SPARING
- beacon_resonance B–C#–E–G#–F#–E (french horns, cellos, violas, warm brass)
- void_pressure F#–G–C–B–F# (low brass, contrabassoon, timpani, low strings, detuned metal)

**Delivery:** OGG Vorbis loops, loop-return point at file end (offset 0 — Godot bug #64775),
−18 LUFS / −1 dBTP program target, no per-stem loudness normalizing. Mix restraint (A12): leave
room for combat SFX readability. No wave stingers, no countdown beeps, ever (A3).

**Base prompt frame (prepend to every cue):**
> Instrumental, hand-played chamber-orchestral palette with warm brass, celesta, harp, low
> strings and soft clockwork percussion; storybook, ceremonial, melancholy-but-warm; intimate
> mix with generous space; seamless loop.
JAZZ variants swap the frame's rhythm layer: *"understated future-jazztronica pulse — deep 808
foundation, sparse trap-inflected hats, brushed kit ghost-notes — under the same chamber
palette; pressure carried by rhythm density and low-end, never by alarm or siren."*

---

## Path A cues (`canon/cue-map.yaml` — each needs SEG_x.1 ORCH + SEG_x.2 JAZZ)

- **spawn_awakening (ORIGIN)** — "A warm awakening at a kept hearth: the gizmo_clockwork motif
  (C#–E–G#) introduced alone on celesta and pizzicato, joined by one muted horn like morning
  light on brass; unhurried, safe, home. 60–70 BPM."
- **first_steps_roam (ROAM)** — "First steps onto the wounded island: the clockwork motif
  walking on marimba and bassoon over soft low-string ground, small curiosity figures in harp;
  open, gently wary, forward-leaning. 80 BPM."
- **wonder_reveal (WONDER)** — "An early wonder: a suspended shimmer of harp and glass
  harmonics parting to reveal a slow wide horn line; one sparing touch of the living_light
  figure (E–F#–G#) at the crest; awe kept quiet."
- **landmark_memory (LANDMARK)** — "The gear-henge remembered: a stately, slightly waltzing
  brass chorale over ticking clockwork percussion, as if a great instrument recalls being
  tended; nostalgic, ceremonial, mid-warm."
- **waltz_lost_machine (WALTZ, optional)** — "A melancholy waltz for a lost machine: music-box
  celesta and solo viola in 3/4, elegant and threadbare, one wrong-leaning harmony resolved
  kindly; graceful sadness, never spooky."
- **ruined_platforms (RUINS)** — "Broken-route traversal: sparse low strings and dry percussion
  over groaning sustained basses, the clockwork motif fragmenting and re-assembling; tension by
  spaciousness and missing beats, not by alarm."
- **wanderer_keeper (KEEPER)** — "A watcher's pressure: the void_pressure cell (F#–G) circling
  on contrabassoon and low brass beneath a patient, formal string ostinato; being observed,
  order without warmth."
- **gilded_path (GILDED)** — "Ascent of renewed brass: warming key-lift, the clockwork motif
  gilded by fuller horns and harp arpeggios, stride widening; earned hope, still humble."
- **trial_pressure (TRIAL)** — "The trial: driving low-string and timpani engine on the
  void_pressure cell, brass stabs kept dry and close, the clockwork motif fighting to keep its
  feet; dense, effortful, survivable. JAZZ variant leads here."
- **beacon_approach (BEACON_APPROACH)** — "Approach to the cold Beacon: the beacon_resonance
  motif (B–C#–E–G#) veiled and low in cellos under a thinning, colder texture; awe and dread
  in equal measure, warmth almost audible inside the ice."
- **rekindle_siege (REKINDLE_SIEGE — the climax, gate A9)** — "The rekindling under siege: the
  beacon_resonance motif fighting upward through the void_pressure engine at full density —
  horns catching flame phrase by phrase while low brass and detuned metal press in; the
  clockwork motif small but unbroken at the center; peak intensity that grows warmer as it
  grows louder; no victory sting, the warmth IS the winning. JAZZ variant: 808 siege floor
  under the same brass battle."
- **vow_afterglow (AFTERGLOW)** — "Rekindled afterglow: the beacon_resonance motif open and
  warm at last, halved tempo, candle-lit orchestration of horns, harp and glass; the
  living_light figure allowed one full, sparing statement; gratitude, breath, the road
  opening. ORCH leads; loops back gently toward roam."

## Bridges (BRG_x — 12 short transitions)
> "A short 8–12 second instrumental bridge from [cue A mood] to [cue B mood]: hand off the
> active motif between sections, thin to a single held color, land on the destination cue's
> first harmony; seamless splice at both ends, no cadence sting."
Generate one per adjacent cue pair along the spine; name `BRG_<from>_<to>`.

## Ambient beds (ElevenLabs SFX v2 loops, `canon/ambient-layers.yaml`)

- **AMB-cosmic-void** — "the great quiet of a violet cosmos — a deep soft airless bed, distant
  slow nebula breath, faint glass overtones far away, seamless 10-second loop, wide and low,
  a foundation not a threat."
- **AMB-floating-ruins** — "wind crossing broken floating sandstone — dry granular dust drift,
  deep structural stone groans far apart, a hanging chain knocking twice a minute, loose
  pebbles trickling into the void, seamless 10-second loop, mid-wide."
- **AMB-clockwork-infrastructure** — "dormant observatory machinery at rest — very sparse deep
  gear settles, a slow pendulum somewhere below the floor, brass shells ringing faintly in
  wind, seamless 10-second loop, subtle, only where machines visibly exist."
- **AMB-sanctuary_bed (SANCTUARY, gate A8)** — "a sheltered hearth-pocket breathing — a small
  kept flame's soft flutter, warm brass lamp-shells ticking as they warm, cloth stirring, the
  pressure of the outside world audibly held at the threshold, seamless 10-second loop, close
  and warm and clearer-mixed than anywhere else; relief, not dead silence, not safety music."
- **AMB-pressure-encroachment** — "the cold closing in — the ruins bed thinning as detuned
  metal shivers rise, breath narrowing, density of small wrong household sounds gathering at
  the edges, seamless 10-second loop, surrounding; dread by density and friction, never a
  siren, never a tick."
- **AMB-beacon-proximity** — "standing before a great cold lantern — hollow brass shell
  resonance, ash-quiet, the faintest imprisoned warmth ringing when touched, seamless
  10-second loop, mid-close, reverent."
- **AMB-aftermath-release** — "after the siege, the island exhales — the pressure layers gone,
  warm ember-bed crackle from the rekindled crown, stone groans relaxing, the wind now merely
  wind, seamless 10-second loop, wide and gentle."
- **AMB-calibration-room / AMB-scrap-merchant** — workshop/hub interiors: "a small warm
  workshop at rest — bench tools settling, a kettle far from boiling, lamp-shells ticking,
  quiet brass wind-chime, seamless 10-second loop, close, domestic and kind." (Merchant
  variant: add "an abacus of brass beads sliding occasionally, satchels shifting.")

**Contradiction guard:** map labels like "First Wave", "final_boss_ascent", "death_screen_
respawn" from soundtrack-v2 sources are REJECTED relabels — trust cue ids + zone bindings above
(`extraction/soundtrack-v2-2026-07-04.md`).
