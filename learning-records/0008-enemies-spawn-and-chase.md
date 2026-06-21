# 0008 — Enemies: spawn, chase, separate, contact

**Date:** 2026-06-20
**Lesson:** `lessons/0008-enemies-spawn-and-chase.html`
**Mode:** **model-built draft — pending learner review.** The learner chose the
architecture (ADR 0002, Option 1) and reviewed the slice; they have NOT yet built
or explained it hands-on. This is **not** a record of demonstrated learner
understanding — promote it to "complete" only after the learner works through and
can explain the slice.
**Status:** DRAFT (implementation verified; learner understanding pending)

## Decision (ADR 0002)
The learner chose the **hybrid**: Simulation owns the rules (incl. enemies as data
agents); the scene renders them; a `GameController` bridges. Seek + soft separation,
**not** NavigationAgent3D or physics bodies. Player movement stays in Godot. Values
in Godot metres. Pinned in `docs/adr/0002-simulation-owns-rules-scene-renders.md`.

## What was built (model-built)
- `scripts/simulation.gd`: inner `Enemy` class; `tick(dt, gizmo_position)` runs four
  phases — spawn (capped at `max_enemies`, balance §6.1), seek on XZ, **soft
  separation** (`_separate_enemies`, deterministic push-apart), and contact AFTER
  moving (within `radius + PLAYER_CONTACT_RADIUS`, only past the 7s `CONTACT_GRACE`,
  simulation.ts:722) via the 0007 `take_damage`. Nibbler damage 1 (ENEMY_SPECS).
  Also added divisor guards to `run_progress`/`hp_progress` (0007 polish).
- `tests/run_simulation_tests.gd`: enemy checks (spawn cadence, chase, contact +
  i-frames, contact grace, separation, alive cap, no-spawn-after-over) → **43 total**.
- Scene: `scenes/enemy.tscn`, `scripts/game_controller.gd` (owns one Simulation,
  feeds Gizmo's position, mirrors visuals), wired into `scenes/main.tscn`.

## Verified (implementation)
- `godot --headless --path godot --script res://tests/run_simulation_tests.gd` →
  **PASS — 43 checks**, exit 0.
- Live: enemies spawn and form a **spaced crowd** around Gizmo (screenshot); min
  pairwise distance ≈ 1.92 m ≈ the 2.0 separation floor (no overlap/blob); contact
  after the grace drives a stationary Gizmo to `gameover`.

## What the slice covers (to confirm with the learner)
The Simulation↔scene seam (data authority + thin renderer via GameController);
data-agent enemies with seek + separation; reusing `take_damage` for contact; the
alive cap and opening grace. The run now pushes back: stand still → die; move → kite.

## Deferred (flagged in-lesson)
- Enemy **death + Spark drops** → 0009 (combat) — closes the loop to 0006.
- **Ramping** spawn pressure / pressure director → 0010. Spatial hash for
  separation when counts climb. Per-enemy `_views` map + removal once enemies die.

## Review history
- Built model-driven per the learner's 0008 spec; reviewed.
- Review round caught: enemy stacking (separation now in-slice, not deferred);
  premature record (this draft framing); crude contact (now post-move + player
  radius); missing 7s grace (added + tested); no alive cap (added + tested);
  spawn ring outside the floor (ring 9). All addressed; suite 39→43.
