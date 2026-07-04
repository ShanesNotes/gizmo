# GZ-121 — E9 (asset-pipeline lab): idle/attack/hit clips on skeleton copies

intent: Gizmo's remaining verbs animated — idle, attack, hit-react — authored on skeleton copies per the lab's animation pipeline. The shipped hand-keyed walk on gizmo.glb is protected: no AI rig op ever touches it.

files in scope: gizmo-asset-pipeline lab (canon/animation-pipeline.yaml is the law); game-repo writes only via validated promotion/install (additive AnimationLibrary, never a gizmo.glb overwrite).
grounding: lab queue q04 (walk clips) precedes this; 53-bone meshy rig documented in gizmo CONTEXT.md; `godot-prompter:animation-system` (AnimationLibrary/retarget) + the lab's `godot-animator` agent routing; proof = inspected skeleton + fixed-camera screenshot, never "Meshy said success".
decisions made: three clips only (idle 2s loop, attack 0.4s, hit 0.25s); cadence must read at the fixed Diablo camera (the judge); loop points authored, not trimmed.
executable success criteria: lab promotion report validates with per-clip evidence; post-install `${GODOT_BIN:-godot} --headless --path godot --import` exits 0 and `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-030 (q04 walk pipeline proven). Blocks GZ-122.
model routing: **Opus** — the animation gap is the lab's named hard problem; judgment-heavy.
cross-domain: asset_pipeline lane; run inside the lab.
status: deferred:E9
format: one issue per file (gh import later).
