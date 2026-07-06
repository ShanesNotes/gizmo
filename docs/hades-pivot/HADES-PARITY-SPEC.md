# Hades-parity spec — the design authority for the Gizmo rebuild

Authored 2026-07-05 by the Fable orchestrator, from first principles about how
Hades (Supergiant, 2020) is actually structured. **This document outranks every
other doc under `docs/hades-pivot/`** — where a slice doc, ticket, or scaffold
disagrees with this spec, this spec wins and the other artifact gets fixed.
ADR 0010 records the pivot decision; this records the target.

Reskin rule (from ADR 0010): Hades' **structure**, Gizmo's **fiction**. Every
Hades system named below gets a Gizmo-lore skin, and the lore mapping column is
a *proposal* until `gizmo-lore` ratifies it — mechanics don't wait on that.

---

## 1. The run skeleton

A run in Hades is: **hub → biome 1 → biome 2 → biome 3 → gauntlet → final boss →
(win or die) → hub.** Death and victory both return home, and the home trip is
where story advances. Gizmo maps onto this cleanly:

| Hades | Structure | Gizmo skin (proposal) |
|---|---|---|
| House of Hades (hub) | No combat; NPCs, meta vendors, weapon pick, mirror | The **Brass Sphere** — workshop/sanctuary |
| Tartarus | ~14 chambers, boss: Megaera | First shattered island region (HEARTH per region graph) |
| Asphodel | ~10 chambers, boss: Bone Hydra | Second region |
| Elysium | ~10 chambers, boss: Theseus & Asterius | Third region |
| Temple of Styx | Hub-and-spoke satyr tunnels, then final approach | Approach to the cold **Beacon** |
| Hades (final boss) | Single arena, two phases | The Beacon's guardian; **rekindling = victory** |
| Death → House | Bank persistent currency, spend, talk, go again | Death → Brass Sphere; bank Scrap; codex logs the run |

v1 scope: **hub + biome 1 + its boss**, full death-and-return loop. Biomes 2–3
are content expansion, not structural risk — the skeleton must support them
from day one (biome_id already threads through the room-graph scaffold; good).

**Chamber counts are pacing law, not flavor.** Hades runs ~35–45 minutes at
14+10+10 chambers with 1–3 minutes per chamber. v1 biome 1 = **8–12 rooms**
(tune inside that band), so a full v1 run lands at 15–25 minutes.

## 2. Room grammar

Each chamber in Hades is: **enter → doors seal → combat waves until clear →
reward materializes → doors open, each door telegraphing the NEXT room's
reward → player chooses → repeat.** The consequential structure:

1. **The door telegraph is the core run-building decision.** Before entering a
   room you see what it pays (boon symbol, currency, hammer, heart, shop).
   Route choice = build choice. This is why the room graph *must* branch —
   a linear chain offers no decisions, and Hades without door choice isn't
   Hades. **Correction to the slice-1 scaffold:** linear-chain-for-v1 is
   acceptable for the *first integration gate only*; branching (2 doors on
   most non-boss rooms) is **v1 scope, not post-v1** — it's HZ-level work,
   not an E-level deferral. The generator emits: each non-terminal room gets
   1–2 exits, each exit pre-assigned a reward type at generation time.
2. **Rewards are assigned to rooms at graph-generation time**, not rolled on
   clear — that's what makes the telegraph honest. `RoomNode` needs a
   `reward_type` field (boon, scrap, sparks, hammer-equivalent, heal, shop).
   The scaffold lacks this today — add it.
3. **Waves, inside rooms, are fine.** ADR 0003's "no wave language" was about
   the old island's player-facing WAVE x/5 framing. Hades rooms literally
   spawn 1–3 encounter waves; the player never sees a counter. Per-room
   director spawning waves until budget exhausted = correct reuse of the
   ADR 0003 pressure math (already scoped per-room by slice 1 — keep).
4. **Mid-biome fixtures:** each Hades biome has one shop (Charon) and one
   mini-boss/elite chamber minimum per run pass. Generator must guarantee
   placement, not leave it to weighted chance (Hades guarantees them too).
5. **Boss chambers end the loop, not the grammar.** Clearing a BOSS room emits
   run-completion instead of the reward/doors step; the boss room never reaches
   REWARDED. Victory rewards and the return-to-hub ceremony are the death/victory
   flow's job (HZ-042/HZ-062), not the room grammar's. (Resolved 2026-07-05
   during the HZ-002 audit — previously undocumented.)

## 3. The kit (numbers are law until tuned in-engine)

Hades' feel comes from specific timings. Targets, from the reference game:

- **Dash**: ~0.25s of movement with i-frames covering most of it; chainable
  (base 1 charge, meta-upgradable); **dash-cancel is the feel** — attack
  recovery cancels into dash at any point. The kit's state machine must allow
  `attack → dash` interrupt mid-recovery. If the scaffold's FSM blocks that
  (flat `attack → idle → dash` only), fix it — Hades without dash-cancel
  feels like mud.
