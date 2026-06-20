# CLAUDE.md — Gizmo (3D rogue-lite) · Godot co-development teaching memory

## Read first (source anchors)
- `CONTEXT.md` — orientation keystone: the game, the 3D direction, **the loop**, v1 scope,
  and where each truth lives. If docs disagree, it wins.
- `design-handoff/NARRATIVE.md` — premise/story canon: a **rogue-lite** where Gizmo the
  clanker preserves the **spark of humanity** through escalating **waves → elites → bosses**,
  in a gouache cosmos of lost tech.
- `design-handoff/ART_DIRECTION.md` + `gizmo-hud.png` — the look (gouache cosmos, brass UI,
  the HUD to match). `godot/assets/gizmo.glb` — the character (meshy.ai, 53-bone rig, no
  animation clips yet; v1 moves it with code, clips are a later lesson).
- `reference/game-balance-reference.md` — game-agnostic balance foundation (TTK bands,
  wave/spawn/upgrade math); the north star for tuning.
- `game-src-phaser/src/game/simulation.ts` — mechanics source of truth; port it before scene polish.
- Root web build (`npx serve .`, play `index.html`) — feel reference.
- Direction: **3D, fixed Diablo-style camera** (decided 2026-06-20). Target **Godot 4.6.x stable**.

## Engineering directive — lead with the skills
This is a co-development *teaching* project; the available skills are the engineering method.
Reach for the right one by situation rather than free-handing it:

| When you're… | Use |
|---|---|
| teaching the next slice / computing the next lesson | **`/teach`** — the engine (editor-first, paced) |
| deciding how a ported piece should be shaped (seams, deep modules, AI-navigable GDScript) | **`codebase-design`** |
| porting/writing logic that can run headless (e.g. `simulation.gd`) | **`tdd`** — red→green→refactor |
| chasing a bug, crash, or perf regression | **`diagnosing-bugs`** |
| pinning down domain terms / system↔fiction language | **`domain-modeling`** (language grows into `CONTEXT.md`) |
| stress-testing a plan or scope *before* building (scope-creep guard) | **`grilling`** |
| reviewing a finished slice's diff (standards + spec) | **`review`** |
| drafting/sharpening a lesson explainer or writing about the build | **`writing-shape`**, **`writing-beats`**, **`writing-fragments`** |
| resolving a merge/rebase | **`resolving-merge-conflicts`** |

Default to a skill before improvising, and compose them — e.g. `grilling` a slice →
`codebase-design` the seam → `tdd` the logic → `review` the diff → `/teach` capture the lesson.
**Not used here:** `scaffold-exercises` and `migrate-to-shoehorn` are TypeScript/ai-hero-cli
specific (our lessons are HTML + live Godot actions); skip unless we deliberately adapt the concept.

## Godot skills & tooling
Ground every Godot concept in the **GodotPrompter** library before teaching it — never guess
the API. Bootstrap with `godot-prompter:using-godot-prompter`, then pull the skill matching the slice:

| Build phase | godot-prompter skill(s) |
|---|---|
| project + scene setup, hierarchy | `godot-project-setup`, `scene-organization` |
| fixed Diablo camera, 3D world | `camera-system`, `3d-essentials` |
| Gizmo movement + input | `player-controller`, `input-handling` |
| porting `simulation.ts` logic | `gdscript-patterns`, `gdscript-advanced`, `state-machine`, `resource-pattern` |
| enemies / waves → elites → bosses | `ai-navigation`, `state-machine` |
| HUD (match `gizmo-hud.png`) | `hud-system`, `godot-ui`, `responsive-ui` |
| cross-system messaging | `event-bus`, `component-system`, `dependency-injection` |
| headless tests & debugging | `godot-testing`, `godot-debugging` |
| animation (rig → clips, later) | `animation-system`, `tween-animation` |
| VFX / shaders / perf (later) | `particles-vfx`, `shader-basics`, `godot-optimization` |
| v1 ship | `export-pipeline` |

**Specialist agents** for deep or independent work (not to replace the learner's editor clicks):
`godot-game-architect` (design a system), `godot-game-dev` (implement), `godot-animator`
(rig → walk/attack clips), `godot-ui-designer` (the HUD Control tree), `godot-code-reviewer`
(quality pass), `godot-performance-profiler` (stutter/frame drops), `godot-shader-author` (VFX).

**`godot-runtime` MCP (connected) — verify and inspect, don't build.** Use it to check the
learner's work and show it running: `validate`, `run_project` + `take_screenshot`,
`get_scene_tree`, `get_debug_output`, `simulate_input`. **Editor-first stands:** the learner
creates scenes/nodes/scripts by hand in the Godot editor; the MCP gives feedback and proof-of-life,
it does not author the slices they should build themselves.

## Teaching contract (the `/teach` engine)
A slow-down-and-learn *co-development* effort — not "watch the AI build," not "type everything yourself."
- Co-development, paced: explain a concept, then build the slice *together* in the Godot
  editor. Claude writing code is fine; pacing for understanding is the point.
- **Editor-first:** lessons are real actions in the Godot editor, not CLI file-authoring.
- Keep the learner in the loop on every decision; avoid a finished black box they can't explain.
- Lessons = self-contained HTML in `lessons/` (numbered from `0001`), one win each. The build
  starts fresh at `0001`; `learning-records/` is empty = from-zero.
- Verify (or name the command) after each slice; ask at most one scope question when it changes the next step.

## Godot rules
- Keep the Godot project contained under `godot/`.
- snake_case filenames/folders (`simulation.gd`, `main.tscn`, `theme.tres`); PascalCase node
  names and `class_name` identifiers (`Simulation`).
- Scenes for composition, scripts for behavior, resources/themes for data.
- 3D: `CharacterBody3D` for Gizmo, `Camera3D` fixed at a Diablo angle, `MeshInstance3D` loading `gizmo.glb`.
- Headless-first: `simulation.ts` → `godot/scripts/simulation.gd` + `godot/tests/run_simulation_tests.gd`.

## Commands & gates
- Feel check: `npx serve .` from repo root.
- Godot version: `${GODOT_BIN:-godot} --version`.
- Import: `${GODOT_BIN:-godot} --headless --path godot --import`.
- Syntax check: `${GODOT_BIN:-godot} --headless --path godot --check-only --script res://scripts/simulation.gd`.
- Tests: `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd`.

## Project conventions ("set up like that")
- **Decisions** → `docs/adr/` (one ADR per locked choice; recorded via `domain-modeling`).
  **Domain language** grows into `CONTEXT.md` — add a term only once the learner can use it.
- **Issues / PRDs** (only if/when work needs tracking) → `.scratch/` markdown.
- **Git:** branch off `main`; commit/push only when asked. End commit messages with the
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` line.

## Boundaries
- Do not rewrite the Phaser source, root web build, or `design-handoff/NARRATIVE.md`.
- Do not stage `node_modules/`, `dist/`, `godot/.godot/`, exports, or generated cache.
- Do not attempt a full port in one lesson. Do not expand past v1 scope until v1 ships.

## Next lesson workflow
1. Run `/teach`; read `learning-records/` (zone of proximal development) and `CONTEXT.md` (v1 scope spine).
2. Cite the `simulation.ts` file/line for the slice; if shaping a module, pull in
   `codebase-design`; if it's testable logic, `tdd` it.
3. Co-develop the slice in `godot/` — small enough to absorb; capture it as HTML in `lessons/`.
4. `review` the diff, verify, and write a `learning-records/` entry when understanding is shown.
