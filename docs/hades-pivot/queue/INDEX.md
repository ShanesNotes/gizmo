# Gizmo — Hades-structure ticket queue index

**Scope (2026-07-05):** This queue supersedes the P0 fun-loop-v1 arena frontier in
`docs/afk/queue/INDEX.md` on **structure only** (ADR 0010). That queue stays
untouched as historical reference; salvage its **balance-math values** (spawn-pressure
curves, TTK bands, HP/damage numbers in `reference/game-balance-reference.md`) by
value, not by ticket ID or architecture. The current `godot/` arena prototype
(`simulation.gd`, `game_controller.gd`, `hud.gd`, …) is **reference-only** — new
systems rebuild from scratch per ADR 0010.

**Branch law:** all work off `hades-clone` (branched from `gizmo-3d` in sibling checkout
`/home/ark/gizmo`; never write there). Tracker fallback: import each `HZ-*.md` via
`gh issue create -R ShanesNotes/gizmo -F <file> -l <status-label>` when GitHub is reachable.

## Decision 1 (locked; no anchor edits)
ADR 0010 + CONTEXT.md pivot banner: Hades-structural clone reskinned with existing Gizmo
lore. **Room-graph** traversal replaces the whole-island model; **dash/attack/special/cast**
replaces auto-fire + leveling; **boon draft between rooms** (run-scoped) plus
**death → hub → new run** meta-progression replace the beacon-rekindle win loop.
Director-driven pressure (ADR 0003) and guard-over-HP (ADR 0007) survive as *combat*
mechanics scoped **per room**. Narrative/art canon unchanged — cite `design-handoff/NARRATIVE.md`,
`design-handoff/ART_DIRECTION.md`, `design-handoff/gizmo-hud.png`; do not invent lore.

## Design anchors (read before pickup; do not redesign in tickets)
| System | Spec | Scaffold |
|---|---|---|
| Room graph + camera | `docs/hades-pivot/room-graph-and-camera.md` + `docs/hades-pivot/HADES-PARITY-SPEC.md` (authority) | `godot/scripts/room_graph/*.gd` (data model + branch/rejoin generator, generation-time rewards; not wired) |
| Ability kit | `docs/hades-pivot/ability-kit.md` (landed) | `godot/scripts/abilities/*.gd` (kit + modifier seam; tested) |
| Boons + meta | `docs/hades-pivot/boon-and-meta-progression.md` (landed) | `godot/scripts/boons/*.gd`, `godot/scripts/meta/*.gd` (tested) |
| Balance salvage | `reference/game-balance-reference.md` §3–§7 | Phaser `simulation.ts` as feel reference only |
| Currency identity | ADR 0001 (Sparks/Scrap names persist; mechanical role shifts per ADR 0010) | — |

## Coverage map (pivot behavior → tickets)
HP-1→001 · HP-2→002,030,032 · HP-3→003 · HP-4→004,005 · HP-5→010 · HP-6→011–015 ·
HP-7→020 · HP-8→021,043 · HP-9→022,023 · HP-10→030,032 · HP-11→031 · HP-12→040 ·
HP-13→041,042,062 · HP-14→050–053 · HP-15→060,061. Ship gate: **061**. No orphan
tickets; every ticket cites its HP id. Companion doc: `docs/hades-pivot/room-graph-and-camera.md`
(§1 data model, §2 camera, § room-transition flow).

## DAG

FRONTIER (ready-for-agent, pick up cold):
- HZ-002 RunController core [Opus] — unblocked (001 done); seam owner for the room-graph lane
- HZ-015 gizmo ability input wiring [Sonnet] — unblocked (011–014 done)
- HZ-022 boon_draft UI scene [Sonnet] — unblocked (021 done)
- HZ-041 hub scene [Opus] — unblocked (040 done)
- HZ-050 HUD retire Path A chrome [Sonnet] — no blockers
- HZ-053 HUD guard-over-HP carry-forward [Sonnet] — parallel; ADR 0007 unchanged

