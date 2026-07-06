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
| HZ-003 | `room_camera.gd` bounds-clamped follow + transition cut (room-graph doc §2, corrected) | Sonnet | HP-3 | blocked:HZ-002 | 002 |
| HZ-004 | `RoomDirector` per-room (difficulty_tier pressure, room-clear signal) | Opus | HP-4 | blocked:HZ-002 | 002 |
| HZ-005 | room scene contract validator (CameraAnchor, SpawnMarker, RoomExit) | Sonnet | HP-4 | ready-for-agent | 001 |
| HZ-010 | ability kit data model (`AbilityDef` / run loadout; cite `ability-kit.md`) | Opus | HP-5 | done | — |
| HZ-011 | dash ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-012 | attack ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-013 | special ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-014 | cast ability implementation | Sonnet | HP-6 | done | 010 |
| HZ-015 | gizmo ability input wiring (actions → kit) | Sonnet | HP-6 | ready-for-agent | 011–014 |
| HZ-020 | `BoonDef` resource model (authored boon table; run-scoped ranks) | Opus | HP-7 | done | — |
| HZ-021 | boon draft roller + apply logic (between-room offers) | Opus | HP-8 | done | 020 |
| HZ-022 | `boon_draft.tscn` UI (3-card choice; signal contract) | Sonnet | HP-9 | ready-for-agent | 021 |
| HZ-023 | RunController boon-draft bridge (pause run, overlay, resume) | Sonnet | HP-9 | blocked:HZ-002,021,022 | 002,021,022 |
| HZ-030 | door unlock on room clear (`RoomConnection.door_name`) | Sonnet | HP-10 | blocked:HZ-002,004 | 002,004 |
| HZ-031 | reward telegraph (door shows destination's generation-time `reward_type`) | Haiku | HP-11 | blocked:HZ-030 | 030 |
| HZ-032 | room transition orchestration (mark REWARDED, free/load, boon gate) | Opus | HP-2,10 | blocked:HZ-003,023,030 | 003,023,030 |
| HZ-040 | `meta_state.gd` save/load (Sparks/Scrap meta, schema_version) | Sonnet | HP-12 | done | — |
| HZ-041 | hub scene (death return; codex/Brass Sphere frame) | Opus | HP-13 | ready-for-agent | 040 |
| HZ-042 | death → hub → new run flow | Sonnet | HP-13 | blocked:HZ-002,040,041 | 002,040,041 |
| HZ-043 | meta bonuses injected at run start | Sonnet | HP-8 | done | 021,040 |
| HZ-050 | HUD retire Path A chrome (beacon, level, XP bar) | Sonnet | HP-14 | done | — |
| HZ-051 | HUD ability bar (dash/attack/special/cast) | Sonnet | HP-14 | blocked:HZ-015 | 015 |
| HZ-052 | HUD boon loadout display | Sonnet | HP-14 | ready-for-agent | 021 |
| HZ-053 | HUD guard-over-HP carry-forward | Sonnet | HP-14 | ready-for-agent | — |
| HZ-060 | greybox `RoomTemplate` pool (combat + boss scenes) | Sonnet | HP-15 | blocked:HZ-005 | 005 |
| HZ-061 | full-run integration gate | Opus | HP-15 | blocked:HZ-032,042,051,052,060 | 032,042,051,052,060 |
| HZ-062 | end-screen hub-return copy + stats | Haiku | HP-13 | blocked:HZ-042 | 042 |

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
- No ready-for-human labels emitted; open calls are decided in design anchors above.