# Animation pipeline — Meshy credit ledger

Session: 2026-07-06, Fable animation-pipeline agent (branch hades-clone).
Policy: ledger-before-use; stop and reassess past ~150 credits cumulative.

| # | date | action | task id | credits | balance after | notes |
|---|------|--------|---------|---------|---------------|-------|
| 0 | 2026-07-06 | meshy_check_balance | — | 0 | 2462 | starting balance |
| 1 | 2026-07-06 | rig attempt — ABORTED before spend | — | 0 | 2462 | gizmo.glb has no Meshy task in this account (list_tasks/list_models checked); upload of the private asset to a public host was denied by permission policy. No retry-spend. Character clips pivot to local Blender authoring per lab canon (gizmo-asset-pipeline briefs/character/gizmo_clips.brief.yaml: author on skeleton copies, never AI-rig the shipped mesh). |
| 2 | 2026-07-06 | meshy_download_model (brass wrench, pre-existing SUCCEEDED text-to-3d task from earlier session; generation credits were spent by that session, not this one) | 019f3a68-b47e-7a83-86a9-c21b6980f3f9 | 0 | 2462 | download only; sidecar written next to asset |

| 3 | 2026-07-06 | note: raw wrench download superseded | 019f3a68-b47e-7a83-86a9-c21b6980f3f9 | 0 | 2462 | the concurrent asset lane promoted the same Meshy task as res://assets/props/brass_winding_wrench/ (own provenance sidecar); my raw godot/assets/weapons/ copy was removed in favor of it. No duplicate spend. |

Cumulative spend this session: **0 credits** (balance 2462 → 2462).

## Enemy animation lane (2026-07-06, Fable enemy-animation principal)

| # | date | action | task id | credits | balance after | notes |
|---|------|--------|---------|---------|---------------|-------|
| E0 | 2026-07-06 | meshy_check_balance | — | 0 | 2446 | lane start (other lanes spent 16 since row 0) |
| E1 | 2026-07-06 | meshy_rig bruiser (test-on-one per lead directive; refine task 019f39ea-ebfd; includes walk+run) | 019f3ab6-6155-792a-afeb-93e2100079fa | 5 | 2441 | SUCCEEDED; 24-bone humanoid rig, mesh intact, walk reads at camera (proof frames in session scratchpad). ACCEPTED |
| E2 | 2026-07-06 | meshy_rig elite (rig-honesty gate passed on bruiser; refine task 019f39eb-5b46; includes walk+run) | 019f3aba-4956-7994-ae98-8c0cfdef14da | 5 | 2436 | SUCCEEDED; same 24-bone humanoid rig, mesh intact. ACCEPTED. Custom clips (idle/attack/hit/death) Blender-authored on both rigs, zero credits — meshy_animate action ids are uncatalogued and no-retry-spend forbids blind 3-credit guesses |

Enemy lane spend: **10 credits** (2446 → 2436).

### Enemy lane outcome (2026-07-07)
Bruiser + elite ship as rigged GLBs with a six-clip contract (walk/run free
with the rigs; idle/attack/hit/death hand-keyed via
tools/animation/author_enemy_clips.py; per-pose stills reviewed at the Diablo
camera). godot/assets/enemies/*_rigged.glb + provenance sidecars; original
unrigged GLBs untouched. Runtime is the two-tier
scripts/enemies/enemy_animation_controller.gd (authored clips supersede, code
poses guarantee), attached by EnemyVisual whenever a model carries a
Skeleton3D. Attack-clip apexes match the enemy_brain windups (0.85s bruiser /
1.05s elite); walk speed-scales to velocity. Elite locomotion stays the
procedural dead-level glide (poised idle stance while moving) per its brief.
Chaff stays procedural-plus: aggression roll-shiver during brain windup,
tumble-and-sink death. Custodian stays procedural-plus: windup presence shift
(rise + lean-in, survey freeze) and a glacial power-down death sink. Suites
green: enemy 199 / boss 110 / orchestrator 3.

## Outcome (2026-07-06)
Character clip set delivered zero-credit via local Blender authoring
(tools/animation/author_gizmo_clips.py → godot/assets/animations/gizmo_clips.glb
+ provenance sidecar): idle, run, attack, special, dash, hit, death, victory on
the shipped 53-bone rig (shipped gizmo.glb untouched). Runtime consumption is
the team-lead-ruled graft seam in gizmo_animation_controller.gd (authored clips
supersede code-built per name; wrench mount follows the attack clip's swinging
hand, Bone_019 chain). scripts/player/gizmo_animator.gd (AnimationTree
locomotion blend + one-shot slots) is delivered and tested but currently
unwired from gizmo_player.tscn per the concurrent-lane scene state; re-enable =
two lines (ext_resource + node), arbitration is built in.
