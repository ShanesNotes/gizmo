# GZ-001 — Simulation: upgrade draft state & weighted offers

intent: The single biggest fun-loop gap. On level-up the sim stops auto-scaling and instead pauses into `awaiting_choice`, rolls 3 weighted upgrade choices, and applies the chosen rank. Spec FL-7 (and the state half of FL-8).

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: scenes, hud.gd, game_controller.gd (UI/bridge land in GZ-011/012), any sibling folder.

grounding:
- Defs table (titles/maxRank/weight/unlockLevel/color are canon): `game-src-phaser/src/game/simulation.ts:265–340`.
- Roll-on-level: ts:1033 (`rollUpgradeChoices(state, 3, "level")`); choice build ts:1536; weighting ts:1553.
- Apply: `chooseUpgrade` ts:499–520 (ignore the nova branch at :514 — nova is cut, SPEC Non-goals).
- Weighted offer math: `reference/game-balance-reference.md` §7.1; exhaustion fallback §7.5.
- Existing level-up autoscale to REPLACE: `current_attack_cooldown/target_count/damage` level_bonus logic, simulation.gd:361–372 — after this ticket those derive from `upgrades["spark"]` rank (rank formulas land in GZ-002; here, rank 0 must reproduce current level-1 baseline so existing tests stay meaningful).

decisions made (do not re-derive):
- Port 7 upgrades' METADATA only (spark, pulse, orbit, magnet, sprint, heart, focus); jackpot/nova excluded (SPEC Non-goals). Effects beyond spark-baseline land in GZ-002+.
- Defs are a `const UPGRADE_DEFS := {...}` dictionary in simulation.gd, not a Resource (SPEC Decision 1; ADR-0002 headless deep module).
- New phase-like flag `awaiting_choice: bool` (not a new PHASE_* constant) — run phase stays "playing"; tick() returns immediately while awaiting. Basis: ADR 0005 phases are win/lose semantics; a draft is a pause, not a phase.
- Multiple pending level-ups queue: resolve one draft, then re-roll if XP still ≥ next_xp (SPEC edge cases).
- Deterministic tests: rolls use `RandomNumberGenerator` held in a `rng` member; tests set `rng.seed`.
- Weight model v1: `weight_i = base_weight × eligibility` where eligibility = 0 if level < unlockLevel or rank ≥ maxRank, else 1. Tag-synergy/pity multipliers (§7.1) deferred to E5. Rationale: no build tags exist yet.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0, including NEW tests: (a) level-up sets awaiting_choice and yields exactly 3 distinct choices at level 2 among unlockLevel≤2 upgrades; (b) tick() advances nothing while awaiting (elapsed, enemies, beacon channel unchanged); (c) `choose_upgrade("spark")` increments rank, clears awaiting, resumes tick; (d) an upgrade at maxRank never appears again; (e) all-pools-exhausted level-up does NOT set awaiting_choice; (f) fewer than 3 eligible → offers that many.
2. `${GODOT_BIN:-godot} --headless --path godot --check-only --script res://scripts/simulation.gd` exits 0.
3. `tools/godot/run_all_checks.sh` exits 0 (no other suite regresses).

acceptance / done: sim exposes `awaiting_choice`, `choices` (Array[Dictionary] with id/title/rank/max_rank/color), `choose_upgrade(id)`, `upgrades` ranks dict; behavior matches criteria; committed on a branch off `gizmo-3d`.

dependencies / order: none — FRONTIER. Serializes the sim lane: GZ-002 must not start until this merges (same primary file).
model routing: **Opus** — architecture-shaping seam inside the deep module; everything downstream hangs off this API.
cross-domain: none.
status: ready-for-agent
format: one issue per file; import later via `gh issue create -R ShanesNotes/gizmo -F <this file>` with label ready-for-agent.
