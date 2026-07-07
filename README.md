# Gizmo

A 3D Godot rogue-lite (Hades-like on `gizmo-3d` / audio worktree lanes). Phaser/TS web prototype + design-handoff are historical reference; active implementation and facets are Godot + sibling labs.

## Repo layout
- **`GODOT-PORT.md`** — port notes (mechanics/look/feel reference).
- `godot/` — the active **Godot 4 implementation** (scenes, scripts, assets, tests in `godot/tests/`, tools/godot/).
- `game-src-phaser/` — the original **Phaser + TypeScript source** (mechanics reference). `node_modules` excluded.
- `design-handoff/` — art direction, Fusion Codex, assets, image backlog.
- `design-system/` — tokens, UI witnesses (small committed set).
- `tools/`, `docs/`, `assets/`, `art/` — supporting.

## Notes
- Primary branch for active work: audio/mix-architecture-2026-07-07 (and gizmo-3d). Facets live in separate roots: gizmo-{lore,design-system,asset-pipeline,audio-canon,level-design}.
- Generated (`.godot/`, `_quarantine/`, `.scratch/`) are untracked per .gitignore.
- Palette/asset truth routes through owning facet labs + promotion.
