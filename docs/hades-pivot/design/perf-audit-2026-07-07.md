# Performance audit — 2026-07-07

Read-only review of `project.godot`, room scenes, `combat_effects.gd`, enemy scripts,
and `audio_director.gd`. Findings ranked by expected runtime impact during combat-heavy
rooms. Fixes are integration-ready; `NodePool` + `PerfProbe` utilities ship separately.

---

## 1. Combat FX allocates nodes, meshes, materials, and tweens per hit

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `combat_effects.gd:25-44` | Every damage event `Label3D.new()` + `create_tween()` + `queue_free()` — 2–4 FX per melee swing at 3–8 Hz. | Pool `Label3D` via `NodePool`; reset text/modulate on acquire; single shared tween driver or manual lerp. | Large reduction in allocator churn and orphan spikes during dense fights. |
| `combat_effects.gd:76-87` | `flash_hit` allocates `StandardMaterial3D.new()` per flash; overwrites `material_override` on mesh. | One cached flash material per archetype; tween emission only. | Removes per-hit material alloc + GC pressure. |
| `combat_effects.gd:129-151` | `spawn_burst_ring` builds `MeshInstance3D` + `TorusMesh` + material + tween per death/surge. | Pooled ring mesh with shared unshaded material; scale/alpha reset on release. | Noticeable drop in mesh/material churn on AoE kills. |
| `combat_effects.gd:156-177` | `spawn_swing_wedge` same pattern with `PrismMesh.new()` per attack. | Pool wedge instances; reuse one prism mesh resource. | Cuts 1–2 allocations per player attack. |
| `combat_effects.gd:199-206` | `_first_mesh` DFS walk on every flash/stagger/death. | Cache `MeshInstance3D` ref on enemy visual at configure time. | Small per-hit CPU save; scales with enemy count. |

---

## 2. CSG room geometry — runtime mesh bake + draw-call growth

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `combat_large.tscn:61-155` | 17 `CSGBox3D` nodes (floor, obstacles, 3 dressing variants). CSG bakes meshes at load; each box is a separate draw + collision body. | Bake to single `MeshInstance3D` + `ConcavePolygonShape3D` (or merged trimesh) at authoring time; keep one dressing variant per exported scene. | Major GPU win: 17→2–4 draws per dressed room; faster room load. |
| `combat_small.tscn:61-100` | 15 CSG nodes with same pattern. | Same bake/merge pass. | Proportional draw-call reduction in the default combat template. |
| `run_orchestrator.gd:353-367` | All dressing variants instantiate, then 2 of 3 are `queue_free()`'d. | Author one variant per `.tscn` resource (or hide via export flag before `_ready`). | Avoids creating ~6 CSG bodies that are immediately destroyed. |
| Each room `WorldEnvironment` + `DirectionalLight3D` | Duplicate env/light per room (`combat_large.tscn:49-57`, `run.tscn:38-41` adds a third light). | Single run-level env; room scenes contribute anchors only. | Fewer shadow casters and env state changes on room transition. |

---

## 3. Spawn placement O(spawns × enemies) during waves

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `run_orchestrator.gd:621-627` | `SPAWN_CANDIDATE_COUNT` (48) candidates per spawn. | Spatial hash or incremental golden-angle with early exit once separation met. | Wave spawn bursts become O(n) not O(48n). |
| `run_orchestrator.gd:680-685` | `_nearest_spawned_enemy_distance` scans all `spawned_enemies.values()` per candidate → **O(48 × E)** per enemy spawned. | Maintain live enemy position array; squared-distance early-out. | At E=12, ~576 distance checks/spawn → ~12 with index. |
| `run_orchestrator.gd:306-307` | `_spawned_enemy_snapshot()` returns `spawned_enemies.values()` (new view each call). | Return cached `Array` rebuilt only on spawn/death. | Removes alloc on every combat resolver query. |

---

## 4. Combat resolver scans and HUD refresh on every ability

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `combat_resolvers.gd:284-293` | `_damageable_enemy_snapshot()` allocates typed `Array` and filters full snapshot per melee/special/cast/surge. | Cache damageable list; invalidate on spawn/death only. | 1–4 array builds per player input frame eliminated. |
| `combat_resolvers.gd:197-201` | Melee iterates all damageable enemies (O(E)) — acceptable alone, compounds with snapshot alloc. | Combine with cached list + arc pre-filter by distance. | Modest CPU at E>8. |
| `combat_resolvers.gd:468-470` | `_render_hud()` after every attack/cast/surge (7 call sites). | Event-driven HUD: vitals on change, abilities on cooldown edge only. | Fewer `get_node_or_null` tree walks per combat frame (`run_orchestrator.gd:1072-1078`). |
| `combat_resolvers.gd:322-349` | Cast miss spawns full `Area3D` + `CollisionShape3D` + `MeshInstance3D` + material per stone. | Pool cast-shard pickups (same seam as damage numbers). | Removes orphan risk when spam-casting. |

