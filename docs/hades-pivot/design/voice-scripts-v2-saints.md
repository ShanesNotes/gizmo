# Voice scripts v2 — the saints of the church (2026-07-07 night, lore lane)

derived from lore canon; do not edit as source
(canon: gizmo-lore `canon/saints-of-the-church.md` — the Reverence Law and roster
govern; this file is the production script + manifest contract only.)

Register law (canon §3): ≤12 spoken words; sentence case; blessing/counsel/witness —
never combat quips, mechanics words, scripture, or liturgy; saints say "keeper", never
Margin's "little keeper"; the Company speaks only as "we". Role-title leads on cards;
the saint's name appears on ceremony surfaces (offer panel, codex, first meeting).

Line ids follow the manifest law (`<id>.ogg` single, `<id>_1..N.ogg` variants).
Playback seam: keepsake offer moment + thresholds via `play_voice_line`. Offer lines
rotate; meeting lines play once (first encounter flag is the design lane's; we ship
ids + files).

---

## the Bearer — Saint Christopher
*Casting: deep, slow, river-worn; few words; outsider gentleness.*

- `saint_bearer_meeting` (1): "I carried more than I knew. So will you, keeper."
- `saint_bearer_offer` (3):
  1. "Take this. The weight is how you know it matters."
  2. "Carry it gently. The river is long."
  3. "What you bear will bear you up."
- `saint_bearer_threshold` (1): "Deep water ahead. Set your feet, and cross."

## the Hearthguard — Saint Demetrios of Thessaloniki
*Casting: steady young-commander warmth; city-wall calm.*

- `saint_hearthguard_meeting` (1): "I kept a city once. Tonight I keep watch with you."
- `saint_hearthguard_offer` (3):
  1. "Hold this at the wall of your heart."
  2. "A guard is a promise. Keep yours whole."
  3. "Walls fall. Watchfulness does not."
- `saint_hearthguard_threshold` (1): "The gate ahead is cold. Stand as a wall stands."

## the Swordbearer — Saint Mercurius of Caesarea
*Casting: bright ringing steel; brisk, disciplined, kind.*

- `saint_swordbearer_meeting` (1): "A sword was given me once. I give you steadiness."
- `saint_swordbearer_offer` (3):
  1. "Strike once, truly. Twice is doubt."
  2. "Take it. Let your arm be honest."
  3. "Courage is a clean edge. Keep it clean."
- `saint_swordbearer_threshold` (1): "What waits ahead fears an honest blow. Go."

## the Marksman — Saint Theodore Stratelates
*Casting: measured, precise, quiet authority.*

- `saint_marksman_meeting` (1): "I faced the serpent unhurried. Learn that from me."
- `saint_marksman_offer` (3):
  1. "See first. Loose second. Nothing wasted."
  2. "Take the long view, keeper. It holds."
  3. "Aim is patience with a purpose."
- `saint_marksman_threshold` (1): "Mark what coils in the dark ahead. Then move."

## the Company — the Forty Martyrs of Sebaste
*Casting: small unison chorus, cold-air breath; always "we". Production: single take,
chorus-doubled in conversion (the Pattern's treatment, gentler settings).*

- `saint_company_meeting` (1): "We are forty. In the cold, we were one."
- `saint_company_offer` (3):
  1. "Take our warmth. It was kept for you."
  2. "None of us stood alone. Neither do you."
  3. "We held the night together. Hold with us."
- `saint_company_threshold` (1): "The cold ahead is old. We remember colder."

---

## Manifest contract (VOICE_LINE_MANIFEST additions — 25 lines)
`saint_<role>_meeting: 1`, `saint_<role>_offer: 3`, `saint_<role>_threshold: 1` for
roles bearer, hearthguard, swordbearer, marksman, company.

## Production notes
- Casting per saint is premade-library casting tuned per register (documented in the
  batch PROVENANCE.yaml); a dedicated ElevenLabs Voice-Design pass is a queued
  follow-up, not tonight's gate.
- Raws stay lab-side (gizmo-audio-canon generated/); only gate-passed converted OGG
  lands in godot/audio/voice/. Ledger before use; no-retry-spend on gate rejects.
- Threshold lines fire on region/door moments the run seam already owns; never during
  combat; the VoiceReserved one-at-a-time law handles collisions.
