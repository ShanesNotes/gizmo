# 0008 — Enemies: spawn, chase, contact

**Date:** 2026-06-20
**Lesson:** `lessons/0008-enemies-spawn-and-chase.html`
**Mode:** model-built-and-explained; learner chose the architecture (ADR 0002)
**Status:** complete — verified green (39 checks) + live runtime

## Decision (ADR 0002)
Where 0008 forced the Simulation↔scene integration, the learner chose the
**hybrid**: Simulation owns the rules (incl. enemies as data agents); the scene
renders them; a `GameController` bridges. Seek steering, **not** NavigationAgent3D.
Player movement stays in Godot. Values in Godot metres. Pinned in
`docs/adr/0002-simulation-owns-rules-scene-renders.md`.

## What was built
- `scripts/simulation.gd`: inner `Enemy` class; `tick(dt, gizmo_position)` spawns
  on `spawn_interval`, seeks Gizmo on XZ (unit-vector × speed × dt), and deals
  contact damage via the 0007 `take_damage` (i-frames + lose for free). Nibbler
  damage 1, faithful to `ENEMY_SPECS` (simulation.ts:259); positions/speeds in
  metres (ADR 0002).
- `tests/run_simulation_tests.gd`: +7 checks (spawn cadence, chase direction,
  contact+i-frames, no-spawn-after-gameover) → **39 total**.
- Scene: `scenes/enemy.tscn` (visual), `scripts/game_controller.gd` (owns one
  Simulation, feeds Gizmo's position each physics frame, mirrors enemy visuals
  by index), wired into `scenes/main.tscn`.

## Verified
- `godot --headless --path godot --script res://tests/run_simulation_tests.gd` →
  **PASS — 39 checks**, exit 0.
- Live: ran the game; 11 nibblers spawned, chased the stationary Gizmo, contact-
  damaged through i-frames to hp 0 → `gameover`; GameController `_views` mirrored
  all 11. Screenshot showed the swarm closing on Gizmo.
- Adversarial workflow (logic-fidelity/ADR-0002, tests-green, scene-wiring,
  hygiene) + completeness critic → pass; critic-caught lesson path prefixes fixed.

## What this establishes (for ZPD)
The Simulation↔scene seam (data authority + thin renderer via GameController);
data-agent enemies with seek steering; reusing the `take_damage` primitive for
contact. The run now pushes back: stand still → die; move → kite.

## Deferred (flagged in-lesson)
- Enemy **death + Spark drops** → 0009 (combat) — closes the loop back to 0006.
- **Ramping** spawn pressure / waves → 0010. Enemy-enemy **separation** → polish.
- The index-parallel `_views` mirror is fine while enemies only grow; it gets a
  per-enemy map + removal once they can die.

## Notes
- Skeleton-first RED doesn't decompose cleanly here (chase/contact tests need a
  spawned enemy), so the tests go green spawn-first, not all-at-once — noted in
  the lesson rather than faked.