---

## 5. Physics layer/mask waste (everything on layer 1)

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `project.godot:127-130` | Jolt enabled but **no** `layer_names` configured; scenes set no `collision_layer`/`collision_mask` (`gizmo_player.tscn`, `greybox_enemy.tscn`, room CSG all default to layer 1). | Define layers: World, Player, Enemy, Pickup, Trigger; masks so enemies don't collide with each other, pickups don't hit world. | Narrower broadphase pairs; fewer enemy-enemy slide solves. |
| Room CSG `use_collision = true` on dressing props | Decorative pillars participate in full physics alongside gameplay obstacles. | Visual-only dressing on layer 0 or static body with mask excluding enemies. | Less Jolt contact manifold work in dressed rooms. |

---

## 6. Per-enemy frame work scales linearly

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `enemy.gd:47-69` | Every live enemy runs `_physics_process` + `move_and_slide()` even when staggered/spawning (still calls slide). | Disable physics process when idle/staggered; central director tick for off-screen enemies (later). | Linear CPU reduction as E grows. |
| `enemy_visual.gd:67-100` | Cosmetic `_physics_process` on every enemy (bob/spin/bank). | `_process` at lower rate or batch in orchestrator cosmetic pass. | ~E fewer physics callbacks/frame. |
| `enemy.gd:141` | `raw_event.duplicate(true)` deep-copies damage dict on every contact hit. | Emit shallow dict or pooled event object. | Small alloc per enemy attack landing. |

---

## 7. Audio stream loading strategy

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `audio_director.gd:427-432` | SFX manifest `load()` at `_ready` — **good** for combat responsiveness. | Keep; optionally `ResourceLoader.load_threaded_request` during title screen. | Already low combat latency; threaded preload hides title hitch. |
| `audio_director.gd:827-833` | V2 music/voice `_load_stream` via `ResourceLoader.load` on first play; cached in `_cue_registry` / `_voice_registry` after. | Prewarm arc SEG paths in `begin_run_silence()` or after first room load. | Removes first-combat music stutter (50–200 ms class). |
| `audio_director.gd:494-517` | `notify_vitals` creates new `Tween` on guard-break transitions. | Reuse vitals tween slot; guard state edge detect in orchestrator (already calls from damage path). | Minor; avoids duplicate tweens on rapid guard chip. |
| `audio_director.gd:361-367` | Music crossfade `create_tween()` per zone change (infrequent). | Acceptable; kill prior tween already handled. | — |

---

## 8. Boss / telegraph allocations (elite room peak)

| Location | Why it costs | Fix | Expected gain |
|---|---|---|---|
| `boss_brain.gd:95-99` | `attack.duplicate(true)` ×3 per `begin_next_attack`. | Store immutable attack defs; emit `StringName` id + refs. | Small dict churn during boss phase transitions. |
| `telegraph_marker.gd:87-111` | Runtime `MeshInstance3D` + mesh + material per telegraph (boss fights). | Pool telegraph markers keyed by shape. | Visible during Custodian fight spike. |

---

## 9. project.godot configuration notes

| Setting | Observation |
|---|---|
| `config/features=Forward Plus` | Appropriate for desktop; mobile preset uses `gl_compatibility` — watch shader cost on CSG + gouache grade (`run.tscn:68-78` full-screen post). |
| `common/physics_interpolation=true` | Good for player/camera; ensure pooled FX reset transforms on acquire to avoid interpolation ghosts. |
| Autoload `AudioDirector` only | No global perf probe yet — `PerfProbe` ready for ceremony scripts. |

---

## Recommended integration order

1. Pool damage numbers + burst rings (`combat_effects.gd` → `NodePool`).
2. Bake CSG rooms to static meshes (largest draw-call win).
3. Physics layer split + dressing collision strip.
4. Cached enemy snapshot + spawn placement index.
5. HUD event-driven refresh.
6. Audio v2 prewarm during run silence window.

Use `PerfProbe.sample_over_frames(get_tree(), 120)` at room entry, mid-combat, and room clear to verify each pass.