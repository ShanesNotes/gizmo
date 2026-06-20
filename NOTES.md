# Teaching notes — Gizmo (3D)

Working scratchpad for the `/teach` engine. Preferences + the lesson roadmap.
Not canon — `CONTEXT.md` wins. The roadmap flexes to the learner's ZPD.

## Learner & pace preferences
- First-time game developer. Goal is to **finish and ship a small v1**, not to be
  comprehensive. Scope discipline over ambition (see memory: working-style).
- Wants honest pushback when a slice is scope creep.
- Co-development pace: **explain the concept, then build the slice together.**
- **Mode is the learner's call, per slice.** Default is hands-on (drive the editor
  yourself the first time — it builds intuition). Any slice can be handed to the
  model, which then walks through what it built and why. Config/boilerplate
  (`project.godot`, ignore files) is fine for the model to author + explain — you
  don't learn that by typing it.
- Commits: "a bit longer, reasonable size" — one commit per completed lesson slice,
  not per file. Commit when the slice is built + verified.

## Lesson roadmap (v1 path — the spine, subject to change)
The only target is a **playable v1**: move under a fixed Diablo camera, enemies
spawn, fight, die, win/lose. Port logic before polish.

- **0001 — First 3D project + a scene you can see.**  Fresh Forward+ project (done),
  then a `Main` scene: `Node3D` root, `Camera3D`, `DirectionalLight3D`, a ground
  plane + a placeholder box. Win: press Play → a lit 3D world.
- **0002 — The fixed Diablo camera.**  Lock the camera to the iconic ARPG down-angle
  (~50°), fixed (no rotation). Win: the signature look.
- **0003 — Gizmo enters the world.**  Swap the placeholder for `gizmo.glb` on the
  floor. Win: Gizmo stands lit under the camera.
- **0004 — Move Gizmo with code.**  `CharacterBody3D` + an Input Map + WASD → velocity.
  Win: drive Gizmo around the floor.
- **0005 — Face movement + camera follow.**  Gizmo turns toward travel; camera tracks.
- **0006 — Headless logic, test-first.**  Port the first slice of `simulation.ts`
  (e.g. the Spark meter or wave timer) into `simulation.gd` with a test runner (TDD).
  Win: a passing GDScript test, no scene needed.
- **0007 — Enemies spawn** and move toward Gizmo.
- **0008 — Combat.**  Gizmo hits; enemies take damage and die.
- **0009 — Waves.**  The wave/spawn budget loop (grounded in the balance reference).
- **0010 — The Spark of Humanity meter + lose condition.**
- **0011 — HUD.**  Match `design-handoff/gizmo-hud.png` (health/Spark, currencies).
- **0012 — Win/lose screens → playable v1 loop.**

### Later (post-v1, do not pull forward)
Animation clips (rig → walk/attack), elites/bosses depth, upgrades (Core Matrix /
Gadgets), audio integration (soundtrack already local in `godot/audio/`), art polish,
export pipeline.

## Conventions in play
- GDScript (not C#), even though the Godot binary is the mono build.
- snake_case files, PascalCase nodes/`class_name`.
- Ground every Godot concept in a GodotPrompter skill before teaching it.
- Verify each slice (Play in editor, or headless via the godot-runtime MCP).
