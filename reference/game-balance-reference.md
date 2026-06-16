# Game Development Balance Reference Artifact

**Use case:** ARPG / action-roguelike / horde-survival combat systems.  
**Format:** lookup tables, formulas, guardrails, and tuning workflow.  
**Anchors:** `D_melee_ST = 1.0`; `H_common_L1 = 1.0`. All values are relative ratios unless noted.

---

## 0. One-Page Balance Card

### Core rules

| System | Default | Reason | Danger if changed |
|---|---:|---|---|
| Additive stat bucket | `1 + Σ increased` | controllable growth | weak stats if overfilled; runaway if split too much |
| Multiplicative stat bucket | `Π(1 + more_j)` | build-defining spikes | permanent exponential scaling |
| Crit EV | `1 + p × (m - 1)` | smooth expected DPS | 100% chance cap creates multiplier-only endgame |
| Projectile transform | same projectile after fork/chain/split | blocks free boss shotgunning | boss TTK collapses by projectile count |
| AoE / aura | low ST, high pack DPS | rewards density play | can trivialize horde if range + proc scale unchecked |
| Recovery | per-hit allowed, global rate-capped | prevents immortality loops | fast AoE hits become infinite sustain |
| Defense | multiplicative layers, capped within layer | each layer matters, none reaches invincible | uncapped DR/resist breaks damage model |
| Enemy ramp | time/stage for horde; level/area for ARPG | matches genre loop | slow-level player can be softlocked if axes mix poorly |
| Slots | cap active build slots | creates specialization | no cap = soup builds and pool exhaustion |
| Meta power | bounded additive or consumed by higher difficulty | preserves early run tension | maxed meta trivializes starts |

### Master formulas

```text
HitDamage = Base
          × (1 + Σ increased)
          × Π(1 + more_j)
          × CritEV
          × Type/Ailment/Target multipliers
          × MitigationAfterPenetration

CritEV = 1 + critChance × (critMultiplier - 1)

DPS_ST = HitDamage × hitsPerSecond × uptime × accuracy × targetAvailability

DPS_pack = Σ over enemies hit per second:
           HitDamage_i × hitRate_i × coverage_i × procCoefficient_i

EHP = HP / Π(1 - mitigationLayer_i)

ArmorDR_rational = Armor / (Armor + k)
DamageTaken = Incoming × Π(1 - DR_i) × (1 - ResistAfterPen)

BossHP(T) = ExpectedPlayerDPS(T) × TargetBossTTK(T)

SpawnPressure(T) = spawnRate(T) × enemyEHP(T)
ClearPressure(T) = playerPackDPS(T) × practicalCoverage(T)
```

### First implementation defaults

| Knob | Horde-survival default | ARPG default |
|---|---:|---:|
| Session unit | 20–30 min run | campaign / map / dungeon |
| Enemy scaling axis | time + stage | area level + difficulty tier |
| XP curve | piecewise-linear increment → quadratic total | polynomial or geometric total |
| Active slots | 6 weapons + 6 passives style | gear slots + skill links/tree |
| Power spike | evolution/combo gate mid-run | item/skill breakpoint |
| Boss HP ratio | ~25× trash starting point | derive from area DPS and TTK |
| Recovery cap | ~20% max HP/sec baseline | class/item-modified cap |
| Performance cap | hard live-enemy cap + spawn queue | encounter budget + AI budget |

---

## 1. Notation & Data Model

### 1.1 Standard variables

| Symbol | Meaning |
|---|---|
| `D_melee_ST` | baseline single-target melee sustained DPS = `1.0` |
| `H_common_L1` | baseline level-1 common enemy HP/EHP = `1.0` |
| `p` | crit chance, clamped to `[0, 1]` unless overcrit exists |
| `m` | crit multiplier, e.g. `2.0` for double damage |
| `APS/CPS` | attacks or casts per second |
| `uptime` | fraction of time effect is active / target is hittable |
| `coverage` | fraction of relevant enemies actually hit by AoE/delivery |
| `procCoeff` | multiplier applied to on-hit trigger chance/effect/duration |
| `k` | soft-cap constant for rational curves |
| `T` | run time, wave, area tier, or target tuning moment |

### 1.2 Skill data schema

