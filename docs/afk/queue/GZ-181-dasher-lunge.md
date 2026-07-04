# GZ-181 — E8/P4 (sim): dasher lunge behavior

intent: The first enemy VERB beyond seek: dashers telegraph a windup, then lunge — punishing straight-line kiting, rewarding the dash verb. Honest port, not invention.
files in scope: PRIMARY: `godot/scripts/simulation.gd` — Cluster A; tests: run_simulation_tests.gd; enemy visual telegraph via the event channel (consumed by GZ-021's layer, tiny addition).
grounding: ts:706 — `chaseBurst = chargeBurst ? (elite ? 1.46 : 1.34) : chargeWindup ? 0.5 : 1` (windup slows to 0.5×, burst multiplies chase speed; elites burst harder). Port the windup→burst cycle with those multipliers; cycle timing derived at pickup from the surrounding ts block (builder cites the lines in the PR — the state timers live near :700–710).
decisions made: applies to dashers (and elite dashers) only in P4; telegraph event `{"type":"windup", id}` 0.5s before burst (readability at the fixed camera — pressure must be readable, ADR 0008 validator spirit); TTK band unchanged (behavior, not stats).
executable success criteria: sim tests — windup slows, burst exceeds base speed ×1.3, cycle repeats, elite multiplier applied, telegraph event precedes every burst; balance suite green. Gate green.
dependencies / order: blockedBy P0 complete; slots into P4 alongside act-1 regions (Cluster A serialization with R-*-5 slices).
model routing: **Sonnet** — anchored port with named multipliers.
status: deferred:P4
