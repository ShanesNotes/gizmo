# Gizmo — full-game ticket queue index

**Scope grew (2026-07-04, loop 5): this queue now slices the ENTIRE game** — see `PHASE-MAP.md` for
the P0→P7 milestone DAG (v1 loop → dressed → systems depth → world frame → acts 1–3 → 1.0 release).
This file remains the authoritative index for the P0 (fun-loop v1) band; later bands: GZ-131–134 (style),
GZ-141 (concordance), GZ-151–156 (juice, ADR 0011), GZ-161–162 (Spark-of-Humanity, ADR 0012),
GZ-171–175 (world frame, ADR 0010), REGION-TEMPLATE + 9 REGION-*.md (all nine remaining regions,
7 slices each), GZ-181–183 (enemy variety + finale ruling, ADR 0013), GZ-191–194 (ship shell → 1.0).

# P0 band — fun-loop v1 (DAG)

Generated 2026-07-04 by the Fable orchestrator pass (plan-only). Spec: `SPEC-fun-loop-v1.md`.
Tracker fallback: GitHub unreachable from this environment; import each `GZ-*.md` via
`gh issue create -R ShanesNotes/gizmo -F <file> -l <status-label>` later. Branch law: all work off `gizmo-3d`.

## Decision 1 (locked; no anchor edits)
ADR-0002 hybrid stands: Simulation (deep headless module) owns rules; scenes render; GameController bridges.
Full system table in the spec. New files in v1: upgrade_draft.tscn/.gd, run_upgrade_draft_tests.gd, run_integration_tests.gd.

## Coverage map (spec behavior → tickets)
FL-1→010 · FL-2→002,003,004,019,021,022 · FL-3→009,019 · FL-4→006,015 · FL-5→007 · FL-6→002 ·
FL-7→001,011,012 · FL-8→002,003,004,016 · FL-9→005,008,013 · FL-10→006,020 (base exists) ·
FL-11→011,013,014 · FL-12→018 · FL-13→015 · FL-14→017,021,022,033. Ship shell: 040 (export), 041 (pause).
No orphan tickets; every ticket cites its FL id. Companion docs: `LANDING-ORDER.md` (shared-file merge
order), `EPICS.md` (E1–E10 charters + seeds).

## DAG

FRONTIER (ready-for-agent, pick up cold):
- GZ-001 sim upgrade draft state [Opus] — start here; unblocks the most
- GZ-010 gizmo dash [Sonnet]
- GZ-014 HUD objective + rekindle indicator [Sonnet]
- GZ-017 beacon visual states [Sonnet]
- GZ-018 end-screen copy + stats [Haiku]
- GZ-030 asset-pipeline P0 q01–q04 [Opus] (run inside gizmo-asset-pipeline/)
- GZ-031 audio 5-cue handoff [Sonnet] (run inside gizmo-audio-canon/)

SIM LANE (strictly serial — all edit simulation.gd):
GZ-001 → GZ-002 [Sonnet] → GZ-003 [Sonnet] → GZ-004 [Sonnet] → GZ-005 [Opus] → GZ-006 [Opus] → GZ-007 [Sonnet] → GZ-008 [Sonnet] → GZ-009 [Sonnet]

PARALLEL BRANCHES (blockedBy):
- GZ-011 draft UI [Sonnet] ← 001
- GZ-012 draft pause bridge [Sonnet] ← 001,011
- GZ-013 guard HUD [Sonnet] ← 005 (not parallel-safe with 014: shared hud files)
- GZ-015 zone markers [Sonnet] ← 006 (not parallel-safe with 012/017/032/033: shared main.tscn/controller)
- GZ-016 sprint hookup [Haiku] ← 002
- GZ-019 balance gate [Sonnet] ← 004,009
- GZ-020 full-run integration [Opus] ← 009,012,015  ← **v1 ship gate**
- GZ-021 combat feedback VFX [Sonnet] ← 003
- GZ-022 orbit stars render [Haiku] ← 004
- GZ-032 music states [Sonnet] ← 031,006,015
- GZ-033 consume P0 assets [Sonnet] ← 030,015,017
- GZ-040 export pipeline [Sonnet] ← 020
- GZ-041 pause menu [Sonnet] ← 012

