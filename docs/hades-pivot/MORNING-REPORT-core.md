# MORNING REPORT — core lane (2026-07-07)

Lane: night/core · Fable 5 orchestrator + GPT-5.5-Codex (xhigh) codev.
Mission: run-loop depth and dopamine — damage numbers, spark-cast identity,
keepsake depth, Keeper Rank meta, input feel, elite/boss mechanics, HZ-107B.

## SHIPPED (merged to gizmo-3d)

### Wave 1 — PR #TBD
- **Damage numbers** (backlog 1): pooled `Label3D` pops (`scripts/fx/damage_numbers.gd`,
  NodePool cap 48, same-origin merge window). Tier language: normal white 64 /
  keepsake-boosted amber 84 / crit ember 110 / player-hit red. Crit flag plumbed
  end-to-end (lights up when keepsake crit ships). Proof:
  `ceremony/core/wave1-damage-numbers-tiers.png`.
- **Spark-cast identity** (backlog 2): visible ember bolt player→impact (28 m/s,
  fading trail), shard visibly LODGES and rides the living enemy, drops on death,
  walk-over + death auto-reclaim proven live. New SFX cue ids for the audio/lore
  lane: `cast_lodge`, `cast_reclaim` (manifest entries needed). Proof:
  `ceremony/core/wave1-spark-cast-lodged.png` (lodged flare + CAST pip 0).
- **Keeper Rank** (backlog 4): run tally → spark-shards (10/room, 1/kill,
  25/flawless, +150 victory); MetaState v3 (`lifetime_spark_shards` never
  regresses, spendable shards, v2 migration); Mirror grades purchasable with
  shards beside untouched scrap path. Run summary additive keys:
  `kills_total`, `flawless_rooms`, `spark_shards_earned`, `keeper_lifetime_shards`,
  `keeper_rank`, `keeper_rank_title`, `keeper_shards_to_next_rank`.
  Cross-fence seam flagged: app_shell.gd +13 lines (banking before save + keys).
- **HZ-107B deflaked** (backlog 7): root cause = load-dependent physics ticks per
  awaited headless frame (0 when fast, bursts under load) — why the gate was ~50%
  red in full batteries yet green solo. Clear-drive rebuilt frame-generous +
  presence-over-window; floor check tolerance −0.15.

### Wave 2 — PR #43
- **Keepsake depth** (backlog 3): rarity pity (weight ×(1+0.6·streak), hard pity
  at streak 3 guarantees an Epic+ slot), the Pattern's Bargain (25% roll reserves
  a costed Rare+ keepsake into the last offer slot + `bargain_offered` signal),
  three authored bargain keepsakes (The Pattern's Bargain / Counterfeit Shard /
  Borrowed Interval), reciprocal synergy pairs (ember_attack↔cast,
  gear_dash↔passive), `offer_flare(best_rarity)` for the UI lane to flare on.
- **Input feel** (backlog 5): 0.12s attack input buffer in AbilityComponent
  (attack-only by design — dash is the cancel and clears the buffer); commit-frame
  swing soft-lock (range ×1.15, ±60°) snapping motor facing to the nearest
  damageable enemy; swing_timing.gd remains the only timing truth.
- **PerfProbe tree gate** (backlog 7 stretch): `count_nodes()` public; damage-number
  flood asserts pool cap at the scene-tree level. Grok's "probe counts scene-tree
  nodes" item verified already-landed.
- Sheriff 04:05 uid ruling: complied; also carried the missing sidecars for lore
  lane's `codex_book.gd` / `_probe_lantern_grip_proof.gd`.

### Wave 3 — PR #45
- **Elite affixes** (backlog 6): seeded one-affix roll on elite spawns.
  Shielded (35% overshield, absorbs first, no stagger while up, break pop +
  `elite_shield_break` cue, muted grey-blue absorb pops) / Frenzied (+40% speed,
  −25% windup, −20% hp, warm pulse) / Warded (half damage while a living ally is
  within 6m — target-priority puzzle, violet). Proof:
  `ceremony/core/wave3-elite-affix-tints.png` (all three tints on the real model).
- **PROTOCOL: QUARANTINE** (backlog 6): THE PATTERN phase 3+ seals the player's
  arena quadrant behind telegraphed damage boundaries for 6s + a chaff-pair add
  wave; pure quadrant math, lifts on expiry/boss death/teardown. Cues:
  `pattern_quarantine_seal`, `pattern_quarantine_lift`.

### Wave 4 — final
- **Affixed-elite TTK gates** (backlog 8): real-melee-kit TTK bands now assert
  shielded 7.7s / frenzied 4.4s / warded-isolated 5.56s inside the elite 3–10s
  band, warded-under-ward ≤15s sponge ceiling, and the frenzied<base<shielded
  ordering. A careless retune of kit damage or elite hp trips red.

## BACKLOG STATE
All eight night-backlog items landed (1–8). HZ-107B fully closed: integration-gate
frame-pacing flake + the survivability-probe margin flake (median-of-3) + both
Grok stretch items.

## NEEDS SHANE
- Mirror currency: shards added as a PARALLEL purchase path (scrap untouched).
  Collapse to one currency is a data-only change — your call.
- Keeper rank titles are placeholder-canon (Cold Chassis → Keeper of the First
  Spark); lore lane should bless or recast.
- `cast_lodge` / `cast_reclaim` cues need audio manifest entries (lore/audio lane).

## PROCESS NOTES
- Ceremony playbook addition: MCP screenshots of sub-second FX — freeze
  `scene_tree.paused = true` in the same run_script as the trigger, hide
  PauseMenu, shoot, resume. Beats the round-trip race cleanly.
- Battery discipline: never run suites while Codex is mid-edit in the worktree;
  mid-edit signature changes read as mass failures.
