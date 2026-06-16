# Godot Agent Tooling Review for Gizmo

Checked: 2026-06-15  
Scope: review the Godot skills/MCP/addon research for use in this repo without trusting the pasted Claude recommendation as authority.

## Direct recommendation

1. **Use GodotPrompter as the first knowledge/skills source, but do not vendor the full third-party skill tree into Gizmo.** Install it per-user for Claude/Codex, or point teaching/implementation agents at a curated subset. For Gizmo's near-term lessons, the useful subset is: `godot-project-setup`, `gdscript-patterns`, `scene-organization`, `godot-ui`, `responsive-ui`, `assets-pipeline`, `godot-testing`, `state-machine`, `input-handling`, `save-load`, and later `inventory-system` / `dialogue-system`.
2. **Keep Gizmo's current custom headless checks as the canonical lesson gate for now.** GUT is the first testing-framework candidate if/when handwritten scripts become too thin; gdUnit4 is strong but heavier and more C#/editor-workflow oriented.
3. **Do not baseline a Godot MCP server yet.** If we trial one, trial it as a local-only teaching aid, not as committed project structure. Best first MCP trials:
   - **Erodenn/godot-mcp-runtime** for screenshots/runtime input/live scene-tree checks because that matches the existing visual-smoke direction.
   - **Godot AI by hi-godot** if editor-control breadth and Codex support matter more than keeping the project addon-free.
   - **Coding-Solo/godot-mcp** only if we want the simpler/popular editor-run-debug loop and accept its smaller tool surface.
4. **Defer gameplay addons.** Dialogue Manager and GLoot are credible, but they should enter only when a lesson opens dialogue/inventory. SaveKit is interesting but too young for Gizmo's early teaching path; build JSON saves ourselves first.
5. **Avoid Godogen for Gizmo.** Its upstream Godot output is C#/.NET-focused, while Gizmo's contract is GDScript-first and lesson-by-lesson, not autonomous whole-game generation.

## Repo-local context

- Gizmo's active Godot project is under `godot/`, verified locally with Godot 4.6.2 stable mono.
- Current lesson contract is editor-first/co-development, not black-box full-port generation.
- Current verification already includes headless import, `--check-only`, custom simulation tests, custom UI smoke tests, and an X11/OpenGL screenshot baseline.
- GodotPrompter-style skills and Godot agent prompts must be exposed through user-level Codex/Claude skill installation or a deliberate project-local setup; do not depend on another workspace's private tool directories for Gizmo lessons.
- `~/.codex/config.toml` currently has OMX MCP servers only; no Godot MCP server is configured for Codex.

## Source-backed evaluation

