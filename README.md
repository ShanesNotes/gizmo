# Gizmo

A **rogue-lite** in which **Gizmo**, a clanker, preserves the **spark of humanity** through escalating **enemy pressure**, across a **gouache cosmos of lost tech**. Originally a Phaser/TS web prototype; **being rebuilt in Godot as a 3D game with a fixed Diablo-style camera**.

**New here? Read `CONTEXT.md` first** — the orientation keystone (what the game is, the 3D direction, v1 scope, where each truth lives).

**Current directive:** this is a clean-slate 3D Godot rebuild. Previous 2.5D /
sprite-first attempts are inactive history and should not steer new work.

## Repo layout
- `assets/` + `index.html` — the **playable web build** (feel reference). Serve the root and play it: `npx serve .`
- `CONTEXT.md` — orientation keystone. `design-handoff/NARRATIVE.md` — premise/story canon.
- `design-handoff/` — **art-direction references**: `NARRATIVE.md` (premise canon), `ART_DIRECTION.md` (the look), `gizmo-hud.png` (canonical UI & world visual target).
- `game-src-phaser/` — the original **Phaser + TypeScript source**; `src/game/simulation.ts` is the mechanics source of truth to port. `node_modules` excluded.
- `godot/` — the **Godot build** (the active path). `godot/assets/gizmo.glb` is the 3D character (meshy.ai: 53-bone rig, no animation clips yet).
- `lessons/`, `learning-records/` — the `/teach` co-development learning path and progress.
- `reference/game-balance-reference.md` — balance knowledge (TTK bands, economy), dimension-agnostic.

## Notes
- The Godot 3D rebuild is the active path; the Phaser source + web build are the reference (mechanics + feel).
- The previous 2.5D sprite scaffolding was removed on 2026-06-20; use it only as archaeology if explicitly requested.
- Do not use the stale concept-art "WAVE x/5" framing as active design; v1 uses director-driven pressure instead of discrete wave rounds.

## Gizmo clean-canvas ecosystem

This folder participates in the Gizmo clean-canvas ecosystem. Read `gizmo-ecosystem.yaml` to route work by specialty before editing cross-domain artifacts.

