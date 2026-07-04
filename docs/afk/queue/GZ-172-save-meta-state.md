# GZ-172 — P3 (game): save & meta-state module

intent: The world remembers: rekindled beacons, carried warmth, unlocks, banishes/tokens, settings — one small deep module with versioned serialization.
files in scope: PRIMARY (new): `godot/scripts/meta_state.gd` (class_name MetaState, RefCounted — headless like Simulation) + (new) `godot/tests/run_meta_state_tests.gd` registered in BOTH run_all_checks.sh arrays; a load/save call in game_controller.gd. DO NOT touch: simulation.gd (a run READS meta at start — one injection point, `Simulation.apply_meta(dict)` added here as its only sim touch, recorded in API-CONTRACT).
grounding: ADR 0010 (what persists); balance §13.1 (meta power bounded additive — apply_meta may only add bounded starting bonuses, never multiply); Godot user:// JSON with schema_version field (verify FileAccess API against 4.7 docs).
decisions made: JSON at user://gizmo_save.json, schema_version 1, unknown-version → backup + fresh (never crash); atomic write (temp + rename); NO mid-run saving in 1.0 (a run is a sitting — rogue-lite law, recorded); corrupted file → fresh with the corrupt one preserved as .bak.
executable success criteria: new runner green — round-trip equality, version migration stub, corruption recovery, atomicity (kill-between simulated); absence: no autosave during a run; gate green.
dependencies / order: blockedBy GZ-171. Blocks GZ-173–175, GZ-162.
model routing: **Sonnet** — a well-specified serialization module, TDD-shaped.
status: deferred:P3
