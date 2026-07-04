# GZ-111 — E2 (level-design lab): validated route-graph bundle for Hearthwake Basin

intent: The level lab's first concrete deliverable to the game: a data-only route-graph instance (regions/connections/zone grammar for the Path A island) validating against their own schema, ready for the baker to consume.

files in scope: gizmo-level-design lab only (their canon/, extraction/, validators/). Deliverable = data files + validator report handed to the game repo as a bundle path; the lab never authors Godot scenes (their ADR 0001, gate L12).
grounding: `validators/route_graph_schema.json` (requires regions+connections | macro_topology | acts); source snapshot `sources/shattered-meridian/region_graph_gizmo_reference_snapshot.json`; their pressure-zone taxonomy (origin_relief, branch_discernment, landmark_read, trial_spike, sanctuary_breath, beacon_rekindling — two curve rules already promoted: sanctuary trough before beacon, unique beacon peak); game-side live coordinates: gizmo `godot/scenes/main.tscn` marker table (path-a spec §4) — the bundle must RECONCILE with those coordinates, not override them (coordinate authority stays game-side).
decisions made: bundle scope = HEARTH region interior only (the playable island), not the macro world graph; conflicts with main.tscn markers → extraction/reconciliation note lab-side, never silent.
executable success criteria: `make validate` exits 0 in gizmo-level-design with the new bundle included; the bundle passes route_graph_schema.json; a written witness maps each bundle zone to a spec §4 marker (or records the divergence).
dependencies / order: blockedBy GZ-015 (game markers landed = the reconciliation target exists). Blocks GZ-112.
model routing: **Sonnet** — schema-driven data authoring inside a disciplined lab.
cross-domain: level_design lane; run inside the lab.
status: deferred:E2
format: one issue per file (gh import later).
