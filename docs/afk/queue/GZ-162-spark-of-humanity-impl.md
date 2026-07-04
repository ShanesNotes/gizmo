# GZ-162 — E6 (game): Spark-of-Humanity implementation per ADR 0012

intent: The ruling becomes real: whatever ADR 0012 ratified (default: between-run carried-warmth world meter gating acts + seeding the style ramp), implemented against the save/meta layer.
files in scope: per the ADR — under the default: `godot/scripts/meta_state.gd` (GZ-172's module) + world-map UI touch (GZ-173) + style baseline hook (GZ-133's director). Tests in the meta/save suite. DO NOT: create any in-run HUD bar for it unless the ADR says so (absence assertion required either way).
grounding: ADR 0012 (the contract); ADR 0001 distinctions (validator-grade: never rendered as Sparks/XP/guard).
decisions made: deferred to the ADR by design — this ticket is deliberately thin until GZ-161 lands; its ACs are re-derived from the ADR's consequence list at pickup (the one permitted re-derivation in this queue, recorded here).
executable success criteria: every consequence line in ADR 0012 has a named test; absence assertions per ADR 0001; `tools/godot/run_all_checks.sh` green.
dependencies / order: blockedBy GZ-161, GZ-172.
model routing: **Sonnet** — implementation of a ratified contract.
status: deferred:E6
