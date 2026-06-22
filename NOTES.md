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
The target is a **playable v1**: move under a fixed Diablo camera, enemies spawn and
fight; then (Path A pivot) traverse to **rekindle a Beacon**. Port logic before polish.

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
- **0006 — Sparks & leveling, test-first.** ✅ Done. Ported `next_xp_for_level`,
  `add_xp` (remainder carry), and `xp_progress` from `simulation.ts` into
  `scripts/simulation.gd` with a headless test runner. Sparks = the `xp` currency
  (NARRATIVE §4) — *not* the Spark of Humanity survival meter.
- **0007 — Run timer & health, test-first.** Port `runProgress` / `timeRemaining`
  and player **HP** (damage / death / lose-on-death) into `simulation.gd`, still
  headless. The **Spark of Humanity** is a *separate* objective meter (ADR 0001,
  mechanics TBD) — not this lesson. Win: red→green tests for the run state.
- **0008 — Enemies spawn** and move toward Gizmo.
- **0009 — Combat.**  Gizmo hits; enemies take damage and die.
- **0010 — Director-driven pressure.**  Spawn-budget escalation via a pressure
  director — no discrete waves (ADR 0003); grounded in the balance reference.
- **0011 — HUD.**  Match `design-handoff/gizmo-hud.png` (HP bar, Sparks/Scrap, level,
  Spark of Humanity meter — all distinct, per ADR 0001).
- **0012 — Win/lose screens → playable v1 loop.**
- **0013 — Balance pass.**  Natural lethality + enemy role variety, pinned by a
  deterministic sim-profile regression guard.
- **0014 — Enemies respect obstacles.**  Circular push-out so enemies don't clip props.
- **0015 — Melee-start weapon progression.**  Gizmo starts melee; the ranged Spark
  Chain becomes the first draftable upgrade (ADR 0004).

### Next — the Path A loop refactor (ADRs 0005–0008)
Replace survive-the-timer with **traverse-and-rekindle**: win = Beacon Rekindled,
lose = HP 0; place-aware director pressure; guard-over-HP + sanctuary recharge.
See `docs/path-a-shattered-meridian-spec.md`.

### Later (post-v1, do not pull forward)
Animation clips (rig → walk/attack), elites/bosses depth, upgrades (Core Matrix /
Gadgets), audio integration (soundtrack already local in `godot/audio/`), art polish,
export pipeline.

## Conventions in play
- GDScript (not C#), even though the Godot binary is the mono build.
- snake_case files, PascalCase nodes/`class_name`.
- Ground every Godot concept in a GodotPrompter skill before teaching it.
- Verify each slice (Play in editor, or headless via the godot-runtime MCP).
