# Godot `godot-runtime` MCP — runtime hazards & guards

Operational notes for agents driving the `godot-runtime` MCP (`run_project`,
`stop_project`, `take_screenshot`, `simulate_input`, `run_script`). Two recurring
hazards, both surfaced during the 0011/0012 work. Neither blocks v1, but both must
be guarded — do **not** normalize them silently.

## 1. McpBridge residue in `project.godot` (must clean before any commit)

`run_project` **injects** for the life of the session:
- an autoload line in `godot/project.godot`:
  `[autoload]` → `McpBridge="*res://mcp_bridge.gd"`
- `godot/mcp_bridge.gd` and `godot/mcp_bridge.gd.uid`

A **clean `stop_project` strips all three.** But:
- `mcp_bridge.gd*` is gitignored (script + `.uid`), so the loose files can't be staged.
- The **autoload line is inside `project.godot`, a tracked file — it CANNOT be gitignored.**
  If a session is interrupted or the teardown crashes (see §2), that line is **stranded
  dirty** in the working tree and can be committed by accident.

**Guard (run every time, before committing anything after an MCP session):**
```
git diff -- godot/project.godot          # must be empty (no McpBridge autoload)
git status --porcelain=v2 -- godot/project.godot godot/mcp_bridge.gd*
```
If dirty: `git checkout -- godot/project.godot` (when the bridge line is the *only*
diff) and remove `godot/mcp_bridge.gd*`. If `project.godot` also has legitimate
uncommitted work, strip **only** the `McpBridge` autoload line by hand.

> History note: a 2026-06-20 check reported `project.godot` "clean" right after a
> stop, but a reviewer found the bridge autoload dirty shortly after — because the
> residue is **session-bound and ephemeral**, not a stable state. Re-verify against
> the live tree at commit time; never trust an earlier "clean" reading.

## 2. signal-11 on teardown of a 3D scene (tracked, not "permanently benign")

Stopping a **3D** scene run (e.g. `scenes/main.tscn`) via the MCP bridge can exit with
`Program crashed with signal 11` **after** the frame has rendered and the quit was
issued. Observed signature (Godot 4.6.2):
- `propagate_notification()` called off the main thread (`scene/main/node.cpp`)
- `No render buffer nor reflection atlas, bug` (`render_forward_clustered.cpp`)
- `RID allocations ... leaked at exit` / `Pages in use exist at exit`

**Classification:** post-render teardown crash; the run itself and all screenshots
succeed first. Acceptable to not block v1.

**Do NOT call it permanently benign.** Re-isolate if any of these change:
- it crashes **before** a successful render / screenshot, or mid-session;
- the backtrace signature changes (not the render-teardown path above);
- it starts leaving §1 residue stranded (the two hazards compound).

If it recurs in a way that matters, capture `get_debug_output` + the full
`stop_project` `finalErrors` and open a focused issue (minimal repro scene).

## Quick checklist after any MCP `run_project`
- [ ] `stop_project` returned (even after a crash).
- [ ] `git diff -- godot/project.godot` is empty.
- [ ] no `godot/mcp_bridge.gd*` in `git status`.
- [ ] commit only after the above are clean.
