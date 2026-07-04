# GZ-156 — E5 (sim): jackpot & nova, re-derived post-ADR-0011

intent: The two cut upgrades return in forms that survive the score cut: jackpot as a fortune passive (crit + cache/scrap luck), nova as the level-up shockwave.
files in scope: PRIMARY: `godot/scripts/simulation.gd` — Cluster A; tests: run_simulation_tests.gd + run_balance_tests.gd.
grounding: defs ts:319–338 (maxRank/weight/unlockLevel canon); nova cast ts:514 (`castNova(state, events, 190 + rank*34, 2.2 + rank*0.8)` on choose); jackpot ts crit/cache language; ADR 0011 (score components dead — jackpot re-derived, recorded here).
decisions made: jackpot rank → crit chance +4%/rank (CritEV per balance §1 master formula; crit multiplier fixed 1.5×) and +8%/rank scrap-drop chance from non-elites; nova rank → on level-up, radial blast damage 1, radius 2.2 + 0.8/rank (pulse's event/render path reused — `{"type":"pulse"}` with a nova flag). Crit is NEW sim surface: `CritEV` folded into current_attack_damage as expected-value (deterministic tests) with per-hit roll only for the feel event.
executable success criteria: sim tests — crit EV math, scrap-luck bounds, nova fires exactly on level-up resolution (after choose_upgrade, before resume) hitting in-radius enemies; balance gate green (jackpot's DPS contribution within additive-bucket guardrails §1). Gate green.
dependencies / order: blockedBy GZ-151 (ADR), GZ-155 (scrap exists for jackpot's luck half).
model routing: **Sonnet** — formulas specified above; port carefully.
status: deferred:E5
