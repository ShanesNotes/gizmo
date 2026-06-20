# CLAUDE.md — Gizmo Godot teaching memory

## Project truths and source anchors
- `CONTEXT.md` is the orientation keystone (what the game is, the 3D direction, v1
  scope, where each truth lives). Read it first; if docs disagree, it wins.
- Premise canon is `design-handoff/NARRATIVE.md`: a **rogue-lite** in which Gizmo the
  clanker preserves the spark of humanity through escalating waves -> elites -> bosses,
  in a gouache cosmos of lost tech.
- Direction: **3D with a fixed Diablo-style camera** (decided 2026-06-20). Not 2.5D
  sprites — the old sprite scaffolding was removed; it's in git history if needed.
- `reference/game-balance-reference.md` is the game-agnostic design foundation
  (formulas, TTK bands, spawn/upgrade math) — the north star for tuning.
- `game-src-phaser/src/game/simulation.ts` is the mechanics source of truth (one
  implementation of the balance reference). Port it before scene polish.
- `godot/assets/gizmo.glb` is the 3D character: a meshy.ai model with a 53-bone rig
  but no animation clips yet. v1 moves it with code; adding clips (meshy "Animate" or
  Mixamo, via `AnimationPlayer`) is a later lesson.
- Art direction: `godot/assets/gizmo.glb` (character) + `design-handoff/gizmo-hud.png`
  (UI/world look), governed by `design-handoff/ART_DIRECTION.md`.
- Visual art is generated fresh (AI / ludo), targeting `design-handoff/gizmo-hud.png`.
  The old Lumen Codex design system was dropped; recover from git history if a palette
  reference is wanted.
- The root playable web build is the feel reference: `npx serve .` and play `index.html`.
- Target Godot: 4.6.x stable (repo verified locally with 4.6.2.stable.mono.official).

## Teaching contract (co-development, paced for understanding)
The engine is the `/teach` skill. This is a slow-down-and-learn *co-development*
effort, not "watch the AI build" and not "type everything yourself."
- Claude is a co-developer and teacher: explain a concept, then build the slice
  *together* in the Godot editor. Claude writing code is fine — pacing for
  understanding is the point.
- **Editor-first.** Lessons are real actions in the Godot editor, not CLI
  file-authoring. The optimization target: teaching how to co-develop a game in
  Godot with Claude Code + the teach skill.
- Keep the learner in the loop on each decision. Avoid a finished black box they
  can't explain — prefer small slices with a pause to absorb.
- Lessons are self-contained HTML in `lessons/` (numbered `0001-…`), one win each.
  The 3D rogue-lite build starts fresh at `0001` — no lessons completed yet (earlier
  2.5D-era drafts were removed; in git history).
- Compute the next lesson from `learning-records/` (empty = from-zero guide).
- Run or name the verification command after each slice; ask at most one scope
  question when it changes the next step.

## Godot rules
- Keep the Godot project contained under `godot/`.
- Use snake_case filenames/folders: `simulation.gd`, `main.tscn`, `theme.tres`.
- Use PascalCase Godot node names and `class_name` identifiers, e.g. `Simulation`.
- Prefer scenes for composition, scripts for behavior, resources/themes for data.
- 3D: `CharacterBody3D` for Gizmo, `Camera3D` fixed at a Diablo angle, `MeshInstance3D`
  loading `gizmo.glb`.
- Start headless: `simulation.ts` → `godot/scripts/simulation.gd` +
  `godot/tests/run_simulation_tests.gd`.

## Commands and gates
- Feel check: `npx serve .` from repo root.
- Godot version: `${GODOT_BIN:-godot} --version`.
- Godot import: `${GODOT_BIN:-godot} --headless --path godot --import`.
- Godot syntax: `${GODOT_BIN:-godot} --headless --path godot --check-only --script res://scripts/simulation.gd`.
- Godot tests: `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd`.

## Boundaries
- Do not rewrite the Phaser source, root web build, or `design-handoff/NARRATIVE.md`.
- Do not stage `node_modules/`, `dist/`, `godot/.godot/`, exports, or generated cache.
- Do not attempt a full port in one lesson. Do not expand past v1 scope until v1 ships.

## Next lesson workflow
1. Run the `/teach` skill from this directory; read `learning-records/` for the zone
   of proximal development and `CONTEXT.md` for the v1 scope spine.
2. Cite the `simulation.ts` file/line anchor for the slice being ported.
3. Co-develop that slice in `godot/` — explain, build together, keep it small enough
   to absorb; capture the lesson as HTML in `lessons/`.
4. Verify, and write a `learning-records/` entry when the learner demonstrates
   understanding.