COMPLETED (2026-07-05 pivot bootstrap + spec-§7 corrections; verified: 160+46+42 headless checks pass):
- HZ-001 room_graph tests · HZ-010 ability data model · HZ-011–014 dash/attack/special/cast
- HZ-020 BoonDef model · HZ-021 draft roller + apply · HZ-040 meta_state save/load · HZ-043 meta bonuses at run start
- HZ-042 partial: `run_lifecycle.gd` covers the death→bank→hub→new-run *logic*; scene wiring remains with 041
- Spec-§7 corrections (HADES-PARITY-SPEC.md): cast → ammo-with-reclaim; dash-cancel out of
  attack/special/cast recovery; `RoomNode.reward_type` assigned at generation; branch/rejoin
  generator with guaranteed mid-biome shop + elite; `BoonDef.slot` + draft-time slot exclusivity

ROOM GRAPH LANE (serial core — RunController is the seam owner):
HZ-001 → HZ-002 [Opus] → HZ-003 [Sonnet] · HZ-004 [Opus] · HZ-005 [Sonnet]

ABILITY LANE (one ability per ticket after the data model):
HZ-010 → HZ-011 [Sonnet] (dash) → HZ-012 [Sonnet] (attack) → HZ-013 [Sonnet] (special) → HZ-014 [Sonnet] (cast) → HZ-015 [Sonnet] (input wiring)

BOON LANE (serial draft stack):
HZ-020 → HZ-021 [Opus] → HZ-022 [Sonnet] → HZ-023 [Sonnet]

PARALLEL BRANCHES (blockedBy):
- HZ-003 room_camera bounds-clamped follow [Sonnet] ← 002 (soft follow clamped to authored room bounds, hard cut on transition — corrected §2 of room-graph doc; not parallel-safe with 050: shared main/camera files)
- HZ-004 RoomDirector per-room [Opus] ← 002 (salvage pressure math from balance ref §6; per-room scope per room-graph doc §1)
- HZ-005 room scene contract validator [Sonnet] ← 001 (CameraAnchor, SpawnMarker, RoomExit names per room-graph doc §2)
- HZ-011 dash ability [Sonnet] ← 010
- HZ-012 attack ability [Sonnet] ← 010 (not parallel-safe with 011: shared abilities/ files if co-located)
- HZ-013 special ability [Sonnet] ← 010
- HZ-014 cast ability [Sonnet] ← 010
- HZ-015 gizmo ability input wiring [Sonnet] ← 011,012,013,014
- HZ-021 boon draft roller + apply [Opus] ← 020 (weighted offers: balance ref §7.1 by value; boons replace level-up draft)
- HZ-022 boon_draft UI scene [Sonnet] ← 021 (brass cartouche from `hud_theme.tres`; cite `gizmo-hud.png`)
- HZ-023 RunController boon-draft bridge [Sonnet] ← 002,021,022 (between-room overlay per room-graph doc § room-transition step 4)
- HZ-030 door unlock on room clear [Sonnet] ← 002,004 (RoomConnection.door_name lookup)
- HZ-031 reward telegraph [Haiku] ← 030 (door reads destination `RoomNode.reward_type` — assigned at generation time per parity spec §2.2; glow/open VFX; no new lore copy; rolling rewards on clear is NOT the design)
- HZ-032 room transition orchestration [Opus] ← 003,023,030 (free scene → boon draft → load next; room-graph doc § room-transition flow)
- HZ-041 hub scene [Opus] ← 040 (Brass Sphere / codex frame per ART_DIRECTION § codex motif; `NARRATIVE.md` §5)
- HZ-042 death → hub → new run flow [Sonnet] ← 002,040,041
- HZ-043 meta bonuses at run start [Sonnet] ← 021,040 (bounded additive per balance ref §13.1)
- HZ-050 HUD retire Path A chrome [Sonnet] ← none (remove beacon/level/XP widgets; ADR 0005 beacon UI retired)
- HZ-051 HUD ability bar [Sonnet] ← 015 (dash/attack/special/cast slots; replaces Core Matrix 1/2/3 framing per ability-kit.md)
- HZ-052 HUD boon loadout [Sonnet] ← 021 (run-scoped picks; replaces level badge)
- HZ-060 greybox template pool [Sonnet] ← 005 (≥1 COMBAT + 1 BOSS RoomTemplate.tres + scenes with CameraAnchor)
- HZ-061 full-run integration gate [Opus] ← 032,042,051,052,060 ← **Hades v1 ship gate**
- HZ-062 end-screen hub-return copy [Haiku] ← 042 (stats reflect rooms cleared/boons taken; no wave/countdown language — ADR 0003)

