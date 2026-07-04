# GZ-175 — P3 (sim): act & threat difficulty scaling

intent: Later regions bite harder: sim gains a difficulty profile (threat tier 0–4 × act multiplier) applied to enemy HP/damage/budget and elite cadence — set per region at run start, never mid-run.
files in scope: PRIMARY: `godot/scripts/simulation.gd` (`configure_difficulty(threat: int, act: int)`) — Cluster A; tests: run_simulation_tests.gd + run_balance_tests.gd. DO NOT: touch per-kind base stats (profiles multiply, bases stay canon).
grounding: region graph threat levels (HEARTH 0 … NULL 4); balance §5.2 enemy-scaling axes ("difficulty tier: Base × tierMultiplier — replay scaling") + §13.1 (meta consumed by higher difficulty); ADR 0010 (region difficulty law).
decisions made (recorded v1 numbers): enemyHP ×(1 + 0.35·threat), enemyDamage +1 at threat ≥3 only (guard math stays readable), spawn budget gain ×(1 + 0.15·threat), elite interval floor −2s·threat (min 18s), act multiplier ×1.0/1.15/1.3 on HP. TTK bands re-anchored per tier in the balance suite (the player is expected to arrive with meta + evolutions — median build per act defined in-test).
executable success criteria: sim tests — profile application exact; immutability mid-run; balance suite — per-act median-build TTK/survival harness green. Gate green.
dependencies / order: blockedBy GZ-172 (meta feeds the median-build assumptions), GZ-154 (evolutions exist). Blocks REGION-* gate tests.
model routing: **Sonnet** — multiplier plumbing with given numbers; balance suite is the guard.
status: deferred:P3
