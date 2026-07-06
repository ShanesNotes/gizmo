# SPEC — Playable Fun-Loop v1 (Path A, Hearthwake Basin)

Status: accepted (red-teamed 2026-07-04, Fable orchestrator pass)
Home: `docs/afk/queue/` (local queue; GitHub is reachable, but this queue has not been imported/synced yet)
Branch: all work branches off `gizmo-3d`. Tickets: `GZ-*.md` in this folder; DAG in `INDEX.md`.

## Decision 1 — locked v1 architecture (no anchor edits required)

ADR-0002 stands unchanged: **`Simulation` (headless `RefCounted`, `godot/scripts/simulation.gd`) owns all rules; scenes render; `GameController` bridges.** No CONTEXT.md or ADR edit is needed — every decision below derives from existing anchors.

Authoritative v1 system list and owners:

| System | Owner file | State today |
|---|---|---|
| Run lifecycle / phases / pressure_clock | simulation.gd | DONE |
| Temporal director + spawn budget + 4 enemy kinds | simulation.gd | DONE |
| Weapons: Spark Chain (auto-attack) | simulation.gd | DONE (level-autoscaled — to be replaced by ranks) |
| Weapons: Bubble Pulse, Orbit Stars | simulation.gd | MISSING (GZ-003/004) |
| XP / Sparks / level | simulation.gd | DONE |
| **Upgrade draft state + weighted offers + effects** | simulation.gd | **MISSING — the core loop gap** (GZ-001/002) |
| Guard-over-HP (ADR 0007) | simulation.gd | MISSING (GZ-005) |
| Pressure zones / spatial exposure / siege override (ADR 0006) | simulation.gd | MISSING (GZ-006) |
| Walkable region + spawn validation (ADR 0006) | simulation.gd | MISSING (GZ-007; obstacles exist) |
| Sanctuary relief → guard recharge (ADR 0007) | simulation.gd | MISSING (GZ-008) |
| Elite variants (ADR 0003 "special threats") | simulation.gd | MISSING (GZ-009) |
| Beacon state machine Dormant→Rekindling→Rekindled (ADR 0005) | simulation.gd | DONE |
| Player input / movement / **dash** | gizmo.gd | move DONE; dash MISSING (GZ-010) |
| Fixed Diablo camera | camera_rig.gd | DONE |
| Bridge: tick feed, enemy mirroring, zone registration, draft pause | game_controller.gd | partial (GZ-012/015) |
| HUD: guard/HP bars, sparks/level, objective cue, rekindle indicator | hud.gd/hud.tscn | partial (GZ-013/014) |
| **Upgrade draft UI** | upgrade_draft.tscn/.gd (NEW) | MISSING (GZ-011) |
| End screens | end_screen.gd | DONE (verify copy/stats, GZ-018) |
| World greybox + zone markers per spec §4 | main.tscn | partial (GZ-015/017) |

New files permitted in v1: `godot/scenes/upgrade_draft.tscn`, `godot/scripts/upgrade_draft.gd`, `godot/tests/run_upgrade_draft_tests.gd`, `godot/tests/run_integration_tests.gd`. Nothing else.

**Recorded call:** upgrade definitions live as a const table inside `simulation.gd`, not a separate Resource. Basis: ADR-0002 ("pure data + math", headless-testable deep module); a Resource seam has no second consumer in v1. Revisit only if meta-progression lands (deferred epic E5/E6).

**Serialization law:** tickets GZ-001…GZ-009 all edit `simulation.gd` and are strictly serialized (declared in each ticket). Scene/UI lanes run in parallel where deps allow.

## The loop (player-visible, one sentence)

Fight through director-driven escalating pressure → collect Sparks/XP → level up → **choose one of three upgrades** → survive the crest → carry your guarded light to the Beacon and rekindle it (win = Beacon Rekindled; lose = HP 0). No waves, no countdown (ADR 0003/0005 — settled; do not reopen).

