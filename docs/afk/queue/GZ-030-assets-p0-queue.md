# GZ-030 — Service lane (asset-pipeline): execute P0 queue q01–q04

intent: The minimum dressing the loop needs from the asset lab: island base, beacon landmark, gear ring, Gizmo animation clips. This ticket is a POINTER — the work runs inside `C:/Users/Shane/gizmo-asset-pipeline` under that lab's own contract.

files in scope: NONE in the game repo. Work happens in `gizmo-asset-pipeline/` per its `AGENTS.md`, `canon/policy.yaml`, `docs/AFK_RUNBOOK.md`. Game-repo writes ONLY through that lab's validated auto-handoff (promotion report → install → headless import + five suites green → revert on red).

grounding: `gizmo-asset-pipeline/queue/QUEUE.yaml` items q01_island_base → q02_beacon → q03_gear_ring → q04_gizmo_clips (P0, already sequenced with dependencies lab-side). Routing law: gizmo/gizmo-ecosystem.yaml `asset_pipeline_to_game` seam (target `godot/assets/<category>/<asset_id>/`, additive-only, never touches hand-authored gizmo.glb).

decisions made: scope capped at P0 for v1 (q05–q14 stay queued lab-side; consuming them is post-v1). Basis: SPEC Non-goals + re-centering directive — assets serve the loop.

executable success criteria (as observed from the game repo):
1. Promotion reports exist lab-side for q01–q04 with all gates PASS + fixed-camera screenshots.
2. After each install: `${GODOT_BIN:-godot} --headless --path godot --import` exits 0 and `tools/godot/run_all_checks.sh` exits 0 on gizmo-3d (the lab's own install gate).

acceptance / done: `godot/assets/` contains validated wrapper installs for the four P0 items; game suite green.
dependencies / order: none — FRONTIER (fully parallel to all game-repo lanes). Blocks GZ-033.
model routing: **Opus** — the lab's AFK loop is autonomous, spend-accounted, judgment-heavy (3-strike breaker, evidence honesty).
cross-domain: asset_pipeline lane per ecosystem yaml; this ticket must NOT be worked from the game repo.
status: ready-for-agent (route to an agent booted inside gizmo-asset-pipeline/)
format: one issue per file (gh import later).
