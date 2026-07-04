# GZ-022 — Scene: orbit stars rendering

intent: The Orbit Stars upgrade must be visible: small glowing star meshes circling Gizmo at the sim's authoritative positions. Pure mirror of `orbit_state()` — no gameplay here. Spec FL-2/FL-14.

files in scope:
- PRIMARY: `godot/scripts/game_controller.gd` (orbit mirror region) + `godot/scenes/main.tscn` (an `OrbitStars` Node3D under the player mirror)
- tests: `godot/tests/run_game_controller_tests.gd`
- DO NOT touch: simulation.gd (orbit_state() from GZ-004 is the only interface), gizmo.gd.

grounding:
- Sim contract (GZ-004): `orbit_state()` → `{count, radius, angle}`; star world positions = player position + polar offsets at equal angular spacing. Color: UPGRADE_DEFS orbit color (#ff79c6, ts:283–290).
- Mirroring precedent: enemies are already data-mirrored onto visuals each frame (ADR-0002); do the same — controller owns the mirror, stars are dumb MeshInstance3Ds (small emissive spheres, greybox acceptable).

decisions made:
- Node pool sized to max rank count (1 + floor(6/2) = 4 stars); visibility toggled by count; no per-frame alloc.
- Star Y = 0.8 m (torso height at the fixed camera — reads as protection, doesn't hide the face; design-system inherited canon: Gizmo's face stays visible).

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_game_controller_tests.gd` exits 0 with NEW tests: (a) rank 0 → zero visible stars; (b) rank 1 → one visible star at distance orbit radius (±0.05) from the player mirror; (c) two ticks apart → the star's angle advanced (positions differ, distance constant); (d) rank 4 → count matches orbit_state().count.
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: drafting orbit visibly arms Gizmo; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-004. NOT parallel-safe with the controller/main.tscn cluster — land per LANDING-ORDER.md.
model routing: **Haiku** — a mirror loop against a stated accessor.
cross-domain: none.
status: blocked:GZ-004
format: one issue per file (gh import later).
