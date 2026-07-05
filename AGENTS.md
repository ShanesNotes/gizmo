# AGENTS.md — Gizmo operating directive

This file governs `/home/ark/gizmo` and its children. Read it before editing. If a
deeper `AGENTS.md` exists, it overrides this file for that subtree.

## Current directive (2026-07-04)

Gizmo is being rebuilt from a **clean slate** as a **3D Godot rogue-lite** with a
fixed Diablo-style camera. The default development mode is now **AFK
coding-agent-driven**: bounded agents may implement, verify, and record surgical
changes without requiring teaching-session pacing.

The older `/teach` co-development path, numbered lessons, and learning records are
preserved project history and may resume when the user explicitly asks for teaching.
Do not let teaching-era pacing block normal agent execution.

Act as a professional game developer and expert 3D Godot engineer consulted on the
project. Give practical engineering guidance, use Godot-native 3D patterns, and
keep scope disciplined toward a small playable v1.

## Stale-history rule

Earlier attempts to build Gizmo as **2.5D**, sprite-first, or orthographic
presentation-first are **inactive history**. Do not treat old 2.5D docs, archived
OMX state, backup folders, or git-history scaffolding as active requirements unless
the user explicitly reactivates them. If old material conflicts with the current
3D direction, `CONTEXT.md` wins.

## No-wave rule

Do **not** treat "WAVE x/5", discrete wave rounds, or "waves → elites → bosses"
from stale concept art / older docs as active design. The active v1 model is
director-driven enemy pressure: spawning and intensity ramp under a director (time
plus place-aware exposure, per ADR 0006) without a player-facing wave-round
structure. See `CONTEXT.md` and ADRs 0003/0006.

## Active source anchors

- `CONTEXT.md` — orientation keystone: game direction, loop, v1 scope, truth map.
- `CLAUDE.md` — agent-development memory and operating contract.
- `MISSION.md`, `NOTES.md`, `RESOURCES.md` — teaching history/preferences/resources.
- `design-handoff/NARRATIVE.md` — premise/story canon.
- `design-handoff/ART_DIRECTION.md` and `design-handoff/gizmo-hud.png` — visual target.
- `game-src-phaser/src/game/simulation.ts` — mechanics source of truth to port.
- `reference/game-balance-reference.md` — game-agnostic balance foundation.
- `godot/` — active Godot project; keep all Godot work contained here.
- `docs/afk/queue/` — current local AFK work queue and landing order until imported/synced
  to GitHub issues.
- `tools/godot/run_all_checks.sh` — one-command Godot verification gate.
- `/home/ark/gizmo-audio-canon/` — soundtrack, ambience, SFX canon and Godot audio handoff.
- `/home/ark/gizmo-soundtrack/` — raw soundtrack source pack; source media only, never
  direct runtime imports.

## Work rules

- Build as true 3D: `Node3D`, `CharacterBody3D`, `Camera3D`, `MeshInstance3D`, and
  `godot/assets/gizmo.glb` for Gizmo.
- Keep the first shipped target small: Gizmo moves, enemies spawn, combat happens,
  enemy pressure ramps, and the game can win/lose.
- Do not revive 2.5D sprite scaffolding, legacy lesson drafts, or old generated
  docs as active architecture.
- Do not rewrite the Phaser source, root web build, or `design-handoff/NARRATIVE.md`.
- Prefer small, verified slices with executable success criteria. Keep changes
  reviewable and record durable outcomes in the tracker or Daily ledger.
- For Godot concepts, ground advice in GodotPrompter skills / official docs before
  teaching; do not guess APIs.
- Use snake_case files/folders and PascalCase node names / `class_name`s in Godot.
- Verify before claiming completion: at minimum inspect diffs; run relevant Godot,
  test, lint, or static checks when code changes.
- Use `gizmo-3d` as the active game branch unless the human explicitly changes
  branch authority. Do not treat remote `main` as the Path A implementation line.
- `docs/afk/queue/` is the current local queue for AFK pickup; GitHub issues are the
  durable external tracker once the queue is imported/synced. Use `ready-for-agent`
  for bounded agent work, `ready-for-human` for approval/decision items, and
  `needs-info` for load-bearing unknowns.

## Gizmo clean-canvas ecosystem

This folder participates in the Gizmo clean-canvas ecosystem. Read `gizmo-ecosystem.yaml` to route work by specialty before editing cross-domain artifacts.
