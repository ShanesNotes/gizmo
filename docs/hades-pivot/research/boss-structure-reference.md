# Boss structure reference — grounded research for Gizmo's first boss

Reference-only. No design decisions here — this exists to ground whatever the
principal agent designs for Gizmo's `boss_arena` room against how Supergiant
actually built Hades' first boss, and against this repo's existing FSM/director
seams. Every external claim below is cited (URL); every local-codebase claim
cites a path.

---

## 1. Megaera (first boss) anatomy

Megaera is the boss of Tartarus, the first biome, fought when the player
attempts to leave the region for the first time
([Fextralife wiki](https://hades.wiki.fextralife.com/Megaera);
[TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)).

### 1.1 Attack roster and phase gating

Megaera opens the fight with two attacks and gains two more as her HP drops.
Sources disagree slightly on exact damage numbers (patch-version-sensitive —
see §14 caveat in the local balance ref), but agree on the roster and gating
logic:

| Attack | Available from | Telegraph | Damage (as reported) | Notes |
|---|---|---|---:|---|
| **Lunge / Dash** | Fight start | She pauses/crouches briefly, then is "locked into her trajectory" once she crouches — the crouch *is* the tell | 13 ([Fextralife](https://hades.wiki.fextralife.com/Megaera)) | Dodge left/right; punishable immediately after with melee (she has recovery lag) ([TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)) |
| **Whip Whirl / Spinning Whip** | Fight start | Hand raised = wind-up cue, before she pulls out the whip and spins | 13–15 (sources vary) | Punishable with ranged attacks during her spin recovery ([TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)) |
| **Volley / Multiple Blast (Spiral Spark)** | Unlocked at **75% HP** (random order vs. Flame) | She floats with a dark aura, then fires a rapid projectile volley | 4 per projectile | First "ranged pressure" attack — introduces the need to break line of sight/kite ([Fextralife](https://hades.wiki.fextralife.com/Megaera), [TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)) |
</br>| **Flame / Firebomb** | Unlocked at **50% HP** (random order vs. Volley) | Pink/purple circles appear on the ground, then ignite into fire after a delay; some circles are deliberately placed *off* the player's current position to bait a dodge into the wrong spot | 8–9 per bomb | The one attack explicitly designed to punish reflexive (non-observant) dodging — you must read the mark, not just react to the boss ([Fextralife](https://hades.wiki.fextralife.com/Megaera), [TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)) |

Both new attacks are gated behind HP thresholds, but which one unlocks first
at 75% vs. 50% is randomized per fight — so the *set* of attacks by phase is
deterministic (2 → 3 → 4) but the *order of introduction* is not
([Fextralife](https://hades.wiki.fextralife.com/Megaera)).

### 1.2 Add-wave summons

Megaera periodically summons two enemy types, escalating at each HP
threshold:

- **Thugs** — described as slow and largely ignorable/low-threat.
- **Witches** — described as more dangerous; sources recommend prioritizing
  their kill.

Summon volume increases at **75%, 50%, and 25% HP** — sources describe it as
"doubling" at each successive threshold
([Fextralife](https://hades.wiki.fextralife.com/Megaera);
[TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)). This
means the add pressure and the attack-roster expansion share the *same*
threshold ladder (75/50/25%), giving the fight three clean escalation beats
rather than independent timers.

### 1.3 Arena, telegraphs generally, intro/defeat ceremony

- **Intro line:** "Ever stubborn, aren't you? Maybe my whip might make you
  reconsider whatever it is that you're attempting here."
  ([Fextralife](https://hades.wiki.fextralife.com/Megaera))
- **Defeat line:** "Impossible."
  ([Fextralife](https://hades.wiki.fextralife.com/Megaera))
- **Reward:** Titan Blood (Hades' boss-exclusive currency used for weapon
  Aspect upgrades) is the confirmed reward; the wiki source consulted did not
  document the door/ceremony sequencing in detail beyond that
  ([Fextralife](https://hades.wiki.fextralife.com/Megaera)) — flagged as a
  gap, see §6.
- General telegraph philosophy across Hades bosses/enemies (not
  Megaera-specific): "most enemies and bosses have a noticeable tell: before
  they attack, they stay frozen for several frames in a recognizable pose,
  and sometimes they even blink" — and the game is explicitly designed so
  "you never feel like the game is trying to trick you," despite dense
  simultaneous action on screen ([gamedesignskills.com via search
  synthesis](https://gamedesignskills.com/game-design/game-boss-design/); note:
  direct fetch of this page 403'd, this is search-snippet-sourced, treat as
  lower-confidence than directly fetched sources).

---

## 2. First-boss design principles (from Hades writeups)

1. **Megaera is explicitly a teaching tool, not just an obstacle.** She's
   fought early in a run with few boons/upgrades, and the fight is framed as
   validating "the Hades fundamentals... when to dodge, when to run, where to
   step, when to attack, and when to back off" before harder trials
   ([ScreenRant, via search
   synthesis](https://screenrant.com/hades-defeat-megaera-boss-guide/)).
2. **Small roster, clean escalation, not a firehose.** Four attacks total,
   introduced 2 → 3 → 4 across the fight, each with a distinct, readable tell.
   Contrast with a horde-shooter boss with a dozen attacks from the start —
   Megaera's design bets on depth-through-mastery of a small set, not
   attack-count breadth ([TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)).
3. **Every attack has a generous, distinct tell and a punish window.** The
   crouch-before-dash, hand-raise-before-whip, and mark-before-firebomb
   patterns all give the player enough lead time to read *before* reacting,
   and named sources explicitly identify the recovery window after Lunge and
   during Whip Whirl as free damage windows
   ([TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)).
4. **No pure reflex-punish attacks; one attack is a deliberate "read, don't
   react" test.** The Firebomb's off-position decoy circles are specifically
   designed to defeat players who dodge on reflex rather than reading the
   telegraph — this is the fight's one genuine skill gate above "dodge the
   obvious thing," introduced only at 50% HP once the player has already
   proven the basics ([Fextralife](https://hades.wiki.fextralife.com/Megaera);
   [TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)).
5. **Adds create a DPS-check / mechanics-check split within one fight.** The
   Thug/Witch summons force a triage decision (ignore the slow ones, prioritize
   the dangerous ones) layered on top of dodging the boss herself — mixing an
   add-management mechanics-check with the underlying boss DPS-check
   ([Fextralife](https://hades.wiki.fextralife.com/Megaera)).
6. **Difficulty for fresh players vs. veterans is handled by build state, not
   separate tuning.** Sources note Megaera is harder for beginners specifically
   *because* they face her with few boons/upgrades this early in the run —
   the same fixed boss stats read as a skill-check for a fresh player and as a
   formality for a built-up veteran. No source found describes Supergiant
   changing Megaera's own numbers between early access and 1.0 for difficulty
   reasons specifically (general early-access iteration is confirmed but not
   itemized — see gap below). Post-launch difficulty scaling for *repeat*
   clears is handled by the separate Pact of Punishment ("Heat") system layered
   on top of fixed boss encounters, not by re-tuning Megaera's base kit
   ([ScreenRant via search
   synthesis](https://screenrant.com/hades-defeat-megaera-boss-guide/); general
   early-access iteration confirmed generically at
   [DigiPen](https://www.digipen.edu/showcase/news/eduardo-gorinstein-delivers-challenge-and-fun-hades),
   no Megaera-specific tuning changes found in sources consulted — gap, see §6).

---

## 3. Phase-machine patterns for Godot, grounded in this codebase

No single canonical "Hades boss FSM" source diagram was found in the sources
consulted (gap — see §6); the pattern below is a generic phase-based-boss
structure synthesized from the attack/threshold behavior documented in §1,
translated into the seams this repo already has.

### 3.1 What a boss FSM must integrate with, as-built

**`EnemyBrain` (`/home/ark/gizmo-hades/godot/scripts/enemies/enemy_brain.gd`)**
is the current per-enemy contact-combat state machine:

- A 3-state attack cycle: `ATTACK_READY → ATTACK_WINDUP → ATTACK_RECOVERY →
  ATTACK_READY` (`enemy_brain.gd:4-6`, `enemy_brain.gd:120-142`), driven by
  `attack_windup`/`attack_recovery` timers configured per-enemy via
  `configure(stats: Dictionary)` (`enemy_brain.gd:19-27`).
- A single melee "in contact" trigger model: the attack only fires when the
  target is within `attack_release_radius` (`enemy_brain.gd:68`), i.e. one
  attack type, contact-range only, no multi-attack selection logic at all
  today.
- A `stagger(duration)` interrupt that resets the attack state and freezes
  movement/attack for a duration (`enemy_brain.gd:33-38`, `enemy_brain.gd:51-61`)
  — this is the only "interrupt an in-progress attack" mechanism that exists.
- `step()` returns a `damage_event` dict only at the windup→recovery
  transition (`enemy_brain.gd:130-135`), i.e. damage is dealt once per attack
  cycle at a fixed moment, not sampled continuously.

**A boss needs strictly more than this**: multiple attack *types* to choose
between (not just one melee loop), phase-gated attack-set expansion (§1.1),
and add-summon triggers — none of which `EnemyBrain` currently models. The
straightforward extension (not a design decision, just what the seam implies)
is a boss-specific brain that *wraps or composes* `EnemyBrain`-style
windup/recovery timing per attack, but adds an **attack-selection layer above
it**: given the current phase (an HP-threshold-derived enum) and cooldown/
readiness state per attack, pick which attack starts its windup next. That
selection layer is new; the windup/recovery/stagger primitives are reusable
as-is.

**`RoomDirector`
(`/home/ark/gizmo-hades/godot/scripts/room_graph/room_director.gd`)** is the
per-room wave/budget engine that spawns chaff/bruiser/elite adds against a
budget that scales with `difficulty_tier` (`room_director.gd:139-232`), and
exposes `notify_kill(spawn_id)` to track clears and advance waves
(`room_director.gd:112-137`). Per HADES-PARITY-SPEC.md §2 item 5, "boss
chambers end the loop, not the grammar" — a boss room's clear condition is the
boss's death, not a `RoomDirector` wave-budget exhaustion. This means a boss
fight's add-waves are a **second, boss-owned spawn concern**, distinct from
`RoomDirector`'s per-room budget model — whatever summons Thugs/Witches at
75/50/25% HP (§1.2) needs its own trigger (likely boss-FSM-driven, firing
discrete summon requests) rather than being folded into `RoomDirector`'s
continuous wave-budget math, since the *count* of adds is HP-threshold-gated,
not budget-gated. Whether that reuses `RoomDirector`'s
`ARCHETYPE_CHAFF`/`ARCHETYPE_BRUISER` spawn-request shape
(`room_director.gd:269-277`) or is a separate boss-scoped spawner is an open
design question for the principal (see §6).

### 3.2 Generic phase-machine survey (industry pattern, not this-codebase-specific)

Standard boss-FSM structuring described in generalist game-design material
(low-confidence source — direct fetch of
[gamedesignskills.com](https://gamedesignskills.com/game-design/game-boss-design/)
403'd; this is search-snippet-level, cross-checked against the Megaera
specifics in §1 which corroborate the same shape):

- **Phase thresholds keyed on HP percentage**, not elapsed time — matches
  Megaera's 75/50/25% gates exactly (§1.1–1.2).
- **Attack-set membership grows monotonically with phase** (2→3→4 attacks),
  never shrinks — old attacks stay available as new ones unlock.
- **Attack selection is typically weighted-random among the currently
  unlocked set**, with a same-attack-twice-in-a-row guard being a common but
  not universally documented convention (not directly confirmed for Megaera
  in sources consulted — flagged as inference, not a cited fact).
- **Add-spawn triggers piggyback on the same phase thresholds** rather than
  running on an independent timer — again matching Megaera's confirmed
  75/50/25% add-escalation (§1.2).

---

## 4. Boss telegraphs in a greybox world

Hades' telegraph vocabulary, as documented above, maps to three primitive
channels that read even with zero VFX budget:

| Hades convention (cited) | Greybox translation |
|---|---|
| "Frozen for several frames in a recognizable pose... sometimes they even blink" before attacking ([gamedesignskills.com via search synthesis](https://gamedesignskills.com/game-design/game-boss-design/), low-confidence) | A held/distinct **pose or scale pulse** on the boss mesh itself during windup — no animation clips needed, a `Tween` on scale/rotation over the `attack_windup` timer already present in `EnemyBrain`'s timing model (`enemy_brain.gd:13`) is sufficient |
| Dash tell = crouch, "she's locked into her trajectory" once committed ([TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)) | A **committed-trajectory indicator**: a flat ground decal/line primitive drawn from boss to target position during windup, since Godot greybox has no sprite budget for a "crouch" animation |
| Whip tell = hand raised before the swing ([TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)) | A **color-shift on the boss's mesh material** (e.g. emissive flash) timed to windup start, functioning as the "raised hand" analog without a rigged limb |
| Firebomb = pink/purple ground circles, timed delay before ignition, some circles deliberately off-position ([Fextralife](https://hades.wiki.fextralife.com/Megaera), [TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)) | **Flat colored circle/quad decals** on the ground (a primitive `MeshInstance3D` plane, no shader needed) that fill or brighten over the windup duration — directly portable to greybox since it's already a 2D-on-3D-floor primitive in the source material, not a particle effect |
| Volley = floating pose + rapid projectile stream ([Fextralife](https://hades.wiki.fextralife.com/Megaera)) | A **brief hover/rise on the Y-axis** as the sole readable cue, paired with projectile primitives (spheres) already needed for any ranged attack |

The common thread across all four Megaera telegraphs: **each uses exactly one
channel** (pose OR color OR ground-mark OR vertical offset), held for the
full windup duration, with no attack sharing a channel with another
concurrently-available attack. That "one channel, no overlap" discipline is
the actual transferable lesson for a shape/color/timing-only greybox — not
the specific art (whip-hand, purple fire) which requires rigging/VFX Gizmo's
boss doesn't have yet.

---

## 5. Scale sanity

Per the local balance reference
(`/home/ark/gizmo-hades/reference/game-balance-reference.md:329-339`):

```
Boss tier target TTK: 10–60s
BossHP(T) = ExpectedPlayerDPS(T) × TargetBossTTK(T)
```

At the stated current kit baseline of **110 sustained DPS**:

| Target TTK | Implied Boss HP |
|---:|---:|
| 10s (floor) | 1,100 |
| 20s | 2,200 |
| 30s (mid-band) | 3,300 |
| 45s | 4,950 |
| 60s (ceiling) | 6,600 |

The balance ref recommends using **P60/P70 player DPS** for normal bosses,
reserving P85/P90 for optional challenge bosses only
(`game-balance-reference.md:341`) — so 110 DPS should be treated as that P60–70
figure, not a floor/ceiling extreme, when deriving the final number.

**Reference-only observation, not a recommendation:** Megaera is Hades'
*first* boss and functions as a fundamentals check (§2.1) rather than a long
DPS-check fight — the sources consulted describe her roster and escalation
but none state her exact total HP number (§1, flagged gap), so no direct
Megaera-HP-to-Gizmo-HP mapping is possible from sources found. Structurally,
a first-boss position argues for landing toward the **lower-middle of the
10–60s band** (fundamentals-teaching, not an endurance test) with three phase
splits at 75/50/25% HP mirroring Megaera's threshold ladder (§1.1–1.2) — that
is the one directly-transferable structural fact, independent of the final
HP number, which is the principal's call.

---

## 6. Open design questions for the principal

1. **Add-spawn ownership**: should boss-phase add-waves (Thug/Witch analog at
   75/50/25% HP, per §1.2/§3.1) be issued through `RoomDirector`'s existing
   spawn-request shape, or does the boss need its own spawner separate from
   `RoomDirector` entirely, given HADES-PARITY-SPEC.md's note that boss rooms
   don't follow the reward/wave-clear grammar? (`room_director.gd:269-277`
   vs. HADES-PARITY-SPEC.md §2 item 5)
2. **Attack-selection algorithm**: weighted-random among the unlocked set with
   a no-repeat guard is the common industry pattern (§3.2), but that specific
   mechanism was not confirmed for Megaera in any source consulted — worth
   deciding deliberately rather than assuming.
3. **Reflex-punish attack placement**: Megaera's Firebomb is the sole
   "read, don't react" test and arrives only at 50% HP (§1.1, §2.4) — does
   Gizmo's boss want an equivalent single decoy-mechanic attack, and at which
   phase threshold, given the local kit has guard-pips rather than Hades'
   Defiance charges (HADES-PARITY-SPEC.md §3)?
4. **Total HP target**: no source gave Megaera's literal number, only phase
   percentages (§1.1, §5 gap) — the principal will need to pick a number in
   the 1,100–6,600 range (§5) without a first-boss anchor point from Hades
   itself; is there a reason to weight toward the low end (fundamentals
   teach) or does Gizmo's early-run kit (no boons yet, ADR references) argue
   otherwise?
5. **Ceremony/reward sequencing**: sources found document Megaera's intro/
   defeat lines and Titan-Blood reward (§1.3) but not the precise
   room-transition choreography (door timing, camera behavior) after a boss
   kill — is that ceremony sequencing already specified elsewhere in this
   repo (e.g. HZ-042/HZ-062 per HADES-PARITY-SPEC.md §2 item 5), or does it
   need fresh research?

---

## Sources consulted

- [Megaera | Hades Wiki - FextraLife](https://hades.wiki.fextralife.com/Megaera)
  — attack roster, HP thresholds, add summons, intro/defeat lines, reward.
- [Hades: How To Beat Megaera With Every Weapon — TheGamer](https://www.thegamer.com/hades-megaera-boss-fight-guide/)
  — telegraph detail, punish windows, damage numbers, add behavior.
- [Hades: How to Defeat Megaera (Boss Guide) — ScreenRant](https://screenrant.com/hades-defeat-megaera-boss-guide/)
  — first-boss-as-fundamentals-check framing, fresh-player difficulty context.
- [Boss Design: How to Make an Unforgettable Boss Battle — gamedesignskills.com](https://gamedesignskills.com/game-design/game-boss-design/)
  — generic telegraph/tell language ("frozen for several frames... blink");
  direct fetch returned HTTP 403, so this is search-snippet-sourced and
  flagged lower-confidence throughout §1.3, §3.2, §4.
- [Eduardo Gorinstein Delivers Never-Ending Challenge and Fun in Hades — DigiPen](https://www.digipen.edu/showcase/news/eduardo-gorinstein-delivers-challenge-and-fun-hades)
  — confirms Early Access playtesting drove iteration generically; no
  Megaera-specific tuning deltas found.
- [Hades Boss Guide: Furies (Megaera, Alecto, Tisiphone) — PC Invasion/Prima Games](https://primagames.com/gaming/hades-boss-guide-furies-megaera-alecto-and-tisiphone)
  — attempted for cross-boss escalation comparison; both the PC Invasion
  redirect and the direct Prima Games fetch returned HTTP 403/blocked, so no
  content from this source made it into the doc above. Left here as a
  known gap for a follow-up pass if Alecto/Tisiphone comparison becomes
  load-bearing for the principal's design.
- [Megaera - Hades Wiki - Fandom](https://hades.fandom.com/wiki/Megaera)
  — attempted for a cross-check on HP/reward detail; returned HTTP 402
  (paywalled), not consulted further.

Local codebase (this repo, cited inline above with line numbers):
`godot/scripts/enemies/enemy_brain.gd`, `godot/scripts/room_graph/room_director.gd`,
`docs/hades-pivot/HADES-PARITY-SPEC.md`, `docs/hades-pivot/creative-direction-saints.md`,
`reference/game-balance-reference.md`.
