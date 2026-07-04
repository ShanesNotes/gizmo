# GZ-112 — E2 (game): stagehand baker v0

intent: ADR 0008 made real: a Python script that places APPROVED wrapper kit from a recipe and emits WalkableRegion + PressureZones + anchors + manifest JSON. Assembles, records, refuses — never invents.

files in scope:
- PRIMARY (new): `tools/level/bake_scene.py` (stdlib Python; deterministic given recipe + seed)
- also (new): `tools/level/recipes/hearthwake_v1.json`; output lands as a NEW scene variant (never overwrites curated main.tscn — ADR 0008 MUST NOT list)
- DO NOT: call Meshy/AI, decide beats, invent landmarks, overwrite curated nodes, ship unvalidated output (ADR 0008 — each is a named reject).

grounding: ADR 0008 pipeline + manifest fields (recipe version, asset ids + transforms, zones, footprint, soundtrack cue ids, validation results); consumes GZ-111's bundle + GZ-030's installed wrapper metadata (role/footprint/collision intent); `.tscn` text format is stable and scriptable (verify against Godot 4.7 docs, not memory).
decisions made: v0 bakes DRESSING only (kit placement within the walkable footprint); zones/anchors are copied from the recipe verbatim (curation stays human); output scene must load headless and pass GZ-113 validators before it may be referenced anywhere.
executable success criteria: `python3 tools/level/bake_scene.py recipes/hearthwake_v1.json --seed 7` twice → byte-identical scene + manifest (determinism); `${GODOT_BIN:-godot} --headless --path godot --import` exits 0 with the baked scene present; manifest carries every ADR 0008 field; `tools/godot/run_all_checks.sh` exits 0.
dependencies / order: blockedBy GZ-111, GZ-030, GZ-033. Blocks GZ-113 (validators test against its output).
model routing: **Opus** — a generator with hard refusal rules; the discipline is the hard part.
cross-domain: consumes level-lab data + asset-lab installs; authored game-side (baking is implementation, per ecosystem seam).
status: deferred:E2
format: one issue per file (gh import later).
