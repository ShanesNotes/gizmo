# GZ-173 — P3 (UI): world map hub (the Codex frame)

intent: Between runs Gizmo stands before the Shattered Meridian: a map of ten islands in the Codex's ceremonial frame — rekindled ones warm, reachable ones lit, the rest cold silhouettes. Pick one; the run begins.
files in scope: PRIMARY (new): `godot/scenes/world_map.tscn` + `godot/scripts/world_map.gd`; (new) runner `run_world_map_tests.gd` in both gate arrays; main-menu/flow touch in game_controller or a new `godot/scripts/game_flow.gd` if the controller is getting deep (builder's call, recorded in PR).
grounding: ADR 0010 (selection law: connected-to-rekindled; act gates); region graph JSON (positions/connections — load it as data, don't hand-copy ten nodes); lore (Codex = UI/memory/ceremony motif — frame copy sentence-case, ceremonial, warm); theme consumption law.
decisions made: map is DATA-DRIVEN from `docs/reference/shattered-meridian-region-graph.json` (single source — new regions light up without UI edits); v1 of the screen: flat stylized node-and-route diagram (no 3D flythrough — deferred polish); selection emits `region_selected(region_id)`; end-of-run returns here with a rekindle ceremony beat on wins (the "road opens outward" moment).
executable success criteria: runner green — reachability law cases (fresh save → only HEARTH's neighbors after HEARTH rekindled; act-gate lock/unlock), data-driven node count == JSON regions, selection signal; absence: no threat-level numbers as raw stats (mood, not math — diegetic law extends); gate green.
dependencies / order: blockedBy GZ-172. Blocks REGION-* activation.
model routing: **Opus** — the game's second screen and its flow spine; data-driven UI with law.
cross-domain: Codex framing copy = lore handoff (placeholder + routed note acceptable).
status: deferred:P3
