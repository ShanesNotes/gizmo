# Post-v1 epics — charters + ticket seeds

Each epic is deferred, not deleted. E1, E2, and E9 are now FULLY decomposed into ticket files
(GZ-101–104, GZ-111–113, GZ-121–122, status deferred:<epic>) — activate by flipping their status when
their blockers merge. E3–E8 and E10 remain seeds ON PURPOSE: each hinges on a decision or lab promotion
(E3 render probe, E4 sibling promotion, E5.1 score grill, E6 lore grill, E7 Path-A proof, E8 source
re-derivation) that cannot be honestly pre-made — pre-writing full tickets there would fake certainty.
Other seeds decompose to full GZ-format at pickup (one session each, same schema). Nothing here enters the frontier until GZ-020 (ship gate) and GZ-040
(export) are green. Routing per gizmo-ecosystem.yaml; lab work runs in the lab, never from the game repo.

## E1 — Audio realization (lane: gizmo-audio-canon → game)
Goal: the full 12-cue arc + SFX grammar behind a real AudioDirector.
Seeds:
- E1.1 [lab, Sonnet] Convert remaining 7 path_a cues + 4 ambient per godot-handoff.yaml (same law as GZ-031).
- E1.2 [game, Opus] AudioDirector: the deep interface the sim drives (inputs: pressure level, zone/state, guard+HP, beacon state, surface). Spec exists lab-side (`gizmo-audio-canon/reference/` AudioDirector spec) — implement game-side behind one node; replaces GZ-032's minimal switcher.
- E1.3 [game, Sonnet] Bus layout (Music/Ambience/SFX/ducking) from the quarantined reference `godot/_quarantine/2026-06-21-pre-art-refactor/default_bus_layout.tres` — resurrect deliberately, don't copy blindly.
- E1.4 [lab+game, Sonnet] SFX grammar first pass: hit/death/pickup/level-up/dash one-shots (WAV law), wired to sim events (GZ-021's channel).
Gate: audio lab validators green + game suite green; loudness MEASURED (-18 LUFS), never claimed.

## E2 — Level pipeline automation (lane: gizmo-level-design + game)
Goal: ADR 0008's stagehand baker + validators as real scripts; validated route-graph bundle.
Seeds:
- E2.1 [lab, Sonnet] Route-graph bundle for Hearthwake Basin validating against `validators/route_graph_schema.json`; hand off as data (gate L12: lab never authors scenes).
- E2.2 [game, Opus] Python baker v0: recipe → places approved wrapper kit → emits WalkableRegion + PressureZones + anchors + manifest JSON (ADR 0008 MUST/MUST-NOT list is the spec).
- E2.3 [game, Sonnet] Scene validators as scripts: reachable anchors, camera readability probe, no-round-counter grep, loopback check — red gates in run_all_checks.sh.
Gate: baked scene passes validators AND all six GZ-015 marker coordinates' exposure values survive rebaking.

## E3 — Design-system render work (lane: gizmo-design-system → game)
Goal: the master mechanic on screen — style shifts LIVING/FACED → HOLLOWED/FACELESS with exposure.
Seeds:
- E3.1 [lab, Opus] Hollowed-pole in-engine probe: apply degradation operators to one landmark at the fixed camera; screenshot evidence; promote or reject (their gates, G0 discipline).
- E3.2 [lab, Opus] Render-target decision (gate G12): CompositorEffect vs per-material gouache — an ADR in their repo, consumed here later.
- E3.3 [game, Sonnet] Consume: exposure-driven material parameter (drain ramp token) on world kit, driven by sim.spatial_exposure_at — only after E3.1/E3.2 promote.
Gate: a screenshot pair (low/high exposure) at the gameplay camera that a stranger can order correctly.

## E4 — Meridian Concordance promotion (lane: all labs)
Goal: sibling-id bindings (X-L/X-S/X-A/X-P) promoted per gates G13/G14. Pure lab-side canon work;
the game consumes nothing until promoted. Seeds: one reconciliation ticket per sibling, driven from
`gizmo-design-system/extraction/reconciliation-2026-07-03-concordance.md` open items D6/D7.

## E5 — Phaser juice systems (lane: game)
Goal: the Phaser build's dopamine layer, ported honestly. Anchors into game-src-phaser/src/game/simulation.ts:
- E5.1 Score + combo (combo timer ts:1009; score sinks throughout) — decide first whether score survives the 3D design at all (grill; it may be cut permanently).
- E5.2 Bounties (BountyKind ts:6 — sweep/flow/thread/cache/elite).
- E5.3 Surge/clutch/close-call systems (ts:749–792) — dash-adjacent risk rewards.
- E5.4 jackpot upgrade (needs E5.1 first — crit/score/cache deps, ts:319–326) and nova upgrade (level-up shockwave, castNova ts:514, :635–644).
- E5.5 Reroll draft option (ts:526) + Scrap economy (ADR 0001 secondary currency) + shop seam.
- E5.6 Evolutions (state.evolved ts:381; magnet/sprint evolution bonuses ts:562,566) + slot-cap policy (balance §13.1: 6/6).
Order: E5.1 decision-first; everything else hangs off it.

## E6 — Spark-of-Humanity meter (lane: lore grill → game)
ADR 0001 explicitly parks it. Requires a design pass WITH the lore lab (meter meaning must not collapse
into Sparks/guard/HP — non-negotiable distinctions). Seed: a grilling session producing an ADR, then
sim + HUD tickets. Do not start from the game repo alone.

## E7 — Path B (connected/streamed islands)
Blocked on Path A shipping and proving traversal/pacing (path-a spec §1). Seed: none yet by design.

## E8 — Beacon guardian + enemy behavior variety
Swarm-at-peak IS the v1 boss (ADR 0005). Seeds: dasher lunge/windup re-derivation from ts:706
(chargeBurst/chargeWindup) — evidence exists, port honestly; bespoke guardian = named later upgrade only.

## E9 — Animation completion
q04 delivers walk on the protected rig path (no AI op touches shipped gizmo.glb — asset-lab law).
Seeds: idle/attack/hit clips on skeleton copies (canon/animation-pipeline.yaml), AnimationTree wiring,
`godot-animator` agent routed.

## E10 — Ship-quality shell
Settings menu (audio sliders vs E1 buses, key rebind), onboarding hint line ("Move, dodge, collect
shards, pick upgrades" — ts:455 is the tone anchor), accessibility pass (readability at 1280×720
baseline), itch.io page + web build QA (GZ-040's web preset).
