# CLAUDE.md — Gizmo (3D rogue-lite) · Godot agent-development memory

## Current operating directive (2026-07-04)
You are supporting a **clean-slate 3D Godot rebuild** of Gizmo as a professional
game developer / expert 3D Godot engineer. The default path is now **AFK
coding-agent-driven development**: bounded, verified agent slices with explicit
success criteria and tracker/Daily handoff. The older `/teach` path remains
available when the user explicitly asks to resume teaching.

Prior 2.5D, sprite-first, or orthographic-presentation attempts are **inactive
history** unless the user explicitly reactivates them. When stale docs disagree
with the clean-slate 3D direction, `CONTEXT.md` wins.

## Read first (source anchors)
- `CONTEXT.md` — orientation keystone: the game, the 3D direction, **the loop**, v1 scope,
  and where each truth lives. If docs disagree, it wins.
- `design-handoff/NARRATIVE.md` — premise/story canon: a **rogue-lite** where Gizmo the
  clanker preserves the **spark of humanity** in a gouache cosmos of lost tech. If it uses
  "waves" language, treat that as older escalation wording; `CONTEXT.md`'s no-wave correction wins.
- `design-handoff/ART_DIRECTION.md` + `design-handoff/gizmo-hud.png` — the look (gouache cosmos, brass UI,
  the HUD to match). `godot/assets/gizmo.glb` — the character (meshy.ai, 53-bone rig, no
  animation clips yet; v1 moves it with code, clips are a later lesson).
- `reference/game-balance-reference.md` — game-agnostic balance foundation (TTK bands,
  spawn pressure / upgrade math); the north star for tuning.
- `game-src-phaser/src/game/simulation.ts` — mechanics source of truth; port it before scene polish.
- Root web build (`npx serve .`, play `index.html`) — feel reference.
- Direction: **3D, fixed Diablo-style camera** (decided 2026-06-20). Current local
  baseline and project config target Godot 4.7 stable with the Godot 4.x Forward+
  renderer.
- `AGENTS.md` — Codex/agent operating directive; mirrors the clean-slate 3D rule for non-Claude agents.

## Engineering directive — lead with the skills
This is now an agent-driven build; the available skills are the engineering method.
Reach for the right one by situation rather than free-handing it. Use `/teach` only
when the user asks for a teaching session:

| When you're… | Use |
|---|---|
| teaching the next slice / computing the next lesson | **`/teach`** — explicit teaching mode only |
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
| enemies / director-driven pressure escalation | `ai-navigation`, `state-machine` |
| HUD (match `design-handoff/gizmo-hud.png`) | `hud-system`, `godot-ui`, `responsive-ui` |
| cross-system messaging | `event-bus`, `component-system`, `dependency-injection` |
| headless tests & debugging | `godot-testing`, `godot-debugging` |
| animation (rig → clips, later) | `animation-system`, `tween-animation` |
| VFX / shaders / perf (later) | `particles-vfx`, `shader-basics`, `godot-optimization` |
| v1 ship | `export-pipeline` |

**Specialist agents** for deep or independent work (not to replace the learner's editor clicks):
`godot-game-architect` (design a system), `godot-game-dev` (implement), `godot-animator`
(rig → walk/attack clips), `godot-ui-designer` (the HUD Control tree), `godot-code-reviewer`
(quality pass), `godot-performance-profiler` (stutter/frame drops), `godot-shader-author` (VFX).

**`godot-runtime` MCP (when connected) — use it for live inspection/verification, and
explain what you do.** Two modes: *inspect/verify* (`validate`, `run_project` +
`take_screenshot`, `get_scene_tree`, `get_debug_output`, `simulate_input`) to check work and
show it running; and *build* when the learner asks (`create_scene`, `add_node`,
`attach_script`, …) — after which you walk through what you created and why, so it's
understood rather than a black box. In Codex sessions where the MCP is not exposed,
use the documented headless commands instead.

## Teaching contract (explicit `/teach` mode)
A slow-down-and-learn *co-development* effort. The bar is **understanding** — never a finished
black box the learner can't explain. This applies only when the user asks to work
through teaching mode. How hands-on they are is their call, slice by slice.
- Explain a concept, then build the slice *together*. The learner can drive it by hand in the
  editor, or hand it to the model — when the model builds it (authoring files or via the
  `godot-runtime` MCP), it walks through **what it did and why** so nothing stays a black box.
- Doing a new thing by hand the first time builds intuition, so it's a good *default* — a
  preference, not a rule. Switch to model-builds-and-explains whenever the learner prefers.
- Keep the learner in the loop on every decision; they should be able to explain any slice
  before moving on.
- Lessons = self-contained HTML in `lessons/` (numbered from `0001`), one win each.
  Records currently run `0001`–`0020`; add more only when teaching resumes.
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
- Full Godot gate: `tools/godot/run_all_checks.sh`.
- Syntax check: `${GODOT_BIN:-godot} --headless --path godot --check-only --script res://scripts/simulation.gd`.
- Tests:
  - `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd`
  - `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_balance_tests.gd`
  - `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd`
  - `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_hud_tests.gd`
  - `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_end_screen_tests.gd`

## Project conventions ("set up like that")
- **Decisions** → `docs/adr/` (one ADR per locked choice; recorded via `domain-modeling`).
  **Domain language** grows into `CONTEXT.md` — add a term only once the learner can use it.
- **Issues / PRDs** → GitHub issues (`ShanesNotes/gizmo`). Use `ready-for-agent`,
  `ready-for-human`, and `needs-info` labels for handoff state. `.scratch/` is
  ignored local scratch/backups, not durable tracker state.
- **Git:** branch off `gizmo-3d` (active branch for this game repo; not `main`); commit/push only when asked. End commit messages with the
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` line.

## Boundaries
- Treat old 2.5D docs, archived OMX state, backups, and legacy lesson drafts as stale history, not active scope.
- Do not rewrite the Phaser source, root web build, or `design-handoff/NARRATIVE.md`.
- Do not stage `node_modules/`, `dist/`, `godot/.godot/`, exports, or generated cache.
- Do not attempt a full port in one lesson. Do not expand past v1 scope until v1 ships.

## Next lesson workflow
1. Run `/teach`; read `learning-records/` (zone of proximal development) and `CONTEXT.md` (v1 scope spine).
2. Cite the `simulation.ts` file/line for the slice; if shaping a module, pull in
   `codebase-design`; if it's testable logic, `tdd` it.
3. Co-develop the slice in `godot/` — small enough to absorb; capture it as HTML in `lessons/`.
4. `review` the diff, verify, and write a `learning-records/` entry when understanding is shown.

## Gizmo clean-canvas ecosystem

This folder participates in the Gizmo clean-canvas ecosystem. Read `gizmo-ecosystem.yaml` to route work by specialty before editing cross-domain artifacts.