Every skill should resolve from explicit fields, not hidden exceptions.

```yaml
skill:
  id: fire_orb
  tags: [fire, projectile, direct, spell]
  delivery: projectile        # melee, projectile, beam, aura, orbit, ground, summon, nova
  damage_type: fire           # physical, fire, cold, lightning, poison, void, holy, true
  base_coeff: 0.85            # relative to D_melee_ST
  hit_rate: 1.2
  target_model: single        # single, pierce, chain, cone, area, aura, random
  target_cap: 1
  same_projectile_rule: true
  shotgun_allowed: false
  proc_coeff: 1.0
  dot_model: none             # none, highest_only, independent, shared_counter, refresh_replace
  crit_allowed: true
  scaling_tags: [spell_damage, fire_damage, projectile_damage]
  boss_effectiveness: 1.0
  crowd_effectiveness: 1.0
```

### 1.3 System tags

| Dimension | Examples | Balance impact |
|---|---|---|
| Damage type | physical, fire, cold, lightning, poison, void, holy, true | mitigation, ailment, resistance, tags |
| Delivery | melee, projectile, aura, orbit, ground pool, summon, beam, nova | coverage, range, proc rate, CPU load |
| Stack model | none, highest-only, independent, shared-counter, refresh | attack-speed value, boss ramp, abuse risk |
| Targeting | nearest, random, priority, cone, chain, pierce, split | player agency, pack clear, boss reliability |
| Inheritance | player stats, minion stats, snapshot, dynamic | exploit potential and build readability |

---

## 2. Damage & Power Scaling

### 2.1 Bucket policy

| Bucket | Formula | Put here | Budget note |
|---|---|---|---|
| Flat/base | `Base + flatAdds` | weapon base, skill base, flat element | strongest early; scales all later buckets |
| Additive increased | `1 + Σ inc_i` | most level-up stats, generic damage, type damage | safe main bucket; diminishing relative value |
| Independent more | `Π(1 + more_j)` | capstones, evolutions, rare uniques | scarce; every source multiplies all others |
| Crit EV | `1 + p(m-1)` | crit chance/damage | chance caps; multiplier keeps scaling |
| Speed | `hits/sec` | attack/cast frequency | directly scales hits and independent DoTs |
| Coverage | `targets/sec` | AoE, chain, pierce, aura, area | main horde multiplier |
| Proc | `procCoeff × chance` | on-hit effects | required to normalize fast/multi-hit skills |
| Mitigation | target-side | armor, resist, DR, vulnerability | must be applied after pen/shred policy |

### 2.2 Marginal value checks

```text
Additive +x% relative gain = x / (1 + currentAdditiveSum)
Multiplicative +x% relative gain = x
Crit chance +Δp gain = Δp × (m - 1) / CritEV
Crit mult +Δm gain = p × Δm / CritEV
Attack speed +x% gain = x, unless animation breakpoints or cooldown floors apply
Area radius +x% gain ≈ (1 + x)^2 - 1, if enemies fill the area
```

### 2.3 Archetype coefficient matrix

| Archetype | Base coeff | Strong axis | Weak axis | Guardrail |
|---|---:|---:|---:|---|
| Melee + bleed | `0.9–1.1` hit | `DPS_ST 1.2–1.6` | `DPS_pack 0.9–1.3` | range risk must pay damage premium |
| Physical projectile | `0.8–1.0` | `DPS_pack 1.5–3.0` | `DPS_ST 0.8–1.1` | same-projectile + less-damage tax |
| Fire + burn | `0.7–1.0` hit | `DPS_ST 1.3–2.0` | delayed output | highest-only burn unless boss ramp desired |
| Damage aura | `0.3–0.5/tick` | `DPS_pack 2.0–5.0+` | `DPS_ST 0.3–0.6` | proc coefficient + radius cap |
| Blizzard / slow AoE | `0.2–0.4` | control + pack | low ST | CC budget tax |
| Poison DoT | `0.4–0.7/sec/stack` | ramped `DPS_ST 2.0–4.0` | delayed / cleanseable | stack, duration, and application caps |
| Lightning chain | `0.7–1.0` | `DPS_pack 1.8–3.5` | target cap | decay per jump or hard chain cap |

