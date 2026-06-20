# 0002 — Simulation owns the rules; the scene renders them (hybrid)

**Status:** accepted · 2026-06-20

## Decision
A **hybrid rules/view split**:

- **`Simulation`** (the headless `RefCounted` in `scripts/simulation.gd`) is the
  authority for **game rules** — the run lifecycle, player HP, Sparks/leveling,
  and **enemies** (spawn cadence, chase, contact damage, death, and later Spark
  drops and wave pressure). It is pure data + math, unit-tested headlessly.
- **The Godot scene** owns **player input & feel** (Gizmo's `CharacterBody3D`
  movement/facing/camera, as built in 0004–0005) and **rendering**.
- A **`GameController`** node bridges them: each physics frame it feeds Gizmo's
  position + `dt` into `Simulation.tick(dt, gizmo_position)`, then mirrors
  Simulation's enemy data onto visual nodes.

## Specifics locked for the enemy work (0008+)
- Enemies are **lightweight data agents** inside Simulation, not autonomous scene
  scripts. The scene draws the truth; it does not invent separate behavior.
- **Simple seek steering**, not `NavigationAgent3D`: open-floor horde pressure
  with many cheap agents is clearer, faster, and testable. Navigation comes later
  if/when maps have obstacles.
- **Player movement is NOT ported** into Simulation for now. Gizmo movement +
  camera stay in Godot (ADR keeps the hands-on feel from 0004–0005).
- **Units:** Simulation works in **Godot metres**, not Phaser pixels. Enemy
  positions/speeds/radii are tuned for our ~20 m floor; the *relative* balance
  (e.g. nibbler `damage`, archetype ratios) stays faithful to `ENEMY_SPECS` in
  `simulation.ts`.

## Why
The addictive horde loop (Vampire Survivors / Diablo / Megabonk) lives or dies on
**testable spawn / combat / reward math**, not one-off scene scripts. Making
Simulation the brain keeps that math under the red→green discipline that has
worked since 0006, and lets the HUD (0011) and win/lose (0012) read one source of
truth. The scene stays responsible for what Godot is best at: feel and rendering.

## What this rules out
- Treating autonomous, untestable enemy scene scripts as the source of truth.
- `NavigationAgent3D` for the open-floor 0008 slice.
- Porting player movement into Simulation now (would redo 0004–0005).

Revisiting any of these (e.g. nav-mesh enemies, or a full headless player port)
requires a new ADR. Relates to [ADR 0001].
