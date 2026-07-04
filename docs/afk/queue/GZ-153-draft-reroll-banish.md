# GZ-153 — E5 (sim+UI): draft reroll & banish

intent: Draft agency deepens: once per draft, reroll all three choices; once per RUN, banish an upgrade from the pool for the rest of the run.
files in scope: PRIMARY: `godot/scripts/simulation.gd` (`reroll_choices()`, `banish_upgrade(id)`, per-run counters) — Cluster A serialization; then `godot/scripts/upgrade_draft.gd` + tscn (two small buttons); tests: run_simulation_tests.gd + run_upgrade_draft_tests.gd.
grounding: reroll precedent ts:526 (`rollUpgradeChoices(state, 3, "reroll")`); banish is a genre-standard pool-shaping verb (recorded as design-choice, no ts analog — balance ref §7.5 pool-exhaustion math must be re-asserted with banish accounted).
decisions made: 1 reroll per draft (not stockpiled), 1 banish per run (v1 of this feature; meta may extend later); reroll consumes the draft's reroll regardless of outcome; banished ids excluded from eligibility (API-CONTRACT weight model extends: availability term 0).
executable success criteria: sim tests — reroll produces a fresh valid roll and second reroll refuses; banish removes the id from all future rolls this run; GZ-019's pool-exhaustion assertion updated and green. UI tests — buttons wired, disabled states correct. Gate green.
dependencies / order: blockedBy GZ-001..012 merged (P0 done) and GZ-151 band open. 
model routing: **Sonnet**.
status: deferred:E5
