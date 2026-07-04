# Gizmo Godot Resources

## Knowledge

- [Official Godot documentation](https://docs.godotengine.org/en/stable/)
  Primary source for GDScript, scenes/nodes, `Node3D`/`Camera3D`/`CharacterBody3D`,
  importing `.glb`, `AnimationPlayer`, signals, headless runs. Use for: any Godot
  concept before teaching it. Never trust parametric memory over the docs.
- **GodotPrompter skills** (`godot-prompter:*`; bootstrap `using-godot-prompter`)
  Curated Godot 4.x knowledge modules — `player-controller`, `3d-essentials`,
  `camera-system`, `hud-system`, `state-machine`, `godot-testing`, and more. Use for:
  grounding any Godot slice before teaching it; see CLAUDE.md for the phase→skill map.
- `CONTEXT.md` (repo)
  Orientation keystone — what the game is, the 3D direction, v1 scope, where each
  truth lives. Use for: getting oriented; resolving "where does this live?".
- `design-handoff/NARRATIVE.md` (repo)
  Premise/story canon. Use for: any fiction or premise question.
- `design-handoff/ART_DIRECTION.md` (repo)
  Governing look-and-feel doc — palette, brass UI frames, HUD anatomy. Use for: any
  visual / art-direction decision.
- `design-handoff/gizmo-hud.png` (repo)
  Canonical UI/world art reference — the gouache cosmos look, brass/bronze filigree
  frames, cyan/teal energy, violet spark motif. Use for: matching UI and world visuals.
- `godot/assets/gizmo.glb` (repo)
  Canonical character reference (meshy.ai, 53-bone rig). Use for: Gizmo's model.
- `reference/game-balance-reference.md` (repo)
  Game-agnostic design foundation — formulas, TTK bands, spawn/upgrade math. Use
  for: tuning intent and enemy-escalation / pressure balance principles (theory).
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
- **ludo.ai** — environment/asset ideation. Use sparingly; environment art is a
  scope trap until v1's loop is fun.
- **godot-runtime MCP** (when connected) — drive/inspect the Godot project: `validate`,
  `run_project`, `take_screenshot`, `get_scene_tree`, `simulate_input`. Use for:
  verifying the learner's editor work and showing it running — not for building it.
