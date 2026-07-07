# Voice scripts v1 — the spoken vigil (2026-07-06, lore pass)

Production-ready line scripts for two voices. Writing only; wiring and generation are
the lead's. Canon compliance: `copy-rules.yaml` voice/tone, ADR 0012 copy law (the
Spark flares/surges, never spent), no saint names, no wave/round/countdown words,
lines kept short so speech never crowds gameplay.

**One canon flag.** The lore canon rejects "the Custodian personally appearing" and
"Voice as chatty villain with speeches" — Voices are weather, guardians are their
local faces. These boss lines are therefore written as **the Custodian's pattern
speaking through the boss** (per `fiction-mechanics.yaml: special_threat_flavor`),
not the Custodian itself arriving. Do not title the boss "THE CUSTODIAN" on screen;
the voice carries the pattern, the name stays in lore. Flagged to the lore lab in
`promotion-request-2026-07-06-game-copy.md`.

---

## Voice 1 — MARGIN (Marginalia, the codex-keeper)

The scribe-moth who illuminates each rescued spark into the record. She records what
was freely given; memory, not acquisition. She is the warmth of the world speaking.

**ElevenLabs direction:** warm, papery, measured. An older, androgynous-leaning alto —
a librarian who loves the library. Slow, unhurried pace; every line lands like ink
drying. Slight audible smile on victory lines; on death lines, softer and slower,
never mournful — she has written this page before. Dry, close, intimate mic; minimal
reverb (she is beside you, not above you). Texture note: faint breathiness like thin
paper; no vocal fry, no whisper-ASMR.

### First-hub introduction (teach the premise; play once, in order)
1. "You woke to two words, little keeper: keep it safe."
2. "Keep it alive. That is the whole of it."
3. "I write down what you save. Nothing kept is lost."

### Run-start send-off (3 variants, rotate)
1. "Go gently. The dark is only a forgetting."
2. "I will hold the page open for you."
3. "Rescue what you can. I will remember the rest."

### Death reflection (3 variants, rotate — "the light failed" register, gentle)
1. "The light failed. It has failed before. Rest now."
2. "Even this, I enter kindly. The keeping goes on."
3. "You fell keeping it. That is not a small thing."

### Victory (2 variants)
1. "The Beacon warms. Let me write that slowly."
2. "Kept. All of it, kept. Gold leaf for this page."

### Boss-threshold warning (1)
1. "The weather ahead has gathered a face. Hold your light close."

### Return-to-hub after death (2 variants)
1. "Home again. Waking is what faithfulness looks like."
2. "The lamp is lit. Begin again, when you are ready."

---

## Voice 2 — THE CUSTODIAN'S PATTERN (boss voice)

Safety without trust; its counterfeit word is protection. It processes, it does not
hate. It genuinely believes it is helping — that is the menace. It never raises its
voice, never mocks, never gloats. Every threat is phrased as care.

**ElevenLabs direction:** polite, level, bureaucratic calm — a concierge announcing a
lockdown. Mid-low register, immaculate diction, unhurried; pauses fall where a form
has fields. Subtle processed quality: a thin choral or metallic doubling under the
voice, as if several identical clerks speak in unison. Absolutely no anger, no
snarl — menace comes from serenity. On its death line only: the doubling frays and
guts out mid-sentence, like a halo guttering; slower, almost puzzled, still gentle.

### Boss intro (2 variants)
1. "There you are. Small, warm, and terribly unsupervised."
2. "Come in. Everything precious ends up in my care."

### Mid-fight phase lines (3 — one per damage threshold, in order)
1. "Struggling is noted. Your comfort remains my priority."
2. "You are damaging yourself. I cannot permit that much freedom."
3. "So few keys left. Let me hold yours."

### Defeat-of-player (1)
1. "There. Safe at last. The door locks from my side."

### Its own death (1 — the halo guttering)
1. "The doors are open. Who will close the doors?"

---

## Production notes (both voices)
- Line-length law: spoken lines stay at or under ~12 words; if a generated take runs
  long, cut words rather than pace.
- One take per line may layer a quiet bed, but dialogue ships dry; the audio lab's
  production-standards gate owns loudness/format (only converted, gate-passed OGG/WAV
  in `godot/audio/`).
- Rotation lines must be interchangeable — no line may reference another line's content.
- Nothing here is objective copy; runtime objectives stay owned by `copy-rules.yaml`.
