# CONTEXT — Gizmo (3D)

Orientation keystone. Read first; if other docs disagree, this wins.

## Clean-slate reset (2026-06-20)
This project is now a **clean-slate 3D Godot rebuild**. Prior 2.5D, sprite-first,
or orthographic-presentation plans/docs are inactive history unless the user
explicitly reactivates them. Use them only as archaeology; do not let them steer
new work.

## What the game is
A **rogue-lite** in which **Gizmo**, a clanker, preserves the **spark of humanity**
through escalating **enemy pressure** across a **gouache cosmos of lost tech**.
Genre tag: **rogue-lite**. Premise canon: `design-handoff/NARRATIVE.md`.

## No-wave correction (2026-06-20)
Do **not** frame Gizmo as discrete "WAVE x/5" rounds. That language came from
stale concept artwork / earlier ideation and is inactive unless the user
explicitly reintroduces it. The active model is a **director-driven pressure
curve**: enemies spawn, pressure ramps, the run can crest into special threats
later, but the player should not see or learn a wave-round structure in v1.
If older docs say waves/elites/bosses, read that as generic enemy escalation
only. See `docs/adr/0003-director-pressure-not-discrete-waves.md`.

## The loop
Survive escalating **enemy pressure** while protecting the **Spark of Humanity**
meter — keep it alive. Earn two currencies, **Sparks** (primary) and **Scrap**
(secondary); build the run via the **Core Matrix** (ability loadout, keys 1/2/3)
and **Gadgets** (L/R activated items), gaining XP and drafting upgrades.

## The direction (decided 2026-06-20)
Built in **3D with a fixed Diablo-style camera** (looking down ~45°), not 2.5D
sprites. Reason: with a 3D model the engine solves camera angle, facing direction,
and frame-to-frame consistency for free — exactly where AI-generated 2D sprite
sheets fall apart. The old 2.5D sprite scaffolding was removed; recover anything
from git history only if the user explicitly asks for archaeology.

## v1 scope (the only thing we're building first)
Gizmo moves under a fixed Diablo camera; enemies spawn; you fight; you can die;
win/lose screen. **The character is `godot/assets/gizmo.glb` — a meshy.ai model
with a 53-bone rig but no animation clips yet.** v1 moves it with code (no clips
needed); adding a walk/attack clip (via meshy's "Animate", played through an
`AnimationPlayer`) is a *later* lesson, not a v1 blocker. Don't expand scope until
v1 is finished.

## Where each truth lives
- **Premise / story** → `design-handoff/NARRATIVE.md`
- **Balance / design foundation (game-agnostic theory)** →
  `reference/game-balance-reference.md` — formulas, TTK bands, spawn budgets,
  upgrade math. The north star; `simulation.ts` is one implementation of it.
- **Mechanics (one implementation of the above)** →
  `game-src-phaser/src/game/simulation.ts` — the source of truth to port. Port
  logic before scene polish.
- **Feel reference (playable)** → root web build; `npx serve .` and play `index.html`
- **Art direction** → character = `godot/assets/gizmo.glb`; UI & world look =
  `design-handoff/gizmo-hud.png` (the canonical visual target); look governed by
  `design-handoff/ART_DIRECTION.md`. Art is generated fresh (meshy.ai / ludo) to
  match the HUD; do not hand-author.
- **3D character model** → `godot/assets/gizmo.glb` (meshy.ai: 53-bone rig, no clips yet)
- **The Godot build** → `godot/` (snake_case files, PascalCase nodes)
- **Learning path** → `lessons/` (one HTML win each, numbered from `0001`) +
  `learning-records/` (records are drafts until the learner can explain the slice).
  Built so far: `0001`–`0009` — player + fixed Diablo camera, Sparks & leveling,
  run clock & player health, enemies (spawn/chase/separate/contact), and combat
  (auto-fire → death → Spark → XP → level: **the loop is closed**). Next: `0010`
  director-driven enemy pressure (not discrete waves).

## How it's built
Co-development via the `/teach` skill — explain a concept, then build the slice
together in the Godot editor, small enough to absorb. See `CLAUDE.md`.