Acyclicity: verified by inspection — edges only point from lower prerequisites to higher dependents; sim lane is a chain; no back-edges.

## Model routing summary
Opus (5): 001, 005, 006, 020, 030. Sonnet (18): 002–004, 007–015 (exc. 016), 017, 019, 021, 031–033, 040, 041. Haiku (3): 016, 018, 022.
Rubric: Opus = seam-shaping/cross-system judgment; Sonnet = specified single-file ports and wiring; Haiku = one-multiplier/mirror/copy work.

## Live-code audit findings folded into tickets (loop 2)
- end_screen.gd:45 shows a survived clock — ADR 0005 violation; removal is now an explicit GZ-018 AC.
- hud.gd:55 already implements the rekindle text readout — GZ-014 rescoped to proximity gating + fill bar + flourish.
- game_controller.gd:164 `_apply_game_feel` is a no-op stub — became the GZ-021 seam; sim event channel (:132–139) confirmed live.
- Coverage gap closed: GZ-003/004 produced events nothing rendered → GZ-021/022 added.

## Deferred batch (pre-decomposed, status deferred:<epic> — activate post-v1)
- E1 audio: GZ-101 remaining cues [Haiku] ← 031 · GZ-103 bus layout [Haiku] ← 031 · GZ-102 AudioDirector [Opus] ← 101,103,032 · GZ-104 SFX pass [Sonnet] ← 103
- E2 level pipeline: GZ-111 route-graph bundle [Sonnet, lab] ← 015 · GZ-112 baker v0 [Opus] ← 111,030,033 · GZ-113 scene validators [Sonnet] ← 112
- E9 animation: GZ-121 idle/attack/hit clips [Opus, lab] ← 030 · GZ-122 AnimationTree wiring [Sonnet] ← 121,021

## Deferred epics (post-v1; named so the vision survives the cut)
- E1 Audio canon full realization: remaining 12 cues, AudioDirector interface, buses/ducking/SFX pooling (audio lab reference/ spec)
- E2 Level pipeline automation: ADR 0008 baker + validators as scripts; validated route-graph bundle from gizmo-level-design; manifest law
- E3 Design-system render work: hollowed-pole in-engine probe; shader/render-target decision (gate G12); degradation operators as world-state style
- E4 Meridian Concordance promotion (gates G13/G14) across siblings
- E5 Phaser juice systems: score/combo/bounties/surge/clutch/close-call, jackpot & nova upgrades, reroll, Scrap economy, meta progression
- E6 Spark-of-Humanity meter mechanics (ADR 0001 pending dedicated pass)
- E7 Path B connected/streamed islands
- E8 Bespoke beacon guardian + enemy behavior variety (dasher lunge etc. — needs source re-derivation, do not invent)
- E9 Animation clips beyond q04 walk (idle/attack/hit wiring)
- E10 Onboarding/tutorial, pause & settings menu, export pipeline (godot-prompter:export-pipeline) for the v1 ship itself

## Red-team notes (recorded)
- Sizing: every sim-lane ticket bounded to one function-group + tests; GZ-001 is the largest and deliberately Opus-routed.
- Shared-file hazards are declared per ticket (hud.tscn pair; main.tscn/controller cluster) — the queue is a DAG on LOGICAL deps; file-conflict ordering is stated as "not parallel-safe" rather than fake edges.
- No ticket revives waves/countdown; GZ-013/014/018 carry explicit ABSENCE assertions so regressions are mechanical, not vigilance.
- No ready-for-human labels emitted (autonomy directive); every open call is decided and recorded in-ticket with doc basis.