### 2.4 Projectile laws

| Rule | Default |
|---|---|
| Fork/chain/split identity | transformed projectile is still the same projectile |
| Same-target repeat | disallow for same projectile path |
| Pierce | can hit multiple distinct targets; one hit per target per projectile |
| Chain | target cap + optional `0.7–0.9×` decay per jump |
| Extra projectiles | apply less-damage tax or only improve coverage |
| Shotgunning | opt-in only for explicit explosive/AoE overlap skills |
| Returning projectiles | apply large less-damage tax unless designed as core identity |
| On-hit procs | use `procCoeff`; never let procs recursively trigger themselves by default |

### 2.5 DoT / ailment models

| Model | Formula sketch | Attack speed value | Best use | Failure mode |
|---|---|---:|---|---|
| Highest-only | `max(activeDPS_i)` | low after uptime | burn/ignite, horde spread | duration becomes dead stat |
| Independent stacks | `Σ activeDPS_i` | high | poison/bleed boss ramp | unbounded with hit rate + duration |
| Shared counter | `base × f(stacks)` with decay | medium | affliction/corruption | hidden math unreadable |
| Refresh/replace | latest overrides old | low/medium | simple debuffs | anti-synergy with fast weak hits |
| Stack cap | `min(stacks, cap)` | medium until cap | readable ramp | cap too low feels fake |

Recommended DoT defaults:

| Game emphasis | Recommended model | Reason |
|---|---|---|
| Boss-centric | independent stacks + visible cap/decay | rewards sustained application |
| Horde-clear | highest-only + proliferation | prevents boss abuse |
| Casual readability | shared visible stacks | easy UI, easy tuning |
| PvP / competitive | refresh/replace or low cap | avoids invisible burst debt |

### 2.6 Proc / on-hit budget

```text
ExpectedProcsPerSecond = hitRate × targetsHit × procCoeff × triggerChance
ExpectedProcDamage = ExpectedProcsPerSecond × procDamage × procUptime
```

Guardrails:

| Risk | Fix |
|---|---|
| fast multi-hit skill triggers too often | `procCoeff < 1.0` |
| AoE hits 30 enemies and heals/procs 30 times | global per-second cap or target-count scaling |
| proc triggers another proc | no recursive procs by default |
| low-chance huge proc creates unfair spikes | internal cooldown, pity smoothing, or lower variance |
| summons multiply proc count | minion-specific proc coefficients |

---

## 3. Defense, Sustain & One-Shot Control

### 3.1 Defense layer stack

| Layer | Formula | Cap policy | Notes |
|---|---|---|---|
| HP | raw pool | none / bounded by item budget | best vs one-shots |
| Armor | `Armor / (Armor + k)` | asymptotic | constant marginal EHP if tuned like Brotato |
| Resist | `1 - clamp(res - pen, min, cap)` | hard cap | cap commonly `75–85%`; overcap handles shred |
| Dodge/evasion | `1 - Π(1 - d_i)` | cap below 100% | stochastic; bad as sole defense |
| Block | `chance × blockValue` | chance/value caps | use vs burst if readable |
| Generic DR | `Π(1 - DR_j)` | multiplicative | never additive to 100% |
| Barrier/shield | temp HP + recharge delay | delay reset on hit | strong vs burst, weak vs chip |
| Recovery | regen/leech/on-hit | global/sec cap | must not scale linearly with enemy count forever |

### 3.2 EHP examples

```text
Incoming = 100
ArmorDR = 40%
Resist = 50%
OtherDR = 20%
DamageTaken = 100 × 0.60 × 0.50 × 0.80 = 24
EHP multiplier = 100 / 24 = 4.17×
```

### 3.3 Recovery cap policy

| Recovery type | Scaling input | Default cap | Why |
|---|---|---:|---|
| Life leech | damage dealt / hit instances | ~20% max HP/sec | normalizes AoE and high APS |
| Life on hit | hit count | hard HP/sec cap | stops machine-gun immortality |
| Regen | time | lower but reliable | safe baseline sustain |
| On-kill | kill rate | uncapped or soft-capped | horde-friendly, boss-weak |
| Shield recharge | time since hit | delay-based | rewards dodging / spacing |
| Potion/flask | charges or cooldown | encounter budget | burst recovery with economy lever |

