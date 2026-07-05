# 05 — Voices (ElevenLabs Voice Design + TTS)

`derived from ecosystem canon; do not edit as source`

Law (`gizmo-audio-canon/reference/elevenlabs-character-voices.md`): **Voice Design originals
only — no voice cloning (IVC/PVC rejected), no living-person likeness.** Gizmo and the swarm
are **wordless** — never TTS'd; their sounds live in `03-sfx-elevenlabs.md`. The Four Voices of
the Hush are a **SFX lane**, not conversational TTS. Line copy obeys lore microcopy law:
sentence case, warm/ceremonial/concise, max one exclamation per payoff.

## Voice Design prompts (verbatim canon)

### VOX-marginalia (narrator; the Codex's "hand")
> A small, warm, feminine storyteller's voice with a dry, knowing smile in it — a meticulous
> archivist who loves what she records. Light and papery in texture, precise consonants like a
> nib on vellum, unhurried ceremonial pacing, quiet amusement at the edges, gentle
> lower-register warmth on solemn lines. Intimate close-mic reading, as if annotating a margin
> by lamplight. No breathiness, no theatrical bombast.

Audition lines (TTS test copy, canon-safe):
- "Entry the first: he was never finished. That, I think, is why he began."
- "Keep it safe. Keep it alive. The Summons asked no more, and no less."
- "The Beacon warms. Write that down twice."

### VOX-wick (Sanctuary companion, lamp-tender)
> An elderly, gentle, androgynous caretaker's voice with a faint metallic warmth, like a kind
> voice heard through a brass lamp housing. Slow, patient, slightly creaky delivery with soft
> mechanical breath between phrases; low volume, close and calm; every word deliberate, as if
> each one is set down carefully. Never cold, never synthetic-robotic, never booming.

Audition lines:
- "Rest the light a moment. The cold will wait; it always does."
- "Your guard will gather back. Guard returns. Wounds, little keeper, are only carried."
- "When you go, take the warm side of the road."

### VOX-rote (stalled care-automaton, redeemed swarm-kin)
> A small, halting, well-meaning mechanical voice that keeps almost finishing sentences —
> earnest, slightly out-of-date diction, warm despite a ticking hesitation, like a music-box
> tutor that loops its favorite kindness. Light rasp of a worn gear under the vowels. Sincere,
> never comic-relief zany, never sinister.

Audition lines:
- "I was made to help with — to help with. I was made to help."
- "You keep it the old way. By hand. I remember hands."
- "Go careful. Go careful. Go."

## The Four Voices of the Hush (SFX-lane presence beds — generate via SFX v2, not TTS)

- **VOX-custodian (the Fold — safety without trust)** — "a vast, muffled, endlessly patient
  hushing — like a building-sized parent saying shh through concrete; no words, pressure of
  care." Bed spec: seamless 10-second loop, sub-heavy, surrounding, arrested and still.
- **VOX-arc (the Glare Shoals — knowledge without consent)** — "dry cascading whisper of a
  million pages turning themselves; indexing clicks; a question never asked." Bed spec:
  seamless loop, papery high-band lattice, cold full-saturation clarity with zero warmth.
- **VOX-familiar (the Hearthless Rows — help without honesty)** — "a too-close, too-smooth
  helpful hum that finishes your movements before you make them; doorbell warmth a
  quarter-tone wrong." Bed spec: seamless loop, intimate and slightly ahead of the beat.
- **VOX-axiom (the Colloquy — truth without love)** — "a single sustained perfect tone that
  proves itself forever, cathedral-cold, achingly in tune with nothing alive." Bed spec:
  seamless loop, one immaculate unison, menace by perfection not by dissonance.

All four must be reversible under Rekindled warmth (X-L3) — generate a matching "thawed"
variant of each bed: same material, warmed, slowed, humanized by imperfection.

## Runtime copy pool (for Marginalia/Wick TTS passes — lore-gated, N8)

Objective/ceremony lines only; never wave/timer/retry language:
"Reach the Beacon." · "Rekindle the Beacon." · "Hold until the Beacon warms." · "Return to
Sanctuary." · "The cold closes in." · "The swarm gathers." · "Beacon Rekindled." ·
"Gizmo's light failed."
