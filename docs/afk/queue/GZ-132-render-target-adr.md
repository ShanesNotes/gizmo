# GZ-132 — E3 (design-system lab): render-target ADR (gate G12)

intent: Decide the painterly pipeline once: CompositorEffect post-process vs per-material gouache shading. An ADR in THEIR repo; the game consumes the ruling later.
files in scope: gizmo-design-system (docs/adr/ or canon decision log; canon/shader-matrix.yaml status flip).
grounding: their shader-matrix.yaml (render-target is a TARGET, gate G12); level-lab's 48-asset gouache research digest (`gizmo-level-design/extraction/digests/godot-art-style-assets-digest.md`); Godot 4.7 CompositorEffect availability — verify against official docs, never memory.
decisions made (recommended default for ratification): **per-material first** — a shared gouache ShaderMaterial on kit + a lightweight environment pass; CompositorEffect deferred until per-material proves insufficient at the fixed camera. Rationale: reversible, asset-pipeline-compatible (wrapper materials), no engine-version risk concentration. The lab may overrule with evidence — that's the point of the ADR.
executable success criteria: ADR exists with decision + consequences + the G12 gate flipped from TARGET to DECIDED; `make validate` green.
dependencies / order: blockedBy GZ-131 (probe evidence informs it). Blocks GZ-133.
model routing: **Opus** — the architecture decision of the art stack.
cross-domain: run inside gizmo-design-system.
status: deferred:E3
