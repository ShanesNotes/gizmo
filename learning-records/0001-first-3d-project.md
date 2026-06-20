# 0001 — Your first 3D project

**Date:** 2026-06-20
**Lesson:** `lessons/0001-first-3d-project.html`
**Mode:** hands-on (learner built the scene in the Godot editor)
**Status:** complete — verified running

## What was built
A fresh Godot 4.6 project (`godot/`) configured for 3D, plus the first scene
`scenes/main.tscn`: a `Node3D` root (`Main`) with `Camera3D`, `Sun`
(`DirectionalLight3D`), `Ground` (`MeshInstance3D` + 20×20 `PlaneMesh`), and
`Box` (`MeshInstance3D` + `BoxMesh` lifted to `y=0.5`). `run/main_scene` points
at the scene; pressing Play renders a lit floor with a box on it.

## Verified
- Headless import: exit 0.
- Ran via godot-runtime MCP; screenshot showed the box resting on the ground.
- Engine log confirmed `Vulkan — Forward+` is the active renderer (the lesson's
  core decision is real, not just declared).

## What this establishes (for ZPD)
The learner can: create/open a Godot project, build a `Node3D` scene tree, add
and rename nodes, assign primitive meshes, place nodes via the Transform
inspector, set the main scene, and Play. Foundation for camera work.

## Notes
- The scene's box origin is centered, so `y=0.5` (half the default 1m box) seats
  it on the floor — first brush with 3D transforms/origins.
- Verbal understanding-check was offered and the learner opted to skip it; the
  correct, spec-matching hands-on build stands as the evidence of competence.
- Renderer nuance captured in the lesson: `forward_plus` is the engine default,
  so the explicit `rendering_method` line may be omitted on rewrite;
  `config/features` ("Forward Plus") is the durable signal.
