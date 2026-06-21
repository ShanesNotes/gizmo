# 0014 — Enemies respect the pillars (solid arena obstacles)

**Date:** 2026-06-21
**Lesson:** `lessons/0014-enemies-respect-pillars.html`
**Mode:** **model-built + explained (TDD), learner verified live.** Claude wrote the red test, the green
implementation, and the wiring, walking through each line; the learner ran the live game and confirmed enemies
no longer clip the pillars ("we are good to move on").
**Status:** Verified — headless deterministic tests + live runtime query + learner live confirmation.

## What was built
The first arena rule with **no `simulation.ts` source** (the Phaser arena is open floor) — a deliberate 3D-arena
addition. The headless Simulation moved enemies on a flat plane with zero obstacle awareness, so the art stream's
solid props (beacon, pylons, debris) were ghosted through. Scoped to **3 files**: `simulation.gd`,
`game_controller.gd`, `run_simulation_tests.gd`.
- **`Obstacle` data agent + `obstacles[]` + `add_obstacle()`** (`simulation.gd`) — circular XZ footprints. **Empty
  by default**, so the 0013 balance harness (bare sim, open floor) is byte-for-byte unaffected and stays a valid guard.
- **`_resolve_obstacles()`** — circle push-out, the same idea as `_separate_enemies()` (0008) but against *static*
  circles. "Soft push-out, **not** navigation" per ADR 0002. Runs **last** in `_update_enemies()` (after seek /
  separation / knockback) so the post-tick invariant holds: no enemy ends a frame inside an obstacle.
- **`_register_arena_obstacles()`** (`game_controller.gd`) — mirrors each **solid** world-kit piece's declared
  `footprint_meters` into the sim, excluding walkable roles (`walkable_tile`, `foundation`). Zero `main.tscn` edits;
  the piece is the single source of truth, fed into two worlds (ADR 0002).

## The teaching beat — two movers, two worlds
The core idea: **enemies move in the Simulation (rules-world); Gizmo moves in Godot physics (physics-world).** A prop
is solid to a mover only if the obstacle exists in the world that owns it. The art stream had already made props solid
for **Gizmo** (each piece carries a `StaticBody3D` + `CollisionShape3D`), so this lesson only had to add the **enemy**
half — the same footprint, mirrored into the rules-world. One source of truth, two worlds.

## Verified
- `run_simulation_tests.gd` → **PASS 71** (two new: push-out to the rim; a 12s seek-through-pillar that never tunnels).
  Full suite green: controller 10 · playable-slice 766 · **balance still 32** (unchanged — opt-in obstacles invisible
  to the bare-sim harness). `--check-only` clean on both edited scripts.
- **Live runtime query** (godot-runtime MCP `run_script`): the running scene registered **27 obstacles** (beacon r≈1.3,
  14 pylons r≈0.7, 12 debris r≈0.8–1.2; **zero** floor tiles / the 18×18 foundation — the role filter worked), with
  `enemies_inside_obstacle: 0`. A staged 16-enemy cluster dropped on the beacon was all ejected (`still_inside_beacon: 0`).
- **Learner live confirmation:** enemies no longer clip the pillars.

## Teaching nuances captured
- **"Red" here is a silent skip, not a red bar.** A missing method (`add_obstacle`) errors mid-test before any
  `_check`, so the count just *doesn't rise* (69, not 71) — red is confirmed by reading the `Nonexistent function`
  error, not a FAIL line. Worth remembering for this dependency-free harness.
- **Emergent routing for free:** an off-axis enemy seeking past a pillar *slides around* it (redirecting seek + radial
  push-out), rather than only pinning. It's still push-out, not pathfinding — the head-on degenerate case can pin.
- **MCP teardown crash on `stop_project`** (signal 11, `propagate_notification` thread error) — a known Godot-mono
  shutdown hazard (commit f6f4d79), not caused by this change; the live query completed cleanly before it. Residue
  guard checked: `.mcp` + `mcp_bridge.gd` gitignored, no `mcp_bridge` autoload in `project.godot`.

## Deferred (named, not built)
- Smarter routing (tangential slide / navmesh) **only if** a feel pass demands it.
- Pillars as deliberate tactical cover in balance tuning.
- The real **Core Matrix / upgrade-choice** system (still post-v1).

See [[v1-loop-complete-balance-pass-next]] (the world-kit-collision deferral is now resolved) and
[[parallel-workstreams]] (clean 3-file scope; art-stream dirt untouched; `WorldKitPiece` reused as the obstacle source).
