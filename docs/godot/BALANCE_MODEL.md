# Balance model — Gizmo

How the generic [`reference/game-balance-reference.md`](../../reference/game-balance-reference.md)
(the Game Dev Balance Reference Artifact) maps onto Gizmo's *actual* mechanics in
`game-src-phaser/src/game/simulation.ts`. Use this when porting tuning to Godot
or rebalancing: the artifact gives the vocabulary and guardrails; this file says
which Gizmo system each rule governs and where the knob lives.

- Status: Living spec (adopted 2026-06-16, ADR-014)
- Anchors: artifact §-numbers below refer to `reference/game-balance-reference.md`.
- Source of truth for current values: `simulation.ts` constants. Numbers quoted
  here are snapshots — re-check the seed before trusting them.

## 1. Genre fit

Gizmo is a **bullet-heaven / survivors-like → use the artifact's horde-survival
preset (§13.1)**, with one twist: the run is short.

| Artifact axis | Gizmo (from `simulation.ts`) |
|---|---|
| Session unit (§0) | bounded run — `RUN_DURATION = 240` (~4 min), ends at "Storm Cleared" |
| Enemy scaling axis (§5.2) | **time + wave + elite** — `time.spawn`, `time.wave`, `nextEliteAt`, `eliteKills` |
| XP curve (§5.1) | piecewise per-level — `level`, `xp`, `nextXp` (confirm increment family when porting) |
| Active slots (§0) | upgrade ranks + evolutions — `UpgradeRanks`, `UpgradeEvolutions`, `cacheEvolutions` |
| Power spike (§8.1) | **Cache** crack = evolution/combo gate — `cachesOpened`, `catalystCaches`, `cacheEvolutions` |
| Recovery (§3.3) | `heart` pickup + Clutch saves — must stay capped (see §4 below) |
| Performance cap (§6) | live-enemy + projectile budget — enforce in the Godot presenter pools |
| Meta (§9) | none yet — keep run-only until the loop holds without meta (§12.1 step 9) |

## 2. Enemy tiers → TTK bands (§5.4)

Four `EnemyKind`s map onto the artifact's TTK bands (their fiction lives in
`design-handoff/NARRATIVE.md` §4). Tune kill-time-to-band, not raw HP in isolation.

| `EnemyKind` | TTK band (§5.4) | Design job |
|---|---|---|
| `nibbler` | Trash, ≤0.5s | dies to incidental AoE |
| `dasher` | Bruiser, 1–3s | forces brief target priority |
| `brute` | Elite, 3–10s | punctuation + build test |
| `warden` | Boss-ish, derive HP from DPS×TTK (§5.5) | sustained DPS + readability |

Elites arrive on a cadence (`nextEliteAt`); treat elite frequency as a §10.1
difficulty knob (medium-safe).

## 3. Damage buckets & the four economies

The artifact's bucket policy (§2.1) and proc/recovery budgets (§2.6, §3.3) are
the right lens for Gizmo's signature systems. The four economies share a shape —
*accumulate charge → cross a threshold → emit a burst* — which is exactly an
on-hit/proc budget problem.

| Economy | Knobs in `simulation.ts` (snapshot) | Artifact rule |
|---|---|---|
| **Surge** (gold) | `SURGE_MAX = 100`, `surgeCharge`, `surgeBursts` | burst = a *more* multiplier (§2.1); cap the charge so it can't loop |
| **Flow** (mint) | `FLOW_BURST_STEP = 144`, `FLOW_BURST_GROWTH = 42`, `flowBursts`, `FLOW_SAVE_*` | momentum/coverage; growth must not outrun §5.3 clear-pressure |
| **Echo** (violet) | `POWER_ECHO_COMMON = 4.6`, `POWER_ECHO_MAX = 9.2`, `ECHO_BURST_BASE = 12`, `echoCharge` | proc-coefficient territory (§2.6) — normalize against hit-rate |
| **Clutch** (cyan) | `closeCall`, `clutchBurst`, `FLOW_SAVE_RESTORE = 0.68` | near-miss recovery — falls under the recovery cap (§3.3) |
| **Boost / Snap** | `BOOST_BUFFER_TIME = 0.24`, `SNAP_BOOST_WINDOW = 0.46`, `BOOST_SCOOP_BASE_RADIUS = 92` | timing-gated; the player-skill lever, not an auto-multiplier |

**Double-dip audit (§8.3):** watch any stat that feeds *both* an economy's charge
rate *and* its burst size, or *both* coverage *and* per-target damage. Flow
(momentum → save → restore) and Boost (scoop radius → speed bonus) are the two to
watch first.

## 4. Recovery cap (§3.3) — load-bearing

`heart` pickups + Clutch saves + any leech must obey a global HP/sec cap, or fast
multi-hit play becomes immortal (§3.4, §11.3 leech-abuse test). The artifact's
PoE-style default is ~20% max HP/sec total, ~2%/instance. When porting recovery,
put the cap in data, not in the hit loop.

## 5. Upgrade offers & rarity (§7)

- `UpgradeRarity = common | uncommon | rare | epic` is the artifact's rarity
  ladder (§7.2): high common weight early, epics gated.
- Offers are weighted (§7.1) — when porting, keep weights + pity + anti-repeat in
  data so the offer-simulation test (§11.3) can run.
- **Pool-exhaustion check (§7.5):** a 4-minute run with frequent level-ups can
  out-draw the meaningful-pick pool. Caches/evolutions are the release valve.

## 6. Architecture: keep balance in a data table, not constants (deepening)

> Artifact §14: *"Keep source-of-truth balance values in data tables, not code.
> Every multiplicative exception needs an owner, a reason, a cap, and a test."*

Right now the knobs above are loose `const`s inside `simulation.ts`. That's fine
for the seed, but the Godot port should **not** copy that shape past a handful of
values. The deepening (architecture review candidate #2):

- Introduce a **`Balance` Resource** (`balance.tres` + a typed `balance.gd`) as the
  single tuning seam. `simulation.gd` reads from it; it never hard-codes a tuning
  number.
- The Resource's fields *are* the test surface — the §11.3 balance tests
  (leech-abuse cap, DoT/economy ramp, defense cap, offer simulation, spawn soak)
  attach to it directly.
- This is **recorded guidance, not built ahead of the learner** (teaching
  contract). Reach for the Balance Resource during co-development once the port
  has more than a few constants — likely around the economies/upgrades lessons,
  not the first movement slices.

## 7. Tuning workflow (§12) — the short version for Gizmo

1. Anchors: `D_melee_ST = 1.0`, `H_common_L1 = 1.0`.
2. Lock the TTK bands for nibbler/dasher/brute/warden (§2 above).
3. Lock economy/proc/recovery rules **before** tuning numbers (§12.1 step 5).
4. Build XP pace + spawn pressure together (§5.3) — a 4-min run is unforgiving of
   mismatch.
5. Tune for P50/P75 play, not perfect play (§12.1 step 8).
6. No meta until the run loop holds without it (§12.1 step 9).