| Candidate | DYOR verdict for Gizmo | Evidence / notes |
| --- | --- | --- |
| **jame581/GodotPrompter** | **Adopt as knowledge layer, curated.** Strongest skills pack for avoiding stale Godot 3 patterns. | Upstream README says 48 skills for Godot 4.3+, GDScript and C#, plus Codex support and 9 specialized agents. Changelog v1.9.0 on 2026-05-29 says 48 skills, 9 Codex sub-agents added in v1.8.0, validator baseline 0 errors. Local game-dev copy matches 48 skills / 9 agents. Sources: https://github.com/jame581/GodotPrompter and https://raw.githubusercontent.com/jame581/GodotPrompter/master/CHANGELOG.md |
| **Coding-Solo/godot-mcp** | **Trial only; not default yet.** Good popular baseline for launch/run/debug, but not enough runtime visual/input depth for Gizmo's UI/lesson verification by itself. | README lists launch editor, run project, debug output, project info, scene/node operations, UID management; requirements are Godot + Node >=18. GitHub shows no releases; npm package is v0.1.1 last modified 2026-02-03. A command-injection issue was opened Jan 19, 2026 and closed by #67, so use current versions only and do not auto-approve broad file/project paths. Sources: https://github.com/Coding-Solo/godot-mcp and https://github.com/Coding-Solo/godot-mcp/issues/64 |
| **Erodenn/godot-mcp-runtime** | **Best first MCP experiment for visual/runtime verification.** Keep as local-only trial because adoption is low. | README claims no addon/no project commits, runtime screenshots, input simulation, UI discovery, live GDScript eval, and headless scene/script validation; prerequisites Node v20+ and Godot 4.x. Local metadata check showed 34 stars, 1 open issue, pushed 2026-05-27. Source: https://github.com/Erodenn/godot-mcp-runtime |
| **hi-godot/godot-ai** | **Important omission from Claude's list. Trial separately before choosing Coding-Solo as baseline.** Strong Codex/editor support, but it installs a Godot plugin and has telemetry to opt out of. | Asset Library page says Godot AI 2.5.9, MIT, submitted 2026-05-28, with MCP clients including Codex. GitHub README says 120+ ops / ~41 MCP tools, Godot 4.3+ with 4.4+ recommended, AssetLib/GitHub install, Codex config snippet, v2.7.3 latest Jun 14, 2026. README also documents telemetry and opt-out env vars. Sources: https://godotengine.org/asset-library/asset/5050 and https://github.com/hi-godot/godot-ai |
| **tugcantopaloglu/godot-mcp** | **Do not baseline.** Useful to know, but too broad/powerful for a teaching repo unless sandboxed. | README advertises 149 tools, runtime `game_eval`, node/property mutation, file write/delete, project creation/config, export, networking, etc. That is a large prompt-injection and accidental-mutation surface. Source: https://github.com/tugcantopaloglu/godot-mcp |
| **GUT** | **First testing-framework candidate if we outgrow custom scripts.** Better fit than gdUnit4 for current GDScript-only Gizmo. | README says GUT is GDScript-in-GDScript unit testing; 9.x targets Godot 4.x; main/9.6.0 targets 4.6.x; features include CLI and JUnit XML. Asset Library lists GUT 9.6.0 for Godot 4.6, MIT, submitted 2026-02-24. Sources: https://github.com/bitwes/Gut and https://godotengine.org/asset-library/asset/1709 |
| **gdUnit4** | **Credible but defer.** Strong if we want richer assertions/mocking/scene tests or mixed C# later; likely too much ceremony for early lessons. | README says it tests GDScript, C# scripts, and scenes; supports Godot 4.5/4.6/4.6.2 in v6.x/master compatibility table; rich assertions/mocking/inspector. Source: https://github.com/godot-gdunit-labs/gdUnit4 |
| **Randroids-Dojo/Godot-Claude-Skills** | **Do not choose over GodotPrompter for general guidance.** Keep as a possible CI/GdUnit4/PlayGodot reference only. | GitHub README marks the repo deprecated in favor of the marketplace, has only one broad `godot` skill, and PlayGodot requires a custom Godot fork/automation branch. Good ideas, less suitable as Gizmo's primary skill base. Source: https://github.com/Randroids-Dojo/Godot-Claude-Skills |
| **GodotTestDriver** | **Skip for now.** | Useful integration-test API, but C# / NuGet only. Gizmo is GDScript-first. Source: https://github.com/chickensoft-games/GodotTestDriver |
| **GDQuest godot-open-rpg** | **Use as architecture/teaching reference, not dependency.** | README says it is a practical educational Godot 4.6.2 OpenRPG reference with combat, inventory, progression, maps/transitions, dialogues, grid movement, menus; also explicitly turn-based and a demo, not a framework. Source: https://github.com/gdquest-demos/godot-open-rpg |
| **Dialogue Manager** | **Defer until narrative/dialogue lesson. Use v3 unless v4 is officially released.** | README says Dialogue Manager 4 is for Godot 4.6+ but warns to probably use version 3 until v4 is officially released; latest shown is v3.10.4 for Godot 4.6. Source: https://github.com/nathanhoad/godot_dialogue_manager |
| **GLoot** | **Defer until inventory lesson; good candidate but not a save system.** | README says GLoot is a Godot 4.4+ universal inventory system with item stacks/prototypes/inventory constraints/basic UI controls. It has a serialization section, but it is inventory logic; pair with our own save architecture. Source: https://github.com/peter-kish/gloot |
| **SaveKit** | **Watch, do not adopt early.** | README is promising: saves nodes/resources, avoids ResourceLoader code-injection risks, JSON/binary serializers. But project is v0.1, 12 stars, 0 forks, and latest release Apr 10, 2026. Gizmo should teach a simple JSON save first. Source: https://github.com/fernforestgames/godot-savekit |
| **Godogen** | **Avoid for Gizmo.** | Upstream search/GitHub says Godot output uses C#/.NET projects and needs the .NET Godot build. Gizmo's teaching track is GDScript-first, editor-first, narrow slices. Source: https://github.com/htdt/godogen |