### 3.4 One-shot vs sustain tuning

| Problem | Symptom | Fix |
|---|---|---|
| sustain too strong | player survives all chip damage | lower recovery cap; add anti-leech enemies; add burst tests |
| one-shots too common | deaths from full HP in <0.5s | raise HP, telegraph, add max-hit clamp, reduce stacking damage mods |
| dodge too swingy | deaths feel random | entropy/pity dodge, lower enemy burst, add block/armor baseline |
| barrier immortal | recharge starts during combat | enforce delay and interruption |
| armor mandatory | non-armor builds unplayable | add armor alternatives and damage-type diversity |

---

## 4. Crowd Control & Utility Budget  **[Gap Fill]**

CC is power. Treat it as an output budget, not flavor.

### 4.1 Control score

```text
ControlScore = strength × uptime × areaCoverage × targetImportance × bossEffectiveness
```

| CC type | Strength guide | Tax damage by | Boss policy |
|---|---:|---:|---|
| Slow/chill | low-medium | `10–30%` | full or reduced |
| Root | medium | `20–40%` | short duration / reduced |
| Stun/freeze | high | `40–70%` | heavy reduction or stagger meter |
| Knockback | variable | positional tax | resist on elites/bosses |
| Vulnerability/shred | offensive CC | treated as multiplicative damage | cap or diminishing return |

### 4.2 Diminishing return models

```text
RepeatedHardCCDuration = baseDuration × targetCCEffectiveness × DR_n
DR_n examples: 1.0, 0.5, 0.25, immuneWindow
```

Use hard CC DR on elites and bosses. Use soft CC at reduced effect instead of immunity when possible.

---

## 5. Progression, XP & Enemy Scaling

### 5.1 XP curve families

| Family | Formula | Best for | Feel |
|---|---|---|---|
| Piecewise linear increment | `XP_to_next += c_band` | 20–30 min survivor run | fast early, steady late |
| Quadratic total | `TotalXP ≈ aL² + bL` | bounded sessions | predictable level pacing |
| Polynomial | `XP(L) = aL^b` | ARPG leveling | flexible steepness |
| Geometric | `XP(L) = ar^L` | long tail / prestige | steep late grind |
| Zone penalty | reward scaled by level gap | ARPG anti-farming | pushes current content |

### 5.2 Enemy scaling axes

| Axis | Formula example | Best for | Note |
|---|---|---|---|
| Time | `EnemyPower(T)` | horde survival | clock is the boss |
| Stage/wave | `Power × stageFactor^stage` | roguelike runs | creates spike at transitions |
| Area level | `HP(level), Damage(level)` | ARPGs | content gates progression |
| Difficulty tier | `Base × tierMultiplier` | replay scaling | rewards must scale too |
| Player level | `BossHP × playerLevel` | selected bosses | use sparingly; can punish leveling |

### 5.3 Horde tuning equation

```text
Need: ClearPressure(T) >= SpawnPressure(T) at intended build power

SpawnPressure(T) = spawnRate(T) × EHP_per_enemy(T)
ClearPressure(T) = practicalPackDPS(T) × coverage(T)

If aliveEnemies reaches cap often:
  actual difficulty may flatten while performance cost rises.
```

### 5.4 TTK bands

| Enemy tier | Target TTK | Design job |
|---|---:|---|
| Trash | `≤0.5s` | die to incidental AoE |
| Bruiser | `1–3s` | force target priority briefly |
| Elite | `3–10s` | punctuation and build test |
| Boss | `10–60s` | sustained DPS + mechanics |
| DPS-check | fixed window | validates build threshold |

### 5.5 Boss HP derivation

```text
ExpectedDPS_T = median or P60 player DPS at encounter time T
TargetTTK_T = desired seconds
BossHP_T = ExpectedDPS_T × TargetTTK_T
```

Use **P60/P70 player DPS** for normal bosses; use **P85/P90** only for optional challenge bosses.

---

## 6. Spawn, Encounter & Performance Budget  **[Gap Fill]**

### 6.1 Spawn budget variables

