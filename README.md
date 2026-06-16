# Gizmo

A kid-friendly **bullet-heaven / survivors-like**: **Gizmo**, a clanker, preserves the **spark of humanity**, protecting it from ever-encroaching dehumanized technology, across a **gouache cosmos filled with lost tech**. Currently a Phaser/TS web prototype; **being ported to Godot**.

**New here? Read `CONTEXT.md` first** — the orientation keystone (domain language, architecture, doc map).

## Repo layout
- **`CONTEXT.md`** — orientation keystone: what the game is, how it's built/taught, and where each truth lives. **`design-handoff/NARRATIVE.md`** — the premise/story canon.
- **`GODOT-PORT.md`** — start here if you're porting: what to read and how the pieces map to Godot.
- `game-src-phaser/` — the original **Phaser + TypeScript source** (the mechanics source of truth; `src/game/simulation.ts` is the core logic). `node_modules` excluded — run `npm install` to build.
- `design-system/` — the **Claude Design output** ("The Lumen Codex"): tokens, React components, UI-kit screens, `SKILL.md`. The look, ready for Claude Code to implement.
- `design-handoff/` — the full **art direction**: art bible, the Fusion Codex, screen mockups, SVG assets, brand emblems, image-model backlog, Claude Design setup guide. Start at `design-handoff/README.md`.
- `index.html`, `assets/`, `art/` — the **playable build** (Vite output). Serve the root and play it: `npx serve .`

## Notes
- The Godot rebuild is the active path; the Phaser source + web build are the reference (mechanics + feel).
- Palette/type/asset truth: `design-system/tokens/` and `design-handoff/FUSION-CODEX.md`.