- **Attack**: 3-hit combo, each stage cancelable into dash; combo window
  generous (~1s); no stamina, no cooldown.
- **Special**: separate button, no resource cost in Hades (the scaffold's
  `spark_charge` cost is a Gizmo-flavored deviation — acceptable, but tag it
  in the doc as a deliberate deviation, reviewable at feel-tuning time).
- **Cast**: in Hades this is **ammo-based, not cooldown-based**: 1–3
  bloodstones; fired stones lodge in enemies and return on kill/pickup.
  The scaffold made cast a cooldown — that's a **structural miss**, because
  bloodstone retrieval creates Hades' positional play (fire, kill, walk to
  reclaim). Rebuild cast as ammo-with-reclaim. Cooldown-cast is Hades II,
  not Hades.
- **Guard-over-HP (ADR 0007)** maps to Hades' Defiance (death-defiance
  charges) + healing scarcity. Keep guard as the Gizmo skin of that layer.

## 4. Boon economy

- **Rarity tiers: Common / Rare / Epic / Heroic**, plus **Legendary** (unique,
  prerequisite-gated) and **Duo** (two-god combos). v1: Common/Rare/Epic with
  the rarity field extensible; Heroic/Legendary/Duo are content, not schema.
  (The slice-3 scaffold's Common/Rare/Epic/Legendary is schema-compatible —
  keep, treat Legendary as gated content later.)
- **Boons attach to kit slots** — attack boon, special boon, cast boon, dash
  boon, plus passive slots. One slot, one god's boon; replacing is a choice.
  The scaffold's free-floating modifier list needs a `slot` field on BoonDef
  so slot-exclusivity is enforceable at draft time.
- **The draft**: 3 choices, one god per chamber-reward; rarity rolled per
  offer; a reroll resource exists in meta. Scaffold matches — keep.
- **Gods → boon-givers**: do NOT invent characters. The `domain` string field
  is the right seam; actual boon-giver identities are a `gizmo-lore`
  reconciliation note (queued, not blocking).
- **Currencies**: Sparks = run-scoped (Hades' Obols — spent at shops, lost on
  death); Scrap = persistent (Hades' Darkness/Gems — banked on death, buys
  meta upgrades). This assignment is now canon-proposed; ADR 0001's "distinct
  quantities" rule is preserved.

## 5. Meta-progression (the death loop)

Hades' loop: die → bank persistent currencies → spend on **Mirror of Night**
(permanent stat/ability nodes) → optionally deepen NPC story → new run plays
differently. Structural requirements:

- A **Mirror-equivalent**: a small tree/list of permanent upgrades bought with
  Scrap at the hub (the scaffold's `MetaState.boon_unlocks` covers pool
  expansion; add stat-grade purchases — e.g. +dash charge, +guard, +reroll).
- **Heat/pact-equivalent** (post-v1, schema-aware): difficulty toggles for
  repeat clears. Don't build; don't preclude.
- **Story-on-death**: the codex motif is the natural skin — each death writes
  a codex entry. Content later; the hook (RunLifecycle already emits the
  death event) exists now.

## 6. Camera & presentation

- Bounds-clamped soft-follow, hard cut between rooms (the corrected slice-1
  §2 is right — it was corrected *by this verification effort* and now
  matches the reference).
- Fixed high angle (~50°), no player rotation of the camera, ever.
- Gouache/painterly flat-lit look: Hades achieves it with hand-painted
  albedo + minimal dynamic lighting. For 3D: unshaded-leaning shaded
  materials, painterly textures (Meshy retexture passes against
  `ART_DIRECTION.md`), no realistic PBR response. Owned by
  `gizmo-design-system` (shader-matrix); this spec just fixes the target.

## 7. What this spec changes right now

Ordered corrections to existing artifacts (each is a ticket-sized fix):

1. **Cast → ammo-with-reclaim** (`godot/scripts/abilities/cast_ability.gd`):
   replace cooldown model with N-stone ammo + reclaim event. [structural]
2. **Dash-cancel**: verify/fix the FSM so attack recovery cancels into dash.
   [feel-critical]
3. **`RoomNode.reward_type`** + generator assigns rewards at generation;
   door telegraph reads it. [structural]
4. **Branching generator is v1**: 1–2 exits per non-terminal room, guaranteed
   shop + elite placement per biome. [scope correction to slice 1]
5. **`BoonDef.slot`** field + draft-time slot exclusivity. [schema]
6. Queue INDEX: fold 1–5 in as tickets; re-point HZ-031 (telegraph) at the
   generation-time reward model.

Everything not listed above survives verification as-built.