| Variable | Meaning | Track in telemetry |
|---|---|---|
| `spawnRate` | enemies spawned/sec | yes |
| `aliveCap` | max simultaneous live enemies | yes |
| `queueDepth` | pending spawns blocked by cap | yes |
| `enemyEHP` | HP after defense modifiers | yes |
| `enemyDPS` | contact/projectile threat/sec | yes |
| `pathingCost` | CPU/AI cost per enemy | yes |
| `pickupCount` | XP/currency objects live | yes |
| `frameTimeP95` | performance stability | yes |

### 6.2 Spawn failure modes

| Symptom | Likely cause | Fix |
|---|---|---|
| player waits between packs | spawnRate too low or spawn distance too far | raise spawn cadence; spawn closer off-screen |
| screen capped but easy | enemy EHP/DPS too low; cap flattening difficulty | stronger waves; elites; ranged pressure |
| screen capped and laggy | aliveCap too high; AI/projectiles too expensive | merge enemies; reduce tick rates; cap projectiles |
| XP inaccessible | pickup radius too low vs movement pressure | raise magnet options; add vacuum events |
| elites invisible in crowd | silhouette/readability failure | size/VFX/health bar priority |
| boss trivialized by horde procs | boss shares proc target count | boss-specific proc/recovery effectiveness |

### 6.3 Practical defaults

| System | Conservative default |
|---|---|
| Aura tick rate | `2–4/sec`; lower if many enemies |
| Ground pool tick rate | `1–4/sec`; batch damage queries |
| On-hit VFX | throttle per target or per skill |
| XP gems | merge nearby pickups by value |
| Damage numbers | sample, aggregate, or priority display |
| Projectile collision | broad-phase + target cap per frame |

---

## 7. Upgrade Pools, Rarity & Offer Math

### 7.1 Weighted offer formula

```text
Eligible = upgrades not banned, not capped, prerequisites met
weight_i = baseTierWeight_i
         × levelBandMultiplier_i
         × tagSynergyMultiplier_i
         × pityMultiplier_i
         × antiRepeatMultiplier_i
         × availability_i

P(offer i) = weight_i / Σ weight_eligible
```

Draw multiple offers **without replacement** unless duplicates are intentional.

### 7.2 Rarity ladder

| Tier | Role | Offer policy |
|---|---|---|
| Common | build foundation | high early weight |
| Rare | specialization | rises after core picks |
| Epic | build-defining | limited early |
| Legendary / Heroic | capstone / transformation | gated, not freely rollable by default |

### 7.3 Build-aware weighting

| Mechanic | Safe range | Note |
|---|---:|---|
| Matching tag boost | `1.25–2.0×` | enough to guide, not auto-solve |
| Off-build suppression | `0.5–0.9×` | avoid hiding pivot options entirely |
| Pity boost | grows after misses | reset on hit |
| Anti-repeat | reduce just-seen options | prevents boring rerolls |
| Prereq forcing | only near build completion | avoid railroading minute 2 |

### 7.4 Reroll / banish / lock / skip

| Tool | Player function | System function |
|---|---|---|
| Reroll | new choices now | variance smoothing |
| Banish | remove bad option for run | denominator shrink, build agency |
| Lock | save a choice | delayed planning |
| Skip | avoid bad picks | prevents forced anti-synergy |
| Limit break | post-cap scaling | solves pool exhaustion |
| Gold/heal fallback | low-value filler | prevents dead level-ups |

### 7.5 Pool exhaustion check

```text
ExpectedRunPicks = expectedLevelUps + chestRewards + shopBuys + questRewards
AvailableMeaningfulPicks = Σ maxLevels of likely eligible upgrades
                         + evolutions/combo rewards
                         + limit-break pool

If ExpectedRunPicks > AvailableMeaningfulPicks:
  add caps, evolutions, limit-breaks, shops, gold/heal fallback, or reduce XP pace.
```

---

## 8. Itemization, Synergy & Combo Gates

### 8.1 Evolution/combo gate pattern

```text
Prereq A: base weapon at max level
Prereq B: matching passive/item owned or leveled
Prereq C: timing gate reached
Prereq D: reward source can evolve/combine
Result: replace or augment base with super-item
```