## Recommended adoption order

### Phase A — knowledge only, no runtime/tooling change

- Install or expose **GodotPrompter** to Claude/Codex as a user-level skill pack, not committed into Gizmo.
- Add a short Gizmo pointer doc only if needed: "when Claude teaches a Godot lesson, consult these GodotPrompter skills, then return to Gizmo's `LEARNING_PATH.md`, `LESSON_LOG.md`, and `DESIGN_TO_LESSON_HANDOFF.md`."
- Do not let GodotPrompter override Gizmo's two-track rule, lesson log rule, or design handoff.

### Phase B — optional local MCP trial

Pick exactly one MCP server for a trial branch/session:

1. **Erodenn/godot-mcp-runtime** if the next pain is visual smoke/runtime interaction.
2. **Godot AI** if the next pain is editor-scene authoring and Codex-native MCP connection.
3. **Coding-Solo/godot-mcp** if the next pain is simple launch/run/debug capture.

Trial checklist:

- Configure local-only first; do not commit `addons/` or MCP config unless deliberately approved.
- Disable telemetry where available (`GODOT_AI_DISABLE_TELEMETRY=true` / `DISABLE_TELEMETRY=true` for Godot AI).
- Do not auto-approve destructive tools (`write_file`, `delete_file`, arbitrary eval, project-path mutation, export/deploy).
- Prove value with one existing task: open project, run current scene/test, capture output/screenshot, no source changes.

### Phase C — testing framework only when lesson complexity demands it

- Continue custom `godot/tests/*.gd` scripts until they become repetitive or weak.
- If adding a test framework for GDScript-only Gizmo: **GUT 9.6.0+ for Godot 4.6** first.
- Consider gdUnit4 only if we need stronger scene-test ergonomics, mocking, or C# support.

## Concrete Gizmo policy

- **Allowed now:** use GodotPrompter skills as external references during lesson planning/implementation.
- **Allowed as local trial:** one Godot MCP server, with explicit local-only config and no broad auto-approval.
- **Not allowed yet:** vendoring third-party addons into `godot/addons/`, switching to C#, replacing current headless gates, or letting an autonomous tool advance lesson logs without learner-understood simulation work.
- **Future lesson triggers:**
  - State-machine lesson: use GodotPrompter `state-machine`; no addon.
  - UI/design lessons: use `godot-ui`, `responsive-ui`, and existing Lumen Codex handoff; no generic UI generation.
  - Inventory lesson: evaluate GLoot vs a small hand-built inventory at that time.
  - Dialogue lesson: evaluate Dialogue Manager v3/v4 state at that time.
  - Save lesson: start with custom JSON from `save-load`; revisit SaveKit only if save graph complexity justifies it.

## Installed local tooling (2026-06-15)

Installed after this review, without vendoring any third-party addon into `godot/`:

- **GodotPrompter 1.9.0** cloned at `~/.codex/vendor/GodotPrompter` (commit `e09aa6d` at install time).
  - Codex compatibility link: `~/.codex/godot-prompter -> ~/.codex/vendor/GodotPrompter`.
  - Codex skill discovery link: `~/.agents/skills/godot-prompter -> ~/.codex/godot-prompter/skills`.
  - Codex native subagent link: `~/.codex/agents/godot-prompter -> ~/.codex/godot-prompter/.codex/agents/godot-prompter`.
  - Claude Code plugin: `godot-prompter@godot-prompter-marketplace`, user scope, enabled.
- **Godot MCP Runtime 3.1.2** configured user-level as `godot-runtime` for Claude Code and as `mcp_servers.godot_runtime` for Codex.
  - Command: `npx -y godot-mcp-runtime@3.1.2`.
  - `GODOT_PATH=/home/ark/.local/bin/godot`.

Operational notes:

- Restart Claude Code / Codex sessions to pick up newly installed skills, agents, and MCP tools.
- Keep `godot-runtime` local-only and verification-oriented: launch/run/capture/check scenes; do not use it to bulk-author scenes or mutate project structure without the lesson/handoff gate.
- To update GodotPrompter: `git -C ~/.codex/vendor/GodotPrompter pull --ff-only`.
- To remove the runtime MCP from Claude: `claude mcp remove "godot-runtime" -s user`.
- To disable the Claude plugin if the always-on prompt cost is too high: `claude plugins disable godot-prompter`.
