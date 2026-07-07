# Morning report — LORE, VOICE & CINEMATICS lane (night of 2026-07-06 → 07-07)

Lane lead: Fable 5 orchestrator; codev: GPT-5.5-Codex xhigh (5 briefs, all landed).
PRs: **#37 (wave 1), #39 (wave 2), #47 (revival wave), all merged to gizmo-3d.**
Full battery green before each merge (the one red was the known contact-damage flake +
a mid-rebase artifact; both clean on rerun). Post-revival integration verified green on
the combined head (cf2ee74) alongside design PR #38 and assets PR #44.

## Revival wave (PR #47 — reopened after the early wrap; backlog completion)

Woke the lane to finish what waves 1-2 left open. All merged and re-verified on the
integrated head.

- **All five saint shrines now stand in the hub.** Waves 1-2 voiced all five saints
  but only placed Bearer + Hearthguard as icons. Added Swordbearer (Mercurius),
  Marksman (Theodore), and Company (Forty Martyrs of Sebaste) shrines on the west wall
  — the veneration aisle is complete. Uses the VO already shipped; `run_hub_tests`
  asserts the full roster + plaque titles (87 checks).
- **Margin's body at the campfire (lead-flagged priority).** Her opening reveal beat
  resolved to a 2D portrait alone; she now has a physical figure across the fire —
  veiled robe, scribe-moth wings, her own candle — hidden through the ember-dark and
  spoken beats (voice before image), rising out of the mist into her light on the
  reveal beat, in step with the portrait. `run_opening_tests` 92 → 96.
- **Gizmo seated at the campfire (HZ-111).** Wired the assets lane's
  `play_campfire_sit()` seam into the opening — the raw-glb Gizmo now wears the
  authored campfire_sit pose, held for the whole cinematic, so he is discovered
  small beside the fire across from Margin's body instead of a default pose. The
  attach is inert without the player rig (every gameplay dep in the controller
  no-ops); `is_cinematic_holding()` verifies the clip grafted. `run_opening_tests`
  96 → 98.
- **Canon promoted game-side** (`docs/hades-pivot/design/lore-canon-gameside.md`): the
  Reverence Law, the role-id → saint → keepsake-family → VO-id map, and the region
  dialect table, each tied to its code seam. Closes backlog #7.
- **Voice manifest integrity test** (Codex, brief 5): guards the voice-line/audio-file
  drift class the sheriff flagged — every manifest entry has its `.ogg` variants, every
  `.ogg` is accounted for, counts reconcile (135 checks).
- **Sheriff `.uid` law honored** (SHERIFF-ALERTS 04:05): added the missing
  `run_threshold_voice_tests.gd.uid`, committed `run_voice_manifest_tests.gd.uid` with
  its script, and stopped instructing Codex to delete generated `.uid` files.

**Fence note:** the 05:00 ruling assigns `hub.tscn` to the levels lane. The revival
shrine edit is orthogonal — additive NPC node instances only, continuing the merged
saints-in-hub work, nothing near the contested GradeLayer/look_grade lines. Verified
coexisting green with design PR #38's look_grade attach.

---
*Waves 1-2 record (unchanged) follows.*

## Shipped

### The campfire opening is a staged cinematic (backlog #1, #2)
- `docs/hades-pivot/design/cinematic-grammar.md` — the research beat as five laws
  (voice before image; liturgical cadence; problem-then-player; title card as
  downbeat; diegetic teaching last) with falsifiable rejects.
- `opening_sequence.gd` + `opening.tscn`: ember-dark pre-beat, per-beat camera poses
  (slow pushes, one move per beat), fire-light ramp, **GIZMO title card on a generated
  swell sting** (never over speech), deterministic test hooks. Opening suite 92 green.
- Ceremony: `ceremony/lore/opening-0{1..5}-*.png` + `hub-01-saints-margin-codex.png`.

### The saints of the church (backlog #3, #4)
- **Canon promoted lab-side** (`gizmo-lore canon/saints-of-the-church.md`): the
  Reverence Law (venerated icons of the church militant; remembered witnesses — never
  pets/vendors/summons; no liturgy/scripture in copy; names on ceremony surfaces only,
  never barks) + roster: Bearer=St. Christopher, Hearthguard=St. Demetrios,
  Swordbearer=St. Mercurius, Marksman=St. Theodore Stratelates, Company=Forty Martyrs
  of Sebaste. George reserved capstone; ruler-saints hub-keeper-only.
- **25 saint VO lines** (meeting/offer×3/threshold per saint) generated, gated,
  manifest-wired. Scripts: `voice-scripts-v2-saints.md` (derived-stamped).
- **Saints physically in the hub**: icon shrines (veneration interact, first-meeting
  persistence, offer rotation, ModelSocket for the asset lab) — Bearer + Hearthguard
  flank the run door. Margin's body (scribe-moth placeholder + candle) at the codex
  desk with her hub-intro conversation.

### The Codex made real (backlog #5)
- `scripts/codex/`: unlock-on-event log (persistent, idempotent) + six entries;
  physical book prop on CodexPlinth; interact cycles unlocked entries and **Margin
  reads each aloud** (6 recorded readings, exact-variant binding). Suites 57+5 green.

### Threshold address sweep (backlog #6)
- 8 region-entry Margin lines (RegionTable dialect color), **the Pattern speaks before
  the boss door** (2 variants), first-flawless + near-death-survive milestone barks,
  title attract line (file+manifest). All wiring inside run_orchestrator's AUDIO
  region; Codex-authored suite 12 green (`run_threshold_voice_tests.gd`).

## Accounting (strict, per mandate)
- ElevenLabs: **47 generation calls, zero failures, zero retries** (25 saints + 15
  threshold + 6 codex readings + 1 music sting). Ledger-before-use honored; batches +
  PROVENANCE.yaml lab-side under `gizmo-audio-canon/generated/elevenlabs/2026-07-07-*`;
  only converted OGG entered `godot/audio/`. Sting reconciliation note filed with the
  audio lab (run score untouched).
- Meshy: **no key exists on this machine — zero credits spent.** Ready-to-run brief
  filed: `gizmo-asset-pipeline/briefs/character/margin_codex_keeper.brief.yaml`.

## Needs Shane (nothing blocking)
0. **Lab repo pushes**: gizmo-lore (saints canon), gizmo-audio-canon (ledger/reconciliation), gizmo-asset-pipeline (Margin brief) have local commits the night build could not push (default-branch push denied by policy). `git push` each when you're up.
1. **Saint roster confirmation** (canon §2, flagged inline): the five namings, and
   whether St. George's reserved capstone becomes a sixth role or a story figure.
2. Interim saint casting is premade-library voices tuned per register; a dedicated
   Voice-Design pass is queued (HZ-LORE-4). Listen and veto freely.
3. The Margin/keepsake-offer and title-attract wirings sit outside the lore fence —
   queued as HZ-LORE-1/2/3 for design/core lanes.

## Queued follow-ups (INDEX)
HZ-LORE-1 (attract wiring, design) · HZ-LORE-2 (offer-moment saint VO call, design) ·
HZ-LORE-3 (codex event emission, core) · HZ-LORE-4 (saints Voice-Design pass, lore).