| Gate | Purpose |
|---|---|
| Max weapon level | proves commitment |
| Passive owned | creates build identity |
| Timing gate | prevents early snowball |
| Chest/boss reward | creates dopamine moment |
| Slot cap | limits number of completed combos |

### 8.2 Synergy types

| Type | Example pattern | Risk |
|---|---|---|
| Same-tag stacking | fire improves burn | over-focus |
| Cross-tag combo | cold + lightning = shock/freeze | discovery burden |
| Delivery combo | projectile + pierce + chain | shotgunning/coverage explosion |
| Stat conversion | armor → damage | double dipping |
| Conditional multiplier | more damage vs chilled | hidden multiplicative stacking |
| Economy synergy | pickup radius + XP gain | runaway leveling |

### 8.3 Double-dip audit

Flag any stat that affects both:

- application rate **and** damage per instance;
- area coverage **and** per-target damage;
- damage dealt **and** recovery from damage dealt;
- enemy debuff magnitude **and** duration/uptime;
- meta progression **and** in-run XP gain;
- summon count **and** each summon’s full inherited damage.

---

## 9. Economy & Meta-Progression  **[Gap Fill]**

### 9.1 Meta architecture

| Architecture | Formula | Pros | Risk |
|---|---|---|---|
| Additive baseline | `Base × (1 + meta + runStats)` | bounded, readable | low excitement |
| Independent multiplier | `Base × (1 + runStats) × (1 + meta)` | strong progression | early-run trivialization |
| Unlock/options | expands pool/content | preserves balance | less raw power fantasy |
| Difficulty consumes power | meta offset by Heat/Curse/Torment | long-term replay | reward tuning required |

### 9.2 Currency economy ledger

```text
NetCurrencyPerHour = earnedPerHour - mandatorySinksPerHour - optionalSinksPerHour
Inflation risk if earnedPerHour rises with meta but sinks are finite.
```

| Source | Sink | Balance note |
|---|---|---|
| run completion | permanent upgrades | finite; eventually exhausted |
| difficulty bonus | rerolls / banishes / unlocks | scales with challenge |
| achievements | new characters/weapons | content sink, not numeric sink |
| endless runs | cosmetics/prestige | avoids mandatory grind |
| duplicates | crafting/dust | prevents dead drops |

### 9.3 Meta guardrails

| Guardrail | Use when |
|---|---|
| cap permanent stat bonuses | raw power meta exists |
| make meta additive with run stats | early-run tension matters |
| unlock sidegrades, not upgrades | competitive balance matters |
| add scaling difficulty | players can overlevel content |
| separate cosmetic sinks | economy needs infinite drain |

---

## 10. Difficulty & Reward Scaling

### 10.1 Difficulty knobs

| Knob | Affects | Safe? | Notes |
|---|---|---|---|
| Enemy HP | TTK | medium | too high = slog |
| Enemy damage | death pressure | dangerous | spikes can feel unfair |
| Spawn density | clear pressure / CPU | medium | horde identity knob |
| Enemy speed | positioning | dangerous | can invalidate slow builds |
| Elite frequency | target priority | medium | good variety lever |
| Boss mechanics | skill test | safe if readable | better than raw HP late |
| Player debuffs | build constraints | dangerous | use in optional modes |
| Reward quantity | economy | medium | must track inflation |
| Reward quality | progression | dangerous | can obsolete lower tiers |

### 10.2 Reward rule

```text
ExpectedRewardRate(difficulty) >= ExpectedRewardRate(lower difficulty)
```

Players optimize the lowest tier that gives comparable reward/time. Raise rewards with difficulty enough to justify risk, but avoid making lower tiers irrelevant.

---

## 11. Telemetry & Balance QA  **[Gap Fill]**

### 11.1 Required telemetry events

| Event | Fields |
|---|---|
| damage_dealt | skill, target tier, damage type, hit/crit, overkill, mitigation |
| damage_taken | source, target HP before/after, mitigation layers, avoid/block result |
| enemy_spawned | wave/time, enemy id, budget cost, modifiers |
| enemy_killed | lifetime, killer skill, XP value, position |
| level_up_offer | offered ids, weights, chosen id, reroll/banish/skip used |
| upgrade_acquired | source, rarity, tags, current build tags |
| boss_start/end | time, player level, DPS, TTK, damage taken, deaths |
| recovery_tick | source, amount, wasted by cap, overheal |
| performance_sample | alive enemies, projectiles, pickups, frame time |

