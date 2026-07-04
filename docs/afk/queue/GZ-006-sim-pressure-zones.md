# GZ-006 — Simulation: pressure zones, spatial exposure, rekindling siege override (ADR 0006)

intent: The director becomes place-aware: `pressure = temporal_ramp × spatial_exposure(gizmo_position)`, with exposure forced to peak while the Beacon is Rekindling. The island decides how cruel the swarm becomes. Spec FL-4, FL-10.

files in scope:
- PRIMARY: `godot/scripts/simulation.gd`
- tests: `godot/tests/run_simulation_tests.gd`
- DO NOT touch: main.tscn / game_controller.gd (zone registration from scene markers is GZ-015).

grounding:
- ADR 0006: exposure encoded as zones `{zone_id, role, radius, exposure 0..1, relief_multiplier}`; sim API `add_pressure_zone(pos, radius, exposure, role)` and `spatial_exposure_at(pos)`; smooth distance-weighted blend of nearby zones; plain spawn→beacon distance fallback when no zones authored; exposure is a MODIFIER, NOT a zero-floor (time always matters).
- ADR 0005 / path-a spec §3–4: while beacon state == Rekindling, exposure overridden to peak (1.0) — the siege is the Path A boss.
- Existing hooks: `pressure()` simulation.gd:260, budget director :74–77, beacon state :101–104.

decisions made (recorded v1 numbers):
- Blend: for zones whose distance d < radius, weight `w = 1 − d/radius` (linear falloff); `exposure = clamp(Σ w_i·e_i / Σ w_i, floor, 1.0)` with `EXPOSURE_FLOOR := 0.35` so temporal ramp always bites (ADR 0006 "modifier, not zero-floor"). No zones in range → fallback `lerp(0.45, 1.0, 1 − dist_to_beacon/dist_spawn_to_beacon)` clamped 0.45..1.0; no beacon authored → 1.0 (today's behavior preserved).
- `pressure()` becomes `temporal_pressure() × spatial_exposure_at(last_gizmo_position)`; keep `temporal_pressure()` public for tests/telemetry. Budget director consumes the combined value — spawn budget breathes with place.
- Zone roles stored verbatim (`spawn|branch|landmark|trial|sanctuary|beacon`); relief behavior is NOT implemented here (GZ-008) — roles are inert data this ticket.
- `relief_multiplier` accepted in add_pressure_zone signature (default 1.0) so GZ-015 can author it before GZ-008 lands.

executable success criteria:
1. `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_simulation_tests.gd` exits 0 with NEW tests: (a) no zones + no beacon → exposure 1.0 (regression: existing pressure tests still pass); (b) inside a single 0.2-exposure zone → exposure == max(0.35, blended) and pressure < temporal_pressure; (c) between two zones → blended value strictly between their exposures; (d) outside all zones with beacon set → distance fallback within 0.45..1.0 and monotonic toward beacon; (e) beacon Rekindling → spatial_exposure_at() == 1.0 regardless of zones; (f) spawn budget over a fixed window is measurably lower in a low-exposure zone than high (count spawns).
2. `tools/godot/run_all_checks.sh` exits 0.

acceptance / done: standing in the warm south landing is measurably gentler than the beacon dais at equal clock; the rekindle hold is a siege; branch off `gizmo-3d`.
dependencies / order: blockedBy GZ-005 (sim-lane serialization). Blocks GZ-007, GZ-015, GZ-032.
model routing: **Opus** — the central director equation; blend/fallback/override interactions are the trickiest sim math in v1.
cross-domain: zone semantics originate in gizmo-level-design canon (origin_relief, trial_spike, sanctuary_breath, beacon_rekindling…); this ticket consumes the ADR 0006 projection already in the game repo — do NOT read or edit the sibling lab.
status: blocked:GZ-005
format: one issue per file (gh import later).
