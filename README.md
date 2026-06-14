# Gizmo

A kid-friendly **bullet-heaven / survivors-like** — *"The Lumen Codex"*: a neon spark re-illuminates an ancient codex (ancient illuminated-manuscript symbolism × futuristic arcade). Currently a Phaser/TS web prototype; **being ported to Godot**.

## Repo layout
- **`GODOT-PORT.md`** — start here if you're porting: what to read and how the pieces map to Godot.
- `game-src-phaser/` — the original **Phaser + TypeScript source** (the mechanics source of truth; `src/game/simulation.ts` is the core logic). `node_modules` excluded — run `npm install` to build.
- `design-system/` — the **Claude Design output** ("The Lumen Codex"): tokens, React components, UI-kit screens, `SKILL.md`. The look, ready for Claude Code to implement.
- `design-handoff/` — the full **art direction**: art bible, the Fusion Codex, screen mockups, SVG assets, brand emblems, image-model backlog, Claude Design setup guide. Start at `design-handoff/README.md`.
- `index.html`, `assets/`, `art/` — the **playable build** (Vite output). Serve the root and play it: `npx serve .`

## Notes
- The Godot rebuild is the active path; the Phaser source + web build are the reference (mechanics + feel).
- Palette/type/asset truth: `design-system/tokens/` and `design-handoff/FUSION-CODEX.md`.
