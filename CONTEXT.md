# CONTEXT — Gizmo (3D)

Orientation keystone. Read first; if other docs disagree, this wins.

## What the game is
A **bullet-heaven / survivors-like**: **Gizmo**, a clanker, preserves the **spark
of humanity** against encroaching dehumanized tech, across a **gouache cosmos of
lost tech**. Premise canon: `design-handoff/NARRATIVE.md`.

## The direction (decided 2026-06-20)
Built in **3D with a fixed Diablo-style camera** (looking down ~45°), not 2.5D
sprites. Reason: with a 3D model the engine solves camera angle, facing direction,
and frame-to-frame consistency for free — exactly where AI-generated 2D sprite
sheets fall apart. The old 2.5D sprite scaffolding was removed; recover anything
from git history if needed.

## v1 scope (the only thing we're building first)
Gizmo moves under a fixed Diablo camera; enemies spawn; you fight; you can die;
win/lose screen. **The character is `godot/assets/gizmo.glb` — a meshy.ai model
with a 53-bone rig but no animation clips yet.** v1 moves it with code (no clips
needed); adding a walk/attack clip (meshy "Animate" or Mixamo, played via
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
- **Visual art** → generated fresh (AI / ludo) per the 3D direction. The old Lumen
  Codex design system was dropped; recover palette/tokens from git history if wanted.
- **3D character model** → `godot/assets/gizmo.glb` (meshy.ai: 53-bone rig, no clips yet)
- **The Godot build** → `godot/` (snake_case files, PascalCase nodes)
- **Learning path** → `lessons/` (foundations 0001–0006 are dimension-agnostic and
  done; 0007–0008 were 2D-flavored, concepts transfer), `learning-records/`

## How it's built
Co-development via the `/teach` skill — explain a concept, then build the slice
together in the Godot editor, small enough to absorb. See `CLAUDE.md`.