## Behaviors (each checkable; tickets cite these ids)

- **FL-1 Move & dash.** WASD movement exists. Add dash: brief speed burst on input action, cooldown-gated, HUD-free. Source feel: simulation.ts:467–468 (timers), :652 (dash speed term). v1 dash grants NO i-frames (recorded call: keeps sim untouched and dash parallel-safe; contact i-frames already exist, simulation.gd:24). Check: scripted input in headless GameController test shows displacement > walk-speed × window during dash and cooldown enforced.
- **FL-2 Combat.** Spark Chain auto-attack (exists) becomes rank-driven (rank effects per simulation.ts:820–836 analog); add Bubble Pulse AoE (ts:840–857) and Orbit Stars (ts:859–873). TTK targets per reference/game-balance-reference.md §5.4: trash ≤ ~0.7s (accepted v1 cadence deviation already recorded at simulation.gd:84), bruiser 1–3s, elite 3–10s. Check: run_balance_tests assertions.
- **FL-3 Enemies & director.** 4 kinds + budget director (exists; simulation.gd:34–77). Add elites: heat-gated spawns of scaled variants, first at pressure_clock ≈ 55s, interval 48 − min(20, wave_index × 2.6)s (ts:674–676; "wave_index" is internal director bookkeeping only — never player-facing). Elite = same kind, HP ×~3.5, radius ×1.3, XP ×3 (ts elite scaling band). Check: sim test fast-forwards and asserts elite presence + TTK band.
- **FL-4 Place-aware pressure.** `pressure = temporal_ramp × spatial_exposure(pos)` + Rekindling forces peak exposure (ADR 0006, ADR 0005; path-a spec §4). Sim API: `add_pressure_zone(pos, radius, exposure, role)`, `spatial_exposure_at(pos)` — smooth distance-weighted blend, spawn→beacon distance fallback, exposure is a modifier not a zero-floor. Check: sim tests assert exposure blend values and siege override.
- **FL-5 Containment.** Authored XZ `WalkableRegion` in sim; ring-spawns validated (sample → reject outside → reject obstacle overlap → nearest-valid fallback); enemies soft-clamped post-move (ADR 0006 §6; no NavigationServer3D). Check: sim tests spawn at region edge and assert containment.
- **FL-6 Pickups.** Spark pickups + pickup radius exist. Magnet upgrade extends radius and adds pull motion toward Gizmo (ts:562, :891–910). Check: sim test asserts pickup moves toward player inside pull radius.
- **FL-7 Level-up draft.** On level-up: sim enters `awaiting_choice`, emits 3 weighted choices (weight = base × unlock/eligibility, maxRank exhaustion respected; ts:1033, :1536, :1553; balance ref §7.1). `choose_upgrade(id)` applies rank + resumes. While awaiting, sim tick is inert (scene pauses gameplay). Pool exhaustion → auto-continue with no draft (balance ref §7.5). Check: sim tests for choice count, weights honoring unlockLevel/maxRank, exhaustion path.
- **FL-8 Upgrade effects (7 of 9 ported).** spark (cooldown/targets/damage/range per rank; drafting rank 1 sets range MELEE→ATTACK_RANGE, simulation.gd:85–86), pulse, orbit, magnet, sprint (player speed multiplier exported to gizmo.gd), heart (max HP + heal now), focus (global cooldown mult). Defs table: ts:265–340 (titles/maxRank/weight/unlockLevel are canon). **Cut:** jackpot (depends on unported score/crit/cache systems), nova (polish; needs castNova). Named in Non-goals. Check: per-effect sim assertions.
- **FL-9 Guard-over-HP.** Damage hits recoverable guard first; HP is one-way; guard recharges after delay-since-last-damage; recharge capped; sanctuary (relief-role zone) shortens delay/raises rate; HP never regenerates; anti-camp holds because temporal ramp keeps climbing (ADR 0007). Numbers are v1 placeholders, recorded in ticket: guard = 3, recharge delay = 4.0s, rate = 0.6/s, sanctuary ×2.5 rate + half delay. Check: sim tests for hit routing, delayed recharge, sanctuary boost, HP non-regen.
- **FL-10 Win/lose.** Beacon area-hold channel → Rekindled → PHASE_COMPLETE (exists, simulation.gd:101–104, 237). HP 0 → PHASE_GAMEOVER (exists). During Rekindling, exposure = peak (FL-4). Check: existing + new sim tests.
- **FL-11 HUD.** Guard bar (cyan/teal) above smaller warm HP bar; Sparks/level/XP kept; objective cue "Reach the Beacon"/"Rekindle the Beacon"; rekindle indicator only near/inside radius; **no countdown, no exposure meter, no wave counter** (spec §7). Theme: `godot/scenes/hud_theme.tres` (published witness — consume, never hand-edit; design-system ADR 0002). Check: run_hud_tests assertions on bar wiring + absence checks.
- **FL-12 End screens.** Win copy "Beacon Rekindled"; lose "Gizmo's light failed"; show level reached, kills, Sparks banked — never "time survived" (ADR 0005). Check: run_end_screen_tests.
- **FL-13 World alignment.** main.tscn zone markers match path-a spec §4 table (SouthLanding 0,0,17 spawn/very-low; East 18,0,-4 / West -20,0,-4 branch; CentralGearPlaza 0,0,-12 landmark; SanctuaryAnchor ≈15,0,-31 relief; NorthBeaconDais 0,0,-42 high→peak) and GameController registers each into the sim. Check: game_controller test asserts registered zone set.
- **FL-14 Presentation minimum.** Beacon visibly distinct per state (Dormant/Rekindling/Rekindled — material/light change). Greybox otherwise acceptable; installed q01/q02 assets swap in when the asset-pipeline lane delivers (GZ-033). Check: scene inspection assertion in game_controller test (state → visual property).

