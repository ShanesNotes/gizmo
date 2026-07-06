# HZ-073 — Live-run hotfixes (ceremony findings 2026-07-06)

**Status:** in-progress · **Worker:** Codex · **Deps:** HZ-103 (shipped)
**Source:** live combat ceremony on merged gizmo-3d (b15c0f2). Both defects are invisible
to the current headless battery and block/limit real play.

1. **[HIGH] Off-world enemy spawns.** In every live run, 2 of 3 wave enemies spawn at
   absurd positions (observed x≈-762 and x≈-1058, sane z, then fall forever at y<-1).
   Only one enemy of each wave lands on the floor. Consequence: rooms are uncleareable
   through normal play (the fallers never die). Correction audit did **not** support the
   stale/garbage `CameraAnchor.global_position` hypothesis: room anchors are stable
   room-local markers, and the golden-angle math itself cannot produce the observed
   off-world coordinates from a near-origin center. The confirmed degenerate source is
   identical enemy starts: exact coincident `GreyboxEnemy` bodies with a chase target
   reproduce off-world displacement under physics. Fix the spawner so it cannot emit
   identical starts, then pin real scene-tree spawn containment, pairwise separation,
   and post-spawn stepped containment.

2. **[HIGH] Door transition frees CollisionObject during physics callback.**
   `room_door.gd _on_body_entered → … → run_orchestrator._on_exit_completed →
   _load_current_room → _cleanup_current_room` removes the old room (with collision
   objects) synchronously inside the physics callback — engine error, undefined behavior
   (exact class of bug fixed for AppShell in PR #14). Defer the room swap out of the
   physics frame (reuse the `_defer_from_physics_frame` pattern from app_shell.gd —
   deferral + resume with args), keeping the flow-bridge contract (draft-before-advance,
   consumed-boon ledger) intact. Pin with a physics-callback test (PhysicsHandlerProbe
   pattern from run_app_shell_tests.gd): fire the door's body_entered from a real physics
   frame and assert no engine error path (old room removed on the following idle frame,
   exactly one room child after).

## Fence
run_orchestrator.gd, room_door.gd (only if the deferral seam lands there),
run_orchestrator_tests.gd, run_room_door_tests.gd, run_integration_gate_tests.gd.
Nothing else.

## Root cause / corrections update (2026-07-06)

- **Confirmed overlap mechanism.** `run_orchestrator_tests.gd:216` deliberately places two
  `GreyboxEnemy` bodies at the exact same position with a chase target. Within 60 physics
  frames, the probe reproduces the off-world displacement class. The code path is
  `enemy.gd:66-67`: `tick_chase(...)` followed by `move_and_slide()`. `enemy_brain.gd:101-103`
  guards the zero-vector steering case, so the reproduced failure is best explained as
  `CharacterBody3D` depenetration / slide solver behavior from coincident bodies, not a
  normalized-zero-vector bug. The probe reproduced the class of failure, not the exact
  x≈-762 live magnitude.
- **Spawner defect fixed.** The pre-correction `_spawn_position_for` fallback used one
  `best_score` sentinel. The first separation-failing candidate could set it non-negative,
  freezing fallback selection on that first attempted position. Current
  `run_orchestrator.gd:371-406` uses separate `best_valid` and `best_fallback` accumulators:
  valid positions optimize the normal score; fallback positions optimize nearest-enemy
  distance first and player distance second.
- **Regression pins.** `run_orchestrator_tests.gd` now covers the crowded-small-room red
  case where old code returned attempt 0, pairwise spawn separation, 60-physics-frame
  containment after real room load, and same-physics-frame two-door arbitration.
  `run_integration_gate_tests.gd` repeats real-run spawn containment and pairwise separation
  across run transitions.

## Acceptance
Red-first for both; orchestrator/door/integration-gate suites green; --check-only clean.
