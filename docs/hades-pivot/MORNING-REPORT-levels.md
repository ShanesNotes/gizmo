# Morning report — levels lane (night of 2026-07-07)

**Lane:** levels · **Branch:** `night/levels` · **PR:** #41 (open, green — see "merge blocked" below)
**Orchestrator:** Fable 5 (Shane's explicit lane assignment) · **Codev:** GPT-5.5-Codex xhigh, 3 briefs · **Audio:** Sonnet subagent in gizmo-audio-canon

## What shipped (waves 1-3, all on PR #41)

### Wave 1 — HZ-106B + hub-as-home + dressing infrastructure
- **Hub**: cosmos panorama sky (placeholder ProceduralSky retired); campfire locus + seat stones, gear-ring mirror fixture, orrery codex desk, threshold gear-ring + braziers at THE VIGIL. After the lore lane's merge, braziers were re-placed to frame their saint shrines.
- **HZ-106B wire-next**: `beacon_landmark.gd` (DORMANT/REKINDLING/REKINDLED drives HearthLight); `gear_gate.gd` open state (collision off, model sinks, tweened in-tree); `bridge_arch_01` kit-bashed from platform_small + gear_ring; `sanctuary_01` installed as rest_alcove's physical relief locus (3.5m fixture zone per asset-lab metadata, greybox cylinder retired); `sting_room_clear.ogg` fires on CLEARED via the SFX pool.
- **Found + fixed a silent regression**: `dressing_loader.gd`'s `ASSET_PATH_CANDIDATES` pointed at nonexistent `assets/world_kit/` — every grammar-dressing placement had been greyboxing despite installed kit. Real scenes now resolve (with `ASSET_SCALE_OVERRIDES` clamps; gear_ring 30m→3.6m for punctuation use).
- **threshold_frame placement**: canon's door-apron cluster was never placed; now bridge_arch frames every door, derived from door layout alone — zero rng consumed, seed streams untouched. Missing-asset guard: a threshold piece never falls back to a placeholder (would wall the door).
- **Validator landed game-side**: `tools/validate_dressing_map.py` + tests (17/17 rejection tests, self-check ACCEPT), grammar path retargeted to `docs/reference/dressing-grammar.json`.

### Wave 2 — act-1 region identity
- **RegionLayers seam** in dressing_loader: rooms carry `RegionLayers/RegionLayer_<ID>` subtrees; only the run region's layer survives (pure name-match, rng-free). Tested.
- **Hand-authored layers** (Codex brief 2) in combat_small/combat_large/elite_arena: HEARTH warm-brass platforms, BRASS cream-stone terraces + gear silhouette, VERDANT moss mounds + violet memory motes, RUST half-buried titan slabs + oil slicks. Each layer: palette light rig, cover with real elevation reads, +z vista apron (region-tinted Meridian-falling-away silhouettes), one secret SCRAP_CACHE alcove with glint.
- **Region ambience**: four 58s looping beds (HEARTH/BRASS/VERDANT/RUST) generated in gizmo-audio-canon (sequential EL, ledger + provenance lab-side, demo-provisional per batch precedent), installed to `audio/ambient/`, played on the Ambience bus, swapped by the region resolve at room load. Notes: EL caps at 30s/call — beds are 28s unique loops crossfade-doubled; loudness finishing deferred to a dedicated pass (beds measured -60..-25 LUFS, canon target -18).

### Wave 3 — variants + stage-two tease
- **Layout variants** (Codex brief 3): `DressingVariantA/B` in five room scenes (combat ×3, reward, shop) — genuinely different tactical reads; orchestrator's existing rng.state pick chooses one per visit. Door clearance 0.25 normalized + spawn keep-out, tested.
- **Stage-two tease** in elite_arena: closed gear_gate at the far perimeter of RegionLayer_VERDANT (PRISM violet/cyan bleed) and RegionLayer_RUST (ASH ember/violet), each with a distant vista slab beyond. Tease lights boosted after a live check showed the bleed too weak (1.4→4.5 energy). Cyan appears in tease LIGHTS only — recorded design decision: stage-two palette bleed, never on geometry materials.

## Ceremony shots (docs/hades-pivot/ceremony/levels/)
hub-home, hub-merged-npcs, real-kit-dressing (live run), combat-small HEARTH/BRASS/VERDANT/RUST, elite VERDANT stage-2 tease.

## Verification
Full battery green before each push (waves 1-2 battery, wave-3 battery at close — see git log). Suites grew: room pool 321→598, orchestrator 433→447, audio 140→148, world-kit 26 (new). Known stochastic contact-damage flake reran once per protocol. Two documented test-margin decisions: inter-wave TEST_DELAY 0.2→0.6s (absorbs real-asset first-load hitch frame — measured, commented); apron test exempts threshold_frame (canon places it IN the apron).

## Blocked / needs Shane or sheriff
1. **PR #41 merge**: the session's permission mode blocks self-merge (twice, explicitly: loop-brief "self-merge on green" does not clear it). PR is green and ready — merge it and run the play-checkout sync (I could not run the post-merge sync without the merge).
2. **Daily vault note**: sandboxed subagents couldn't write `/home/ark/memory` — levels-lane entry appended by the orchestrator directly (see Daily/2026-07-07.md).

## Follow-ups (queued for INDEX)
- Region palette should reach the FLOOR and fog, not just light rigs — that's HZ-108B (world-state palette tinting in-engine); tonight's layers make it urgent-visible.
- Room-entry first-load hitch (~100-300ms) when a kit asset first resolves — consider a boot-time preload of the 9 kit scenes.
- Ambient beds owe a loudness finishing pass (audio lab, A10 gating) + A1 canon registration when promoted from demo-provisional.
- rest_alcove/reward/shop have no RegionLayers yet (combat rooms only tonight) — cheap extension of the same seam.
- Meshy spend intentionally skipped: canon's gap note licenses kit reuse under region palettes until per-region kits ship; bridge_arch was kit-bashed. Per-region kit briefs (VERDANT flora, RUST titan parts) are the asset lab's next natural batch.
- Lab-side: `gizmo-level-design` has the uncommitted dressing-grammar canon/witness/validator work this night consumed — needs a lab commit (not done; lab law commits only when asked).

## Revival close-out (2026-07-07)
A finisher session revived the lane after the prior agent rebased but died before the force-push.

- **Trunk integration**: merged origin/gizmo-3d twice — first cef2480 (core PRs #45/#46: enemy/boss/damage-number work), then eb93ac4 after **design's PR #38 landed**. Both merges auto-resolved (ort); no textual conflicts on any levels file.
- **hub.tscn ruling compliance** (SHERIFF-ALERTS 05:00): after the second merge, hub.tscn correctly carries BOTH — levels' GradeLayer/GradeRect geometry AND design's two look_grade lines (`ext_resource scripts/ui/look_grade.gd id=5_look_grade` at the top + `script = ExtResource("5_look_grade")` on GradeRect). Verified present post-merge; levels added nothing to hub.tscn — design's attach arrived through its own PR #38 as the ruling intended.
- **Ember Alcove magnet-radius regression** (commit 892d46f): restored to pickup default in rest_alcove.tscn — carried intact through both merges.
- **Battery**: full `tools/godot/run_all_checks.sh` (auto-discovered syntax-check of every script + every run_*_tests.gd suite) + `tools/validate_dressing_map.py`. Validator RESULT: ACCEPT (6 archetypes, 7 room archetypes, 10 regions). All suites green **except** `run_boss_tests.gd` (158 passed, 2 failed).
- **The 2 boss failures are PRE-EXISTING trunk redness, not a levels regression** — proven by running the suite on a clean detached `origin/gizmo-3d` (cef2480): identical `FAIL - boss arena instances the Custodian GLB model` + `FAIL - presence fixture has pivot + model + motion API`, same 158/2 count. The custodian_boss.glb instance node `CustodianBoss/VisualPivot/CustodianBossModel` "vanishes" on import ("was modified from inside an instance, but it has vanished"). boss_arena.tscn and the custodian GLB/scene are **outside the levels fence** (rooms/** except boss_arena) and were untouched by both the levels lane and the design merge (verified `git diff --stat cef2480..eb93ac4` empty for those paths). This belongs to the core/assets lane — flagging for a sheriff alert / follow-up; the levels lane neither caused it nor can fix it in-fence.
- **Force-pushed** night/levels → origin (442506c). **PR #41 now reports MERGEABLE / CLEAN.** Held for Shane per protocol — no self-merge.