## Edge cases & failure modes (builders: handle, don't ask)

- Level-up during Rekindling: draft still offered; channel progress pauses with the sim while awaiting_choice (recorded call — simplest consistent rule; ADR 0005 decay knob untouched).
- Multiple level-ups from one pickup burst: queue drafts one at a time (ts behavior at :1033 analog).
- Draft offered with < 3 eligible upgrades: offer what's eligible (2, 1); zero → skip silently (balance §7.5 fallback).
- Guard hit that overflows into HP: split damage across guard then HP in the same hit.
- Enemy spawn when no valid point found after N=12 samples: nearest-valid fallback (ADR 0006).
- Beacon radius 0 (no beacon authored): channel inert (existing behavior, simulation.gd:167) — tests must keep this.
- dt spikes: MAX_DT clamp exists (simulation.gd:23); all new systems must respect it.

## Non-goals (scope firewall — deferred, named, not deleted)

jackpot & nova upgrades; Scrap economy, score/combo/bounties/surge/clutch/close-call systems (ts BountyKind:6, :768–792); reroll UI (ts:526); Spark-of-Humanity meter (ADR 0001 pending pass); audio canon realization beyond the 5-cue service lane; level-baker automation (ADR 0008 pipeline); route-graph bundle from gizmo-level-design (main.tscn is live coordinate authority per spec §4); design-system hollowed-pole probe, shader/render-target (G12), concordance promotion (G13/G14); Path B; bespoke beacon guardian (swarm-at-peak IS the boss); animation clips beyond asset-pipeline q04; onboarding/tutorial; pause/settings menu; NavigationServer3D (rejected, ADR 0006); any wave-round or countdown UI (settled — ADR 0003/0005).

## Verification law

Every ticket names its exact command(s). Global gate: `tools/godot/run_all_checks.sh` exits 0. Suite runners: `${GODOT_BIN:-godot} --headless --path godot --script res://tests/run_<suite>_tests.gd`. A ticket that adds behavior adds tests in the same diff.
