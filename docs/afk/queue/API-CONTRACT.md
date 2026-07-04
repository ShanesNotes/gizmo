# Simulation public API — contract evolution across the sim lane

Cold-agent orientation: what surface `godot/scripts/simulation.gd` (class_name Simulation) exposes
BEFORE the lane starts, and exactly what each ticket ADDS. A sim-lane ticket may not remove or rename
anything below without recording it in its "decisions made" — downstream tickets and tests cite this.

## Baseline (verified on gizmo-3d, 2026-07-04)
State: `phase` (playing/complete/gameover), `elapsed`, `level`, `xp`, `next_xp`, `hp`, `max_hp`,
`kills`, `enemies`, `pickups`, `last_events`, beacon: `beacon_state` (dormant/rekindling/rekindled),
`beacon_channel_progress`, `beacon_position`, `beacon_radius`.
Methods: `tick(dt, gizmo_position)`, `add_xp(amount) -> bool`, `xp_progress()`, `hp_progress()`,
`take_damage(amount) -> bool`, `pressure()`, `heat()`, `current_attack_cooldown()`,
`current_attack_target_count()`, `current_attack_damage()`, `add_obstacle(pos, radius)`,
`next_xp_for_level(lvl)` (static).

## Additions by ticket
| Ticket | Adds | Notes |
|---|---|---|
| GZ-001 | `awaiting_choice: bool`, `choices: Array[Dictionary]` ({id,title,rank,max_rank,color}), `choose_upgrade(id)`, `upgrades: Dictionary` (id→rank), `rng: RandomNumberGenerator`, `const UPGRADE_DEFS` | tick() inert while awaiting_choice; level autoscale (:361–372) retired — rank 0 == old level-1 baseline |
| GZ-002 | `speed_multiplier() -> float`; pickup pull motion; heart/focus/magnet/sprint/spark rank effects | attack_range flips MELEE→5.0 at spark rank 1 |
| GZ-003 | pulse internals + `{"type":"pulse","radius":R}` event in last_events | no new public methods |
| GZ-004 | `orbit_state() -> Dictionary` ({count, radius, angle}) | scene mirrors it (GZ-022) |
| GZ-005 | `guard`, `max_guard`, `guard_progress() -> float`, `set_guard_recharge_modifier(rate_mult, delay_mult)` | take_damage routes guard-first; hp_progress meaning unchanged |
| GZ-006 | `add_pressure_zone(pos, radius, exposure, role, relief_multiplier := 1.0)`, `spatial_exposure_at(pos) -> float`, `temporal_pressure() -> float` | `pressure()` becomes temporal × spatial; Rekindling forces exposure 1.0 |
| GZ-007 | `set_walkable_region(points: PackedVector2Array)`, `is_walkable(pos) -> bool` | empty region = permissive (baseline preserved) |
| GZ-008 | (no new surface) sanctuary-role zones drive the GZ-005 modifier each tick | strongest-single, no stacking |
| GZ-009 | `elite: bool` on enemy records; internal `elite_index` | never player-facing |

## Consumers (read-only wrt this contract)
GameController: tick feed, enemy/orbit mirroring, zone registration (GZ-015), draft pause (GZ-012),
music states (GZ-032), feel events (GZ-021). HUD: guard_progress/hp_progress/xp_progress, beacon
readout (exists, hud.gd:55), rekindle fill (GZ-014). End screen: level/kills/xp (GZ-018).
Integration gate: everything (GZ-020).
