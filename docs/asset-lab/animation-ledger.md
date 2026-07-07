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
