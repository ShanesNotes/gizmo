# GZ-154 — E5 (sim): evolutions + slot caps

intent: Build identity: maxed upgrades offer an EVOLUTION rank (transformed effect), and active build slots are capped so picks are choices, not collections.
files in scope: PRIMARY: `godot/scripts/simulation.gd` — Cluster A; tests: run_simulation_tests.gd + run_balance_tests.gd.
grounding: ts evolved flags ts:381; evolution bonuses in formulas ts:562 (magnet +110 pull), ts:566 (sprint +42 scoop / ts:652 +34 speed); rarity/capstone policy balance ref §7 rarity ladder ("Legendary/capstone — gated, not freely rollable"); slot caps balance §13.1 (6 weapons/6 passives preset → v1 of this feature: 3 weapon slots [spark/pulse/orbit all fit], 4 passive slots [of magnet/sprint/heart/focus] — caps bind when E5/E8 add more upgrades).
decisions made: evolution = rank maxRank+1, offered only when base is maxed, weighted rare (0.35× pity-boosted per §7.1); evolved effects (recorded): spark→chain forks once (same-projectile rule §2 respected — fork shares the hit, no boss shotgun), pulse→leaves a 1.5s slow field, orbit→+1 star & radius ×1.25, magnet/sprint per ts numbers, heart→guard +1 (the ONLY guard-touching upgrade; ADR 0007 cap respected), focus→cooldown floor −10%.
executable success criteria: sim tests per evolution effect; offer tests (never offered pre-max; rare weight); slot-cap test (5th passive draft never offered); balance gate re-run green with evolutions in the median build. Gate green.
dependencies / order: blockedBy GZ-153 (draft surface stable), GZ-019.
model routing: **Opus** — touches every weapon formula + the offer system; balance-sensitive.
status: deferred:E5
