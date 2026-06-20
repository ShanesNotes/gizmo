# Gizmo

A **bullet-heaven / survivors-like**: **Gizmo**, a clanker, preserves the **spark of humanity**, protecting it from ever-encroaching dehumanized technology, across a **gouache cosmos filled with lost tech**. Originally a Phaser/TS web prototype; **being rebuilt in Godot as a 3D game with a fixed Diablo-style camera**.

**New here? Read `CONTEXT.md` first** — the orientation keystone (what the game is, the 3D direction, v1 scope, where each truth lives).

## Repo layout
- **`CONTEXT.md`** — orientation keystone. **`design-handoff/NARRATIVE.md`** — premise/story canon.
- `godot/` — the **Godot build** (the active path). `godot/assets/gizmo.glb` is the 3D character (meshy.ai: 53-bone rig, no animation clips yet).
- `game-src-phaser/` — the original **Phaser + TypeScript source**; `src/game/simulation.ts` is the mechanics source of truth to port. `node_modules` excluded.
- `index.html`, `assets/` — the **playable web build** (feel reference). Serve the root and play it: `npx serve .`
- `design-system/` — the **Lumen Codex** design system: tokens, components, UI motifs. The look/aesthetic.
- `reference/game-balance-reference.md` — balance knowledge (TTK bands, economy), dimension-agnostic.
- `lessons/`, `learning-records/` — the `/teach` co-development learning path and progress.

## Notes
- The Godot 3D rebuild is the active path; the Phaser source + web build are the reference (mechanics + feel).
- The previous 2.5D sprite scaffolding was removed on 2026-06-20; it lives in git history if needed.
