# Boss design — THE CUSTODIAN (first boss, biome: hearth)

**Author:** Fable (principal), 2026-07-06 · **Grounding:** `research/boss-structure-reference.md`
(Megaera anatomy), `creative-direction-saints.md` (hyperscaler enemy order), balance ref §5.
**Naming:** "Custodian" is a greybox role-id. The lore canvas owns the true name; the fiction
seed is *counterfeit authority* — a warden process that mimics care while hollowing it
("machinery that has forgotten the people it was built for"). It does not hate Gizmo; it
processes him.

## Shape of the fight (Megaera pattern, transposed)
First boss = fundamentals exam, not endurance: teachable tells, no one-shots, one
read-don't-react test introduced only after basics are proven. Every attack has exactly one
telegraph channel; no two attacks share one.

- **HP 2,400** (≈22s pure-DPS at the 110-DPS kit; realistically a 45–60s fight with
  movement/phases — lower-middle of the 10–60s band per research §5).
- **Phase ladder at 75/50/25%** (1,800 / 1,200 / 600) drives BOTH attack unlocks and add
  waves (research: same-threshold ladder is the Megaera pattern).
- **No contact-damage chase loop.** The Custodian is deliberate: it repositions slowly and
  hurts only through attacks. All hits cost ≤2 guard pips. All telegraphs ≥0.8s.

## Attack roster (greybox telegraph language: ground markers + body tells)
| Phase | Attack | Behavior | Telegraph |
|---|---|---|---|
| 1 (100–75) | **Audit Sweep** | lunge along a line through the player's position; contact 2 dmg | body tilt + line marker on floor, 0.9s |
| 1 | **Compliance Ring** | radial pulse, radius 3.0, 1 dmg | expanding disc marker under boss, 0.8s |
| 2 (75–50) | **Overreach Slam** | AoE circle (r 2.5) at player's marked position, 2 dmg | filled circle marker, 1.2s |
| 2 | *adds wave 1* | 2 chaff | spawn telegraphs (existing windup) |
| 3 (50–25) | **Decoy Ping** | 3 circle markers; only the off-cadence one detonates (2 dmg) — the read-don't-react test | 3 discs, real one pulses off-beat, 1.4s |
| 3 | *adds wave 2* | 1 bruiser + 1 chaff | existing windups |
| 4 (25–0) | tempo ×0.8 cooldowns, no new attacks | *adds wave 3*: 2 chaff | endurance close |

**Attack selection:** weighted-random among unlocked attacks, no-immediate-repeat, per-attack
cooldowns (research: industry standard; exact Megaera algorithm unconfirmed — we choose this
deliberately).

## Architecture decisions (the researcher's open questions, answered)
1. **Add spawns are boss-owned, orchestrator-executed.** `BossBrain` emits
   `add_wave_requested(requests)` using the SAME spawn-request Dictionary shape RoomDirector
   uses (archetype, count, spawn_ids), so the orchestrator's existing spawn machinery
   (telegraphs, separation, kill ledger) is reused verbatim. RoomDirector itself is untouched
   — boss rooms don't follow wave/budget grammar (spec §2.5).
2. **`BossBrain` is an attack-selection layer above the windup/recovery idiom** — a new
   script (not an EnemyBrain replacement): phase machine (HP thresholds) → attack picker
   (weights/cooldowns/no-repeat) → per-attack execution states reusing windup→commit→recover
   timing. Boss body = new `custodian_boss.gd` (CharacterBody3D; not GreyboxEnemy — different
   vitals scale, no chase-contact), but it reports kills through the SAME `died(spawn_id)` /
   ledger contract so orchestrator bookkeeping is unchanged.
3. **Reflex-punish placement:** Decoy Ping at 50%, per research ("introduced only after
   fundamentals are proven").
4. **HP 2,400** with the phase splits above.
5. **Ceremony reuses the shipped path:** boss death → room clear → `run_completed` →
   victory end screen (HZ-042/062). Intro: doors seal (existing SEALED state), boss nameplate
   via Label3D + 1.0s camera hold on the boss (existing camera enter_room cut then hold —
   keep minimal; no cutscene system).

## Telegraph primitives (greybox budget)
One reusable `TelegraphMarker` scene: a flat disc/line mesh with exported color+shape+pulse,
spawned by attacks, freed on commit. Colors: warn amber for markers, off-beat pulse red for
the real Decoy. That single primitive covers the whole roster.

## Out of scope v1
Boss voice/copy (lore canvas), unique arena geometry beyond boss_arena.tscn greybox, Heat
scaling, post-boss biome-2 door (run ends at victory per spec §2.5).
