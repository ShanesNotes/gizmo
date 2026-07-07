# The presentation moat — what Hades does that Gizmo doesn't yet

**Author:** Fable (lead), 2026-07-06 night, on Shane's interrogation. This is the gap
analysis and the plan of record; the strike team's second slices execute the near half.

## The one-line answer
Hades' moat is not its combat — it's that **the world constantly addresses the player.**
Every threshold is a presented, voiced, framed *moment*: the god appears and speaks, the
chamber reveals itself, death is a sequence, the house remembers you. Gizmo has the
systems (rooms, boons, boss, score) but almost no *address*. Presentation is the moat,
and voice is its deepest water.

## Gap inventory (Hades beat → our state → the fix)
| Hades beat | Gizmo today | Fix (owner) |
|---|---|---|
| Chamber entry: door opens, camera settles, reward glints | teleport-cut | room-entry camera settle + door-unlock shine (fable-look, slice 2) |
| God appears + SPEAKS on boon offer | bare card UI | benefactor presentation pass (queued, needs benefactor voices — phase 2 of voice plan) |
| Death: red wash → Styx → house, narrated | instant overlay | ink-dark fade (look slice 2) + Margin death lines (voice lane) |
| Narrator + character voices everywhere | silence | **THE VOICE OF THE VIGIL** (below) |
| Run start: bedroom exit, taunt, send-off | door tap | Margin send-off line + hub intro (voice lane) |
| Boss: named intro, mid-fight barks | nameplate + music cut | Custodian voice: intro/phase/kill lines (voice lane) |
| First-time onboarding: the house teaches you | nothing | Margin first-hub introduction (voice lane, first-boot flag) |
| Fine grain: pickup glints, clear chimes, dust | partial (feedback kit) | room-clear sting (audio slice 2), pickup polish (queued) |

## THE VOICE OF THE VIGIL — ElevenLabs at full potential
Two voices ship first (scripts: fable-lore; generation + wiring: the lead, tonight):
1. **MARGIN, the codex-keeper** — the narrator. Warm, papery, measured; the one who
   "enters it in the Codex." Speaks at: first hub (onboarding), run start (send-off
   variants), death (gentle reflection variants), victory, boss threshold, hub return.
   Margin is our Storyteller — the address that makes the player *kept company*.
2. **THE CUSTODIAN** — polite, hollow, bureaucratic menace. It processes; it does not
   hate. Intro, one line per phase threshold, player-kill line, and its own death — the
   halo guttering out.
Phase 2 (queued, not tonight): benefactor voices on boon drafts (five role-voices —
the Bearer, the Hearthguard, ... — pending lore-canvas name promotion), Gizmo's own
non-verbal chirps (synthesized, not EL), codex entries read aloud.
Infrastructure: the VoiceReserved bus (waiting since HZ-104) + AudioDirector
play_voice_line seam with music ducking (fable-audio, slice 2). All generations through
the audio lab's ledger/provenance law; demo-provisional pending loudness gates.

## Moat verdict
Our moat ≠ out-Hades-ing Hades on content volume. It is: **the vigil frame** (you keep
a light; the world enters what you do in a book), **the dual-variant score** reacting
as world-state, and **the warrior-saint benefactor order** once promoted. Presentation
makes those legible; voice makes them felt.
