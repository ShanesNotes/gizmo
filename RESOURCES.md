# Gizmo Godot Resources

## Knowledge

- [Official Godot 4.6 documentation](https://docs.godotengine.org/en/stable/)
  Primary source for GDScript, scenes/nodes, `Node3D`/`Camera3D`/`CharacterBody3D`,
  importing `.glb`, `AnimationPlayer`, signals, headless runs. Use for: any Godot
  concept before teaching it. Never trust parametric memory over the docs.
- `CONTEXT.md` (repo)
  Orientation keystone — what the game is, the 3D direction, v1 scope, where each
  truth lives. Use for: getting oriented; resolving "where does this live?".
- `design-handoff/NARRATIVE.md` (repo)
  Premise/story canon. Use for: any fiction or premise question.
- `reference/game-balance-reference.md` (repo)
  Game-agnostic design foundation — formulas, TTK bands, spawn/upgrade math. Use
  for: tuning intent and survivors-like balance principles.
- `game-src-phaser/src/game/simulation.ts` (repo)
  Mechanics source of truth (pure logic). Use for: the exact rules to port.
- Root web build (`index.html` + `assets/`, `npx serve .`)
  Playable feel reference. Use for: checking that the Godot port feels right.

## Wisdom (Communities)

- [r/godot](https://reddit.com/r/godot) — active, beginner-friendly. Use for: "is
  this the Godot way?", troubleshooting, project critique.
- [Godot Q&A / forum](https://forum.godotengine.org/) — searchable, high-signal.

## Tools

- **meshy.ai** — generated `gizmo.glb` (53-bone rig). Use its "Animate" feature to
  add walk/idle/attack clips, then export with animations selected.
- **Mixamo** (free) — humanoid animation library; retarget onto the rig in Godot.
- **ludo.ai** — environment/asset ideation. Use sparingly; environment art is a
  scope trap until v1's loop is fun.
