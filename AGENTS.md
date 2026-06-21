# AGENTS.md — Gizmo operating directive

This file governs `/home/ark/gizmo` and its children. Read it before editing. If a
deeper `AGENTS.md` exists, it overrides this file for that subtree.

## Current directive (2026-06-20)

Gizmo is being rebuilt from a **clean slate** as a **3D Godot rogue-lite** with a
fixed Diablo-style camera. The active co-development path is the user working with
Claude through the `/teach` skill; every slice should preserve understanding over
black-box completion.

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
director-driven enemy pressure: spawning and intensity ramp over time without a
player-facing wave-round structure. See `CONTEXT.md` and ADR 0003.

## Active source anchors

- `CONTEXT.md` — orientation keystone: game direction, loop, v1 scope, truth map.
- `CLAUDE.md` — Claude `/teach` co-development memory and operating contract.
- `MISSION.md`, `NOTES.md`, `RESOURCES.md` — teaching mission, preferences, resources.
- `design-handoff/NARRATIVE.md` — premise/story canon.
- `design-handoff/ART_DIRECTION.md` and `design-handoff/gizmo-hud.png` — visual target.
- `game-src-phaser/src/game/simulation.ts` — mechanics source of truth to port.
- `reference/game-balance-reference.md` — game-agnostic balance foundation.
- `godot/` — active Godot project; keep all Godot work contained here.

## Work rules

- Build as true 3D: `Node3D`, `CharacterBody3D`, `Camera3D`, `MeshInstance3D`, and
  `godot/assets/gizmo.glb` for Gizmo.
- Keep the first shipped target small: Gizmo moves, enemies spawn, combat happens,
  enemy pressure ramps, and the game can win/lose.
- Do not revive 2.5D sprite scaffolding, legacy lesson drafts, or old generated
  docs as active architecture.
- Do not rewrite the Phaser source, root web build, or `design-handoff/NARRATIVE.md`.
- Prefer small, teachable, verified slices. Explain any model-authored changes so
  the learner can repeat or describe them.
- For Godot concepts, ground advice in GodotPrompter skills / official docs before
  teaching; do not guess APIs.
- Use snake_case files/folders and PascalCase node names / `class_name`s in Godot.
- Verify before claiming completion: at minimum inspect diffs; run relevant Godot,
  test, lint, or static checks when code changes.
