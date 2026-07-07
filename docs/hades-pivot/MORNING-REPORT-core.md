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

## IN FLIGHT / QUEUED
- Brief 3 (keepsake depth: pity math, Pattern's Bargain, reciprocal synergies,
  offer_flare signal) — brief written, launching post-wave-1.
- Brief 4 (input feel: 0.12s attack buffer, swing soft-lock) — brief written.
- Brief 5 (elite affixes shielded/frenzied/warded + PROTOCOL: QUARANTINE Pattern
  phase mechanic) — brief written.
- Backlog 8 (TTK balance pass) — after mechanics settle.

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
