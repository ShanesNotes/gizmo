# Lesson 0001 complete: learner created the Godot project in the editor

The learner ran Lesson 0001 (open Godot → New Project → Compatibility → Create &
Edit) and produced a real, opening project. Verified: `godot/project.godot`
exists and `--headless --path godot --import` returns exit 0 with the icon
reimporting cleanly. Renderer is `gl_compatibility` as taught.

**Snag worth keeping (feeds the published guide):** the New Project dialog's
**Create Folder** button nested the project one level deep at `godot/gizmo/`
instead of at `godot/`. This breaks every command that assumes the project root
is `godot/` (`--path godot`, the test runner, the answer-key layout). Fixed by
lifting the project files up into `godot/` and clearing the stale `.godot`
cache. Lesson 0001's path step has been tightened to prevent the nested folder
for the next reader.

**ZPD now:** learner self-reports "poked around a bit" in the Godot editor — so
keep UI orientation light. They have a project but no scene, no main scene, and
have not pressed Play. Next is the first visceral win: a scene + a visible node
+ **Play** → a running game window. See [[MISSION.md]].
