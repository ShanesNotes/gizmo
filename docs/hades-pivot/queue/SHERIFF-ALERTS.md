# SHERIFF ALERTS — overnight integration arbitration (2026-07-07)

The principal session (integration sheriff) commits binding entries here on gizmo-3d.
Night lanes (night/core, night/levels, night/assets, night/design, night/lore): read
this file after EVERY rebase onto origin/gizmo-3d; entries addressed to your lane are
binding arbitration under the fence law in
`docs/hades-pivot/NIGHTLOOP-PROMPTS-2026-07-07.md`.

Format: `## <timestamp Detroit> · to: <lane(s)> · <one-line ruling>` + body.

## 2026-07-07 04:05 Detroit · to: ALL LANES · commit the `.uid` sidecar with every new script/scene

This repo TRACKS Godot `.uid` sidecars (~100 committed — Godot 4.4+ convention for
stable resource UIDs across checkouts). At least two new scripts merged tonight
without theirs (`godot/scripts/codex/codex_book.gd`, `godot/tests/_probe_lantern_grip_proof.gd`),
which makes every checkout mint its own random UID locally — stray untracked files
that block pulls, and UID drift across the six worktrees.

Binding: when you add any `.gd`/`.tscn`/resource, run the headless import in YOUR
worktree and `git add` the generated `.uid` alongside it. Do not instruct Codex to
delete generated `.uid` files (lore lane's brief did this — stop). Lanes that already
merged uid-less files: include the sidecar in your next wave commit.

## 2026-07-07 04:40 Detroit · to: assets · custodian GLB extracts an untracked texture on every import

PR #42's decimated `custodian_boss.glb` embeds a texture that Godot's importer
EXTRACTS to `godot/assets/enemies/custodian_boss_Image_0.jpg` (+ `.import`) on every
checkout — untracked strays on all six worktrees, pull-blocker class. Binding: in your
next wave either (a) commit the extracted jpg + its `.import`, or (b) set
`gltf/embedded_image_handling` to embed-as-basisu/uncompressed in
`custodian_boss.glb.import` so nothing extracts. Pick one; verify with a clean
`git status` after a fresh `--import` in your worktree.
