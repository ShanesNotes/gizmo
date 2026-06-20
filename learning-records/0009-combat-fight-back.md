# 0009 — Combat: fight back & close the loop

**Date:** 2026-06-20
**Lesson:** `lessons/0009-combat-fight-back.html`
**Mode:** **model-built draft — pending learner review.** The learner chose the
direction (auto-fire) and will review; they have NOT yet built or explained it
hands-on. Promote to "complete" only after the learner can explain the slice.
**Status:** DRAFT (implementation verified; learner understanding pending)

## What was built (model-built)
The combat loop, closing kill → Spark → XP → level:
- `scripts/simulation.gd`: `Pickup` data agent; `Enemy.xp_value`; combat consts
  (ATTACK_COOLDOWN 0.5, ATTACK_RANGE 6, ATTACK_DAMAGE 1, PICKUP_RADIUS 1.8,
  NIBBLER_XP 3). `tick` gains `_update_weapon` (auto-fire at the nearest LIVE enemy
  in range — skips a corpse, simulation.ts:1714; kill → remove + drop Spark worth
  xp_value) and `_update_pickups` (collect within radius → `add_xp`, i.e. 0006
  leveling). Faithful shapes: updateWeapons/dealDamage (simulation.ts:817-836,
  1169-1185), xp gain (1014), pickup/levelup events (949/1038).
- Review hardening (0009 review): a per-tick `last_events: Array[Dictionary]`
  (attack/hit/defeat/pickup/levelup), a fresh array each `tick` (snapshot-safe) — the `GameEvent[]` seam
  (simulation.ts:168-198, 462, 496) that 0011 HUD / a later VFX lesson will read
  (0010 does NOT use it yet). Uncollected Sparks capped at `max_pickups` 90,
  drop-oldest (simulation.ts:207/945). Weapon ignores dead enemies (1714).
- `tests/run_simulation_tests.gd`: +9 combat checks (autofire damage, range+radius,
  death+removal, Spark drop value, collect→xp, level-up) and +14 hardening checks
  (corpse-skip ×2, nearest-of-two ×2, pickup cap ×2, events ×5, snapshot-safety ×3)
  → **66 total**.
  Enemy-only tests set a huge `attack_cooldown`, and pickup-sensitive tests set
  `pickup_radius = 0`, to isolate the unit under test.
- Scene: `scenes/spark.tscn` (violet emissive pickup); `game_controller.gd`
  refactored to a **per-agent-type Dictionary** `_sync` — adds views, moves them,
  and frees the view of any agent that's gone (death/collect). No index parallel.

## Verified (implementation)
- `godot --headless --path godot --script res://tests/run_simulation_tests.gd` →
  **PASS — 66 checks**, exit 0.
- Live: stationary Gizmo → weapon clears enemies at range (only ~1 alive),
  ~21–59 violet Sparks ring him (`spark_views` == `pickups`, dict sync holds),
  hp stays 7. Moving NE collected Sparks → the **Simulation's xp rose 0 → 27**
  (9 × 3; no HUD yet — that's 0011). Screenshot shows the Spark halo. Leveling
  crossing proven by the headless test.

## What the slice covers (to confirm with the learner)
The closed dopamine loop; combat as Simulation rules (ADR 0002); the
Dictionary-keyed view sync that frees visuals on death/collect (the 0008-promised
refactor); reusing `add_xp` so three lessons of systems become one loop.

## Deferred (flagged in-lesson)
- Weapon **VFX** (tracers/projectiles/GPU particles) → a later particles/shader
  lesson; the shot is invisible for now (feedback = deaths + Sparks).
- Crits, multi-target, Cache/Heart drops, magnet/upgrade draft.
- **Event fields are minimal by design**: `last_events` carries the five event
  names with only the fields our current systems produce. Richer GameEvent fields
  (attack kind, crit, color, upgrade `choices`, full enemy/pickup refs) land with
  those systems — adding them now would invent detail we haven't designed.
- **Pressure director** + ramping enemy intensity → 0010 (where the loop snowballs).
- Spark value is the faithful 3, so leveling is slow until pressure ramps kills.
