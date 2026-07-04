# GZ-152 — E5 (sim+scene): close-call & clutch feel hooks

intent: The dodge deserves teeth: grazing an enemy during dash refunds dash cooldown (close call); a kill inside the post-dodge window refunds more (clutch). Non-numeric risk-reward per ADR 0011.
files in scope: PRIMARY: `godot/scripts/simulation.gd` (close-call detection needs enemy proximity truth — sim-owned) + a small gizmo.gd/controller hook for the dash-active flag; tests: run_simulation_tests.gd. Sim lane rules apply (Cluster A — serialize with any other open sim ticket).
grounding: ts:749–757 (close-call: proximity pass while dashing → cooldown refund 0.32/0.55s, brief lockout 0.62/0.9s), ts:768–792 (clutch window CLUTCH_CHAIN_WINDOW after close call; kill inside it → larger refund ~0.72s); ADR 0011 (score halves cut; refunds kept).
decisions made: sim gains `set_dash_active(active: bool)` (scene pushes it — dash stays scene-owned, ADR 0002); close call = enemy within (enemy.radius + 0.6m) while dash_active and not in lockout; refunds emitted as events `{"type":"close_call"}` / `{"type":"clutch"}` — the scene applies the cooldown refund to its own dash timer (cooldown is scene state), sim only detects.
executable success criteria: sim tests — (a) dash-by within threshold emits close_call once per lockout; (b) kill inside 1.2s after close_call emits clutch; (c) no dash → no events. Controller test — refund shortens the scene dash cooldown. `tools/godot/run_all_checks.sh` green.
dependencies / order: blockedBy GZ-151 (ADR ratified), GZ-010 (dash exists), GZ-021 (event consumption pattern).
model routing: **Sonnet** — two events + one flag across a stated seam.
status: deferred:E5
