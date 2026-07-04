# GZ-113 — E2 (game): scene validators as red gates

intent: ADR 0008's validator list becomes executable: reachable anchors · camera readability · pressure ≠ trap spawn · clear loopback · ≤1 visible landmark at major sightlines · no player-facing round-counter UI. A scene that can't be played, read, or traced does not ship.

files in scope: PRIMARY (new): `tools/level/validate_scene.py` (stdlib; takes a scene+manifest, RETURNS a report — no side effects); register as a step in `tools/godot/run_all_checks.sh` for any baked scene present.
grounding: ADR 0008 validator list verbatim; "camera readability" v0 = geometric proxy (no walkable geometry above y-threshold occluding the fixed-camera frustum toward Gizmo's plane — path-a spec §6's flat-connector law), not a rendered-image judgment (that stays E3 evidence work); round-counter check = grep of scene text for wave/round/countdown node names + label text (same regex family as GZ-013).
decisions made: validators run on manifest + .tscn text (parseable), not on a live engine — headless-fast, CI-honest; each check emits pass/fail + the offending node path (a gate that can't name the betrayal isn't a gate — lab discipline imported).
executable success criteria: red-team fixtures — a deliberately bad scene (unreachable beacon anchor; a "Wave 3" label) is REJECTED with named findings; the GZ-112 baked scene passes; `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-112.
model routing: **Sonnet** — TDD-shaped rule implementation with fixtures.
cross-domain: none (game-side; mirrors level-lab gate philosophy).
status: deferred:E2
format: one issue per file (gh import later).