### 11.2 Dashboard targets

| Metric | Healthy signal | Red flag |
|---|---|---|
| Median level by minute | within planned band | underleveled players face full time ramp |
| Boss TTK P50/P90 | within tier range | P90 impossible or P50 trivial |
| Damage source share | no accidental monopoly | one skill >40–50% across builds |
| Recovery wasted by cap | nonzero for AoE builds | zero means cap irrelevant; 100% means sustain dead |
| Alive enemy cap time | occasional peaks | always capped or never pressured |
| Offer pick rate | varied by archetype | mandatory picks or never-picked upgrades |
| Reroll/banish usage | strategic | constant reroll = diluted pool |
| Death source distribution | multiple readable causes | one opaque source dominates |
| Frame time P95 | stable under cap | VFX/projectiles overwhelm |

### 11.3 Automated balance tests

| Test | Pass condition |
|---|---|
| Single-target dummy | each archetype within planned ST band |
| 10-target pack dummy | pack builds beat ST builds, but within cap |
| Projectile shotgun test | extra projectiles do not multiply boss DPS unless allowed |
| Leech abuse test | high-APS AoE hits recovery cap, not infinite sustain |
| DoT ramp test | stack cap/duration gives planned boss TTK |
| Defense cap test | no layer reaches invulnerability |
| Offer simulation | desired build can complete before intended timing gate |
| Spawn soak test | frame time stable at alive cap |
| Meta maxed test | early run still has threat or higher difficulty consumes surplus |

---

## 12. Tuning Workflow

### 12.1 Build order

1. **Set anchors:** `D_melee_ST = 1.0`, `H_common_L1 = 1.0`.
2. **Choose genre axis:** time/stage ramp or area/level ramp.
3. **Define TTK bands:** trash, elite, boss, DPS-check.
4. **Create archetype matrix:** ST value, pack value, penalty, guardrail.
5. **Lock projectile/DoT/recovery rules before tuning numbers.**
6. **Build XP and spawn curves together:** level pace must match enemy pressure.
7. **Create offer pool and slot caps:** avoid pool exhaustion.
8. **Simulate median and high-roll builds:** tune for P50/P75, not perfect play only.
9. **Tune meta last:** after the run loop works without permanent upgrades.
10. **Instrument and rebalance from telemetry:** especially TTK, recovery cap waste, offer rates.

### 12.2 Safe vs load-bearing knobs

| Safe to tune often | Load-bearing: change carefully |
|---|---|
| flat base damage | additive vs multiplicative bucket boundary |
| additive stat magnitudes | shotgunning rules |
| spawn count within performance cap | DoT stack model |
| pickup radius | recovery caps |
| cosmetic rarity weights | armor/resist caps |
| individual enemy HP | stage/time ramp exponent |
| minor XP rewards | slot caps |
| UI/readability | XP increment constants |
| gold fallback values | proc recursion rules |

### 12.3 Tuning smell checklist

| Smell | Check |
|---|---|
| “Every build takes this” | is it multiplicative, uncapped, or solving a mandatory defense? |
| “Bosses melt only with projectile builds” | shotgunning or explosion overlap leak |
| “Attack speed is always best” | independent DoT/proc/recovery double dip |
| “Defense feels useless until suddenly mandatory” | caps too steep or enemy burst too high |
| “Rerolls feel mandatory” | pool too diluted or tag weights too weak |
| “Late game is lag, not difficulty” | alive cap/projectiles/VFX exceed budget |
| “Meta makes early game boring” | meta in independent multiplier bucket |
| “CC builds do no damage and still fail bosses” | boss effectiveness too low or no stagger alternative |
| “DoT builds feel bad in packs” | no proliferation/spread/target switching support |
| “On-kill builds fail bosses” | no boss substitute trigger or adds phase |

---

## 13. Practical Starting Presets

### 13.1 Horde-survival preset

