# Mission: Build Gizmo in Godot (3D), from zero

## Why
Build **Gizmo** — a **rogue-lite** in which **Gizmo**, a clanker, preserves the
**spark of humanity** through increasingly difficult **waves of enemies, elites, and
bosses**, across a **gouache cosmos of lost tech** (premise:
`design-handoff/NARRATIVE.md`) — in Godot as a **3D game with a fixed Diablo-style
camera**, *co-developing it with an AI teacher* and deliberately slowing down to
understand each piece instead of being handed a black box. The journey doubles as a
from-zero guide to co-developing a game in Godot with Claude Code and the teach skill.
First-time game developer; the real goal is to **finish and ship a small game** —
scope discipline over ambition. Orientation: `CONTEXT.md`.

## Success looks like
- Comfortable in Godot 3D: creating a project, scenes, GDScript, a `Camera3D` rig
- Gizmo (`godot/assets/gizmo.glb`) moving on screen under the Diablo camera
- The core loop ported from `simulation.ts` into GDScript I understand and can explain
  (movement, escalating waves -> elites -> bosses, protecting the Spark of Humanity,
  XP/level, the economies)
- A **playable v1**: survive waves, protect the Spark, fight, die, win/lose screen —
  finished, not perfect
- A `lessons/` guide that reads cleanly from zero for someone else

## Constraints
- Co-development pace: explain, then build the slice together; keep slices small.
- Editor-first by default, but flexible: the learner can hand a slice to the model,
  which then explains what it built.
- Art is generated (meshy.ai / ludo); don't hand-author assets.

## Out of scope (until v1 ships)
- Skeletal animation clips (the rig exists; clips are a later lesson)
- Procedural/generated environments beyond a ground plane + a few props
- Multiplayer, save systems, polish passes, new mechanics beyond the ported loop
