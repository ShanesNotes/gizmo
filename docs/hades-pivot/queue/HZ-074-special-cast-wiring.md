# HZ-074 — SPECIAL and CAST live damage wiring

**Status:** ready-for-agent · **Worker:** Codex · **Deps:** HZ-071 (shipped)
**Source:** HZ-103 audit note — `special_started`/`cast_started` are signal-only
placeholders (same defect class as the fixed attack gap). Parity spec: special = heavy
swing; cast = ammo-with-reclaim ranged shot (ammo logic already lives in the kit).

## Scope
1. **Special resolver** (orchestrator, analog of the melee resolver): heavier damage, wider
   arc (~160°), slightly longer range, longer recovery — a crowd tool. Charges Spark
   (damage-dealt path). Windup-immune enemies excluded.
2. **Cast resolver**: ranged — a projectile-lite hitscan along facing (first enemy within an
   exported cast_range ~8.0 in a narrow corridor arc ~20°), consumes ammo per the existing
   kit logic; the shard lodges in the victim (Hades pattern): reclaim on victim death or
   walk-over pickup — reuse the fixture/pickup idiom from HZ-072 if it fits, else a minimal
   shard node. Charges Spark on hit.
3. HUD ability slots already render counts — verify cast ammo count flows (payload only).
4. Red-first: both resolvers (range/arc/damage/Spark charge/windup immunity), ammo
   consume/reclaim cycle, kill-through-cast ledger exactly-once.

## Fence
run_orchestrator.gd (resolver functions + signal wiring region only if other jobs active),
godot/scripts/abilities/ (cast/special ability params if numbers need exposing), a minimal
shard scene/script if needed, suites: orchestrator, ability_kit, integration_gate.
NOT enemies/, room_director, boons, hud.gd internals (payload calls allowed), app_shell.