| System | Start value / policy |
|---|---|
| Run length | 20–30 min |
| XP | piecewise-linear increment; fast first 5 levels |
| Enemy scaling | scripted per-minute waves + stage/difficulty multiplier |
| Spawn cap | hard cap + queue telemetry |
| Slots | 6 active weapons, 6 passives, evolutions mid-run |
| Damage buckets | mostly additive; rare multiplicative evolutions |
| Recovery | global HP/sec caps; on-kill viable; boss-starved compensated |
| Projectiles | same-projectile rule; no free boss shotgun |
| Area | premium stat; monitor radius² scaling |
| Meta | additive power + unlocks + difficulty escalation |

### 13.2 ARPG preset

| System | Start value / policy |
|---|---|
| Session | campaign/map/dungeon chunks |
| XP | polynomial/geometric with level-gap penalty |
| Enemy scaling | area level + difficulty tier |
| Items | base + affixes + rarity + build-defining uniques |
| Damage buckets | clear increased/more language |
| Defense | armor/resist/dodge/block/barrier layers |
| Recovery | leech/regen/flask caps and class exceptions |
| Bosses | derived HP by area DPS and desired TTK |
| Meta/endgame | tiers that multiply risk and rewards |
| Economy | crafting sinks, upgrade sinks, trading/drop-rate controls |

---

## 14. Source Notes & Caveats

- Concrete game values are version-sensitive. Treat them as snapshots and re-check before shipping a clone of any live game's numbers.
- Coefficient ranges are synthesis defaults, not universal laws.
- Keep source-of-truth balance values in data tables, not code.
- Every multiplicative exception needs an owner, a reason, a cap, and a test.
- If telemetry and theory disagree, use telemetry to find the hidden bucket, target-count leak, or uptime assumption.

### Confirmed values retained from original reference

| Value | Usage |
|---|---|
| PoE-style leech default | total life/mana leech recovery cap ≈ `20% max/sec`; per-instance rate `2% max/sec` |
| Brotato-style armor lesson | rational armor gives declining displayed DR but constant marginal EHP |
| RoR2-style stage jump | time ramp plus multiplicative stage factor creates transition spikes |
| Vampire Survivors-style XP | piecewise-linear XP-to-next increments support bounded sessions |
| Vampire Survivors-style slots | active slot caps + evolutions produce specialization and mid-run spikes |
| Proc coefficients | normalize fast/multi-hit skills against on-hit effects |

---

## 15. Copy-Paste Formula Appendix

```text
# Additive bucket relative value
relative_gain_from_additive = delta / (1 + current_additive_sum)

# Crit expected value
crit_ev = 1 + clamp(crit_chance, 0, 1) * (crit_multiplier - 1)

# Attack/cast DPS
single_target_dps = average_hit * hits_per_second * uptime

# Pack DPS approximation
pack_dps = average_hit * hits_per_second * average_targets_hit * coverage

# Proc rate
procs_per_second = hits_per_second * targets_hit * proc_coeff * trigger_chance

# Rational mitigation
armor_dr = armor / (armor + k)
post_armor_damage = incoming * (1 - armor_dr)

# Resistance with penetration
res_after_pen = clamp(resistance - penetration, min_res, max_res)
post_res_damage = incoming * (1 - res_after_pen)

# EHP from layered mitigation
ehp = hp / product(1 - mitigation_layer_i)

# DoT independent stack steady-state approximation
active_stacks ≈ application_rate * duration
stacking_dot_dps ≈ dot_dps_per_stack * active_stacks

# Highest-only DoT
highest_only_dot_dps = max(active_dot_instances.dps)

# Cooldown with hard floor
actual_cooldown = max(base_cooldown * (1 - cooldown_reduction), cooldown_floor)
casts_per_second = 1 / actual_cooldown

# Exponential soft cap
final = cap * (1 - exp(-x / tau))

# Stacking independent avoidance
avoidance = 1 - product(1 - avoidance_source_i)

# Boss HP from TTK target
boss_hp = expected_player_dps_at_time_T * target_ttk_seconds

# Spawn pressure
spawn_pressure = spawn_rate * enemy_ehp
clear_pressure = player_pack_dps * practical_coverage

# Weighted offer probability
offer_weight_i = base_weight_i * level_band_i * tag_synergy_i * pity_i * anti_repeat_i
probability_i = offer_weight_i / sum(offer_weight_j for j in eligible)
```
