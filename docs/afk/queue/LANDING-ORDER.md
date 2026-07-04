# Landing-order playbook — shared-file clusters

The DAG encodes LOGICAL dependencies only. Two clusters share files; agents landing into them
follow this order (or rebase cleanly — later lander rebases, never force-push):

## Cluster A — `godot/scripts/simulation.gd` + `run_simulation_tests.gd`
Strictly serial by ticket number: GZ-001 → 002 → 003 → 004 → 005 → 006 → 007 → 008 → 009.
Never two sim-lane tickets in flight at once. Each merges to `gizmo-3d` before the next starts.

## Cluster B — `godot/scripts/game_controller.gd` + `godot/scenes/main.tscn`
Recommended landing order (minimizes rebase pain; earlier = smaller diff):
1. GZ-017 beacon visuals (frontier — can land immediately)
2. GZ-012 draft pause wiring (after GZ-011)
3. GZ-015 zone markers (after GZ-006)
4. GZ-041 pause menu (after GZ-012)
5. GZ-021 combat feedback VFX (after GZ-003)
6. GZ-022 orbit stars render (after GZ-004)
7. GZ-032 music states (after GZ-031/006/015)
8. GZ-033 consume P0 assets (after GZ-030/015/017 — last; biggest scene diff)
GZ-010 (gizmo.gd) and GZ-016 (gizmo.gd) are outside the cluster but share gizmo.gd with each
other: GZ-010 first, GZ-016 second.

## Cluster C — `godot/scenes/hud.tscn` + `hud.gd`
GZ-014 (frontier) lands before GZ-013 (blocked on GZ-005 anyway). One in flight at a time.

## Invariant
After EVERY landing: `tools/godot/run_all_checks.sh` exits 0 on `gizmo-3d`. A red gate reverts
the landing (asset-lab discipline applies repo-wide).