Acyclicity: verified by inspection — edges only point from lower prerequisites to higher dependents; room-graph core is a short chain; ability and boon lanes are chains; no back-edges.

## Model routing summary
Opus (8): 002, 004, 010, 020, 021, 032, 041, 061. Sonnet (22): 001, 003, 005, 011–015, 022–023, 030, 040, 042–043, 050–052, 053, 060. Haiku (2): 031, 062.
Rubric: Opus = seam-shaping/cross-system judgment; Sonnet = specified single-file ports and wiring; Haiku = one-multiplier/mirror/copy work.

## Ticket ledger (one function-group + tests each)

| ID | Title | Model | HP | Status | blockedBy |
|---|---|---|---|---|---|
| HZ-001 | `room_graph` headless tests (RoomGraph lookups, generator linear chain, state machine) | Sonnet | HP-1 | done | — |
| HZ-002 | `RunController` core (owns `RoomGraph`, `current_room_id`, enter/clear lifecycle) | Opus | HP-2 | done | 001 |
| HZ-003 | `room_camera.gd` bounds-clamped follow + transition cut (room-graph doc §2, corrected) | Sonnet | HP-3 | done | 002 |
| HZ-004 | `RoomDirector` per-room (difficulty_tier pressure, room-clear signal) | Opus | HP-4 | done | 002 |
| HZ-005 | room scene contract validator (CameraAnchor, SpawnMarker, RoomExit) | Sonnet | HP-4 | done | 001 |
| HZ-010 | ability kit data model (`AbilityDef` / run loadout; cite `ability-kit.md`) | Opus | HP-5 | done | — |
| HZ-011 | dash ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-012 | attack ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-013 | special ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-014 | cast ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-015 | gizmo ability input wiring (actions → kit) | Sonnet | HP-6 | done | 011–014 |
| HZ-016 | Gizmo player entity scene (CharacterBody3D + AbilityComponent + AbilityInputRouter + placeholder mesh) | Opus | HP-6 | done | 015 |
| HZ-020 | `BoonDef` resource model (authored boon table; run-scoped ranks) | Opus | HP-7 | done | — |
| HZ-021 | boon draft roller + apply logic (between-room offers) | Opus | HP-8 | done | 020 |
| HZ-022 | `boon_draft.tscn` UI (3-card choice; signal contract) | Sonnet | HP-9 | done | 021 |
| HZ-023 | RunController boon-draft bridge (pause run, overlay, resume) | Sonnet | HP-9 | done | 002,021,022 |
| HZ-030 | door unlock on room clear (`RoomConnection.door_name`) | Sonnet | HP-10 | done | 002,004 |
| HZ-031 | reward telegraph (door shows destination's generation-time `reward_type`) | Haiku | HP-11 | done | 030 |
| HZ-032 | room transition orchestration (mark REWARDED, free/load, boon gate) | Opus | HP-2,10 | done | 003,023,030 |
| HZ-040 | `meta_state.gd` save/load (Sparks/Scrap meta, schema_version) | Sonnet | HP-12 | done | — |
| HZ-041 | hub scene (death return; codex/Brass Sphere frame) | Opus | HP-13 | done | 040 |
| HZ-042 | death → hub → new run flow | Sonnet | HP-13 | done | 002,040,041 |
| HZ-043 | meta bonuses injected at run start | Sonnet | HP-8 | done | 021,040 |
| HZ-050 | HUD retire Path A chrome (beacon, level, XP bar) | Sonnet | HP-14 | done | — |
| HZ-051 | HUD ability bar (dash/attack/special/cast) | Sonnet | HP-14 | done | 015 |
| HZ-052 | HUD boon loadout display | Sonnet | HP-14 | done | 021 |
| HZ-053 | HUD guard-over-HP carry-forward | Sonnet | HP-14 | done | — |
| HZ-060 | greybox `RoomTemplate` pool (combat + boss scenes) | Sonnet | HP-15 | done | 005 |
| HZ-061 | full-run integration gate | Opus | HP-15 | done | 032,042,051,052,060 |
| HZ-062 | end-screen hub-return copy + stats | Haiku | HP-13 | done | 042 |
| HZ-070 | combat feel & survivability pass (spawn distance, telegraph, TTK) | Codex | feel | done | 061 |
| HZ-102 | REST/REWARD room types (generation side) | Codex | rooms | done | 061 |
| HZ-104 | AudioDirector runtime seam (room-state music) | Codex | audio | done | 061 |
| HZ-106 | pause menu + export pipeline | Codex | ship | done | 061 |
| HZ-103 | Spark Surge (Call-gauge analog, ADR 0012) | Codex | meter | done | 070,104 |
| HZ-071 | combat scale rebalance (TTK bands unreachable) | Codex | feel | done | 103 |
| HZ-072 | REST/REWARD runtime behavior + traversal coverage | Codex | rooms | done | 103 |

## Salvage notes (old queue → this queue)
- **Do not reopen GZ-001…GZ-041** as frontier tickets. Reuse only documented numbers/formulas.
- GZ-011/012 draft UI pattern → informs HZ-022/023 shape (payload-in, signal-out) but new files/scenes.
- GZ-172 meta serialization shape → informs HZ-040 (JSON `user://`, schema_version) but meta fields reflect boon-economy not beacon rekindle.
- GZ-010 dash feel numbers → optional reference for HZ-011 until `ability-kit.md` pins them.
- `camera_rig.gd` continuous follow → **salvaged as the smoothing core**; HZ-003 adds per-room bounds clamping + transition cut (room-graph doc §2, corrected — Hades follows the player within clamped room bounds, it does not hold a static frame).

## Deferred batch (post–HZ-061; activate only after ship gate)
- ~~HZ-101 branch/rejoin generator~~ — **landed early** as spec-§7 correction 4 (branching is v1 per parity spec §2.1); no longer deferred
- HZ-102 REST/REWARD room types beyond the landed SHOP/ELITE fixtures (template pool + draft rules)
- HZ-103 Spark-of-Humanity meter pass (ADR 0001 — requires dedicated design ADR; do not fuse into HP)
- HZ-104 audio director + room-state music (audio-canon handoff)
- HZ-105 animation clips for ability kit (meshy.ai rig; post-feel gate)
- HZ-106 export pipeline + pause menu (godot-prompter:export-pipeline)

## Red-team notes (recorded)
- Sizing: every ticket bounded to one function-group + tests; HZ-002/021/032/061 are deliberately Opus-routed seams.
- Shared-file hazards declared inline (main/camera cluster for 003 vs 050; abilities/ for 011–014) — logical DAG deps; file-conflict ordering stated as "not parallel-safe" not fake edges.
- No ticket revives waves/countdown/beacon-rekindle win; HZ-050/062 carry explicit ABSENCE assertions.
- `ability-kit.md` landed (with `godot/scripts/abilities/`): HZ-015 and the HUD tickets cite it as authority; Phaser dash constants remain salvage-by-value reference only.
- Room graph scaffold exists but has **zero tests** — HZ-001 is the cold-start entry, not a re-scaffold.
- Wave-2 audit (2026-07-05): HZ-015's router is headless-only by design — HZ-016 (added) owns scene
  integration; HZ-051 and HZ-061 should treat 016 as a prerequisite. Hub door entry is tested via
  simulated body_entered signals, not real physics overlap — accepted; the HZ-061 live gate covers it.
- No ready-for-human labels emitted; open calls are decided in design anchors above.
- HZ-070 audit (2026-07-06): confirmed — vacuous retreat-probe cadence (HIGH, reworked to player-DPS model), 3D-vs-XZ spawn distance (MED), silent containment no-op + wave index reuse (LOW). Refuted/accepted — HUD pip layout asymmetry (container-managed), probe double-tick risk (no current trigger; revisit if a test interleaves harness ticks with real frames).
- Strategic-gate flag (2026-07-06): melee kit damage [18,20,26] one-shots all archetypes (HP 1/4) — ability-kit port scale vs enemy HP band scale mismatch. Bruiser/elite TTK bands (1-3s/3-10s) unreachable. Rebalance ticket due at the post-batch Fable gate (HZ-071 candidate).
- Fable strategic gate #1 (2026-07-06, post HZ-070/102/104/106 merge): VERDICT — architecture coherent (payload HUD, contract-shaped audio seam, group-based overlay guard, edge-walk invariants all healthy); REST self-clear ordering verified legal against RunController state machine; test battery honest post-audits (mutation-proofed probe, real-topology integration). Defects → tickets: HZ-071 (combat scale: melee one-shots all archetypes, TTK bands unreachable), HZ-072 (Scrap Cache grants nothing at runtime; Ember Alcove heals nothing; zero live REST/REWARD traversal coverage). Watch item: run_orchestrator.gd at 666 lines is drifting toward god-module — decompose next time it needs surgery, not before. Hades-bar note: real boss encounter (unique archetype + patterns) remains the largest structural gap to parity; queue after feel settles.
- Gate #1 addendum: merged-tree battery exposed a cross-slice defect — 5-boon default pool exhausts (integration gate hit a 4th BOON door under HZ-102's reweighted graphs → "expected 3 offers, got 2"). Fix folds into HZ-103 corrections (same fence): expand default pool AND graceful exhaustion (offer min(3, remaining); zero remaining → BOON door falls back to a currency grant, Hades replacement-reward pattern); integration gate updated to the new contract. Legacy game_controller 2-line expectation artifact from checkpoint e0d7914 fixed directly on gizmo-3d (f4f13c7).
| HZ-108 | benefactor seam: BoonDef role-id field + pool tagging (ADR 0013) | Codex | lore | done | 103 |
- HZ-103 audit (2026-07-06): CRITICAL confirmed — attack_started had no damage subscriber; the player could never kill an enemy in live play (all test room-clears used direct take_damage). Melee hit resolver wired in corrections. Also confirmed: surge ignored spawn windup (MED), stagger banked serially through windup (MED), HUD fixed-offset overlap (LOW). Watch item (recorded, no fix): damage_taken(charges_spark) flag is single-purpose — future listeners must not assume all emissions charge the Spark. Boon-pool exhaustion gate fix rides this corrections job.
- HZ-103 corrections note: SPECIAL and CAST are still signal-only placeholders (no runtime damage subscriber, same class as the fixed attack gap) — fold live wiring into HZ-071 or a dedicated ticket before any combat-depth work relies on them.
| HZ-073 | live-run hotfixes: off-world spawns + door-swap physics-callback free | Codex | feel | done | 103 |
- Ceremony #3 (2026-07-06, post PR #18): attack chain PROVEN live end-to-end (try_activate → attack_started → resolver → chaff killed; Spark gauge charged to 85% from damage dealt; rooms_cleared reached 1 live). Two NEW live defects → HZ-073. Harness note (playbook-worthy): MCP-bridge injected InputEventAction/mouse_button events do NOT reach _unhandled_input handlers (router is event-based); movement worked because the motor polls Input state. Future ceremonies: drive abilities via try_activate or real key bindings, and treat injected-event silence as a bridge limitation, not a game bug.
| HZ-074 | SPECIAL/CAST live damage wiring | Codex | feel | done | 071 |
| HZ-075 | THE CUSTODIAN first boss (design/boss-custodian.md) | Codex | boss | done | 074 |
- Evening creative-direction block (Shane 2026-07-06, "full creative direction... until 10"): Fable authored design/boss-custodian.md (Megaera-pattern transposition onto the counterfeit-authority hyperscaler; HP 2400, 75/50/25 ladder, boss-owned adds through existing spawn machinery, TelegraphMarker greybox primitive). Roadmap: HZ-072 → HZ-108 → gate #2 → HZ-074 → HZ-076 (gizmo.glb player visual) ∥ HZ-077 (room mood lighting) → HZ-075 boss.
- Fable strategic gate #2 (2026-07-06 evening, post PRs #15-#21): VERDICT — system coherent; audits are catching real defects at every wave (fallback sentinel, tier-0 dump, boon-pool exhaustion, dead attack pipeline all caught before or at merge). Feel: live behavior matches probes (sim honest); human playtest pending tonight. Decisions: (1) run_orchestrator.gd is now ~950 lines and gains two more resolvers in HZ-074 — HZ-079 (extract a CombatResolvers module: melee/surge/special/cast + damage/Spark plumbing behind one seam) is MANDATORY between HZ-074 and HZ-075 so the boss lands on a clean seam; (2) benefactor validation is not wired into generic .tres authoring paths — acceptable until hand-authored boons exist, flagged for the lore-canvas handoff; (3) SPECIAL/CAST wiring launching now (HZ-074); boss design authority complete (design/boss-custodian.md).
| HZ-079 | extract CombatResolvers module from run_orchestrator (god-module split) | Codex | arch | done | 074 |
| HZ-076 | gizmo.glb player visual (capsule replaced, procedural motion) | Codex | look | done | — |
| HZ-077 | room mood lighting per type (gouache-lit greybox) | Codex | look | done | — |
- HZ-074/076/077 audit rulings (2026-07-06 evening): through-wall cast ACCEPTED v1 (open arenas; revisit at boss geometry); room-exit shard auto-reclaim KEPT (Hades bloodstone parity); HZ-077 received proportional audit (zero logic — live visual verification + green validator suites instead of finder pair); run_all_checks.sh rewritten to auto-discover all scripts/suites after audit found the gate orphaned at 5 suites; dead _face_direction rotation writer deleted from gizmo_player.gd (was neutralized only by scene data).
| HZ-080 | hub identity: gizmo.glb placeholder swap + anchor labels + void blocker | Codex | look | done | — |
| HZ-081 | first-room pacing: tier-0 wave-count floor + inter-wave beat | Codex | feel | done | 071 |
| HZ-082 | stale-import brick: hub error surface + doorway blocker + sync docs | Codex | ship | done | — |
| HZ-083 | combat-room baseline lighting warmth | Codex | look | done | 077 |
| HZ-084 | combat feedback kit (hit flash, death pop, surge ring, stagger read) | FABLE | feel | done | — |
- Director's playthrough (2026-07-06 evening, Shane-directed): survived 3:31 with the full kit live, zero errors; demo backlog at queue/DEMO-POLISH-BACKLOG.md. Headline gap: combat feedback (HZ-084, Fable-owned). Process: merged-checkout sync ritual now includes --import (stale class-name cache bricked the run door and revealed the void-walk).
| HZ-090 | ElevenLabs audio wired live (10 SFX + 2 music loops, demo-provisional) | Codex | audio | done | 104 |
| HZ-091 | meshy enemy models (chaff/bruiser/elite/Custodian GLBs) | Codex | look | done | — |
| HZ-092 | title screen + settings (volume buses, persistence) | Codex | ship | done | — |
- FULL-SEND block (Shane 2026-07-06 ~8pm, 2h to playtest): ElevenLabs limit test PASSED (10 SFX + 2×60s music loops generated, converted 48k per canon, provenance+ledger in gizmo-audio-canon/generated/elevenlabs/); meshy limit test PASSED (4 textured models, ~75 credits of 2557: chaff/bruiser/elite meshy-5+refine, Custodian meshy-6+refine). Three concurrent Codex jobs wiring it all.
| HZ-095 | AudioDirector v2: 61-cue soundtrack live (dual-variant, spec-driven) | FABLE | audio | done | 090 |
- ZOOM-OUT correction (Shane, 2026-07-06 night): the demo wave generated new music beside the produced 61-track score. Full ecosystem survey done → docs/hades-pivot/ECOSYSTEM-WIRING-PLAN.md (5 phases: soundtrack v2 tonight; asset-pipeline promotion, gouache render target, region-grammar consumption, lore promotion queued for tomorrow — all executable without Fable). Reconciliation notes filed lab-side (audio-canon: EL batch provisional; asset-pipeline: 4 models are draft witnesses owing retro-briefs). All 61 cues converted to godot/audio/music/soundtrack_v2/.
| HZ-096 | asset retro-promotion: 4 demo models through the lab | — | assets | done (fable-assets settled the lab debt: retro-briefs, promotion report, ledger; Custodian Blender decimation still owed lab-side) | plan-P2 |
| HZ-097 | gouache render target (CompositorEffect route) | design-lab-blocked | look | pending SHADER-ARCH-01 (fable-look shipped the matrix-compliant baked-first grade; the post-pass route stays the lab's open decision) | plan-P3 |
| HZ-098 | region grammar into the run generator | — | rooms | done (fable-level: region_table.gd, toasts, dressing, trial beat) | plan-P4 |
| HZ-099 | lore promotion request: benefactor names + game copy | lore-canvas | lore | sent (promotion-request-2026-07-06-game-copy.md filed lab-side; awaiting canon promotion) | plan-P5 |
- Phase 2-5 authority: docs/hades-pivot/ECOSYSTEM-WIRING-PLAN.md + each sibling's canon (read owning canon FIRST per ecosystem protocol).
- PLAYTEST FEEDBACK (Shane, 2026-07-06 ~10pm, first human session): (1) music shifts far too frequent — songs never build; new strategy = long-form vibe-setting, lean heavy into JAZZTRONICA SEGs + BRG bridges for combat slices, switch on run milestones not per-room; (2) attacks need more feedback — DAMAGE NUMBERS; (3) dash needs a short cooldown; (4) combat must feel fluid and engaging, not flat. Directive: full Fable pass on the whole game — one Fable agent per lab folder (Shane explicitly overrides the no-Fable-subagent tiering law for this push), world must be immersive and beautiful.
| HZ-100 | music strategy rework: long-form composition pacing (Shane note 1) | FABLE-audio | audio | done | 095 |
| HZ-101B | damage numbers + dash cooldown + combat fluidity (Shane notes 2-4) | FABLE-combat | feel | done | 084 |
| HZ-102B | gouache look pass per design-system canon | FABLE-look | look | done | plan-P3 |
| HZ-103B | region grammar + level identity per level-design canon | FABLE-level | rooms | done | plan-P4 |
| HZ-104B | lore copy pass: telegraphs, boons, codex voice per lore canon | FABLE-lore | lore | done | plan-P5 |
| HZ-105B | AAA animation pipeline: rig/clips/weapon, movement identity | FABLE-assets | assets | done | plan-P2 |
| HZ-106B | wire-next from asset lab: beacon HearthLight state, sanctuary relief zone, gear_gate open state; hub sky one-liner; room-clear sting playback; bridge_arch kit-bash | any | world | ready-for-agent | 34 |
| HZ-107B | deflake stochastic contact-damage balance check (~50% flap, flagged by asset lab + 2 ship batteries) | codex | tests | ready-for-agent | 34 |
| HZ-108B | design-sweep follow-ups: world-state palette tinting in-engine; region voice dialects into room identity | FABLE | look/lore | backlog | 34 |
