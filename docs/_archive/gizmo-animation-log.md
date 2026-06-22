# Gizmo Animation Log

Date: 2026-06-21

Scope: OMX G004 — improve Gizmo movement animation from the downloaded walk sheet.

## Decision

Meshy animation was not used for this slice. The canonical playable Gizmo remains
`godot/assets/gizmo.glb`, and the downloaded sprite sheet is now a local
reference, not a runtime 2D replacement.

The earlier stiff clanker bob stays as the readability layer because it reads well
from the fixed Diablo camera. The improvement is a more deliberate six-pose gait:
body lean/squash is quieter, the timing follows the sprite reference row, and the
existing rig bones swing arms/legs more clearly.

## Reference assets copied

- `godot/assets/reference/gizmo/gizmo_walk_sheet_6x6.png`
  - Source: downloaded 36-frame Gizmo walk sheet.
  - Size: 2064x4320, 6 columns x 6 rows.
  - Frame cell: 344x720.
- `godot/assets/reference/gizmo/gizmo_walk_pose_row.png`
  - Lightweight six-pose strip generated from the top row for quick review.

## Implementation

`godot/scenes/gizmo.tscn`:

- `walk_bob` is now a 0.72s looping cycle with six poses plus loop close.
- Pose spacing is 0.12s, matching the six-pose contact/lift/pass rhythm from the
  reference strip.
- Existing rig tracks were preserved and amplified conservatively:
  - `Bone_010`, `Bone_015` — leg/hip swing.
  - `Bone_009`, `Bone_014` — knee motion.
  - `Bone_023`, `Bone_028` — arm/shoulder counter-swing.

`godot/scripts/gizmo.gd`:

- Adds `walk_reference_sprite_sheet_path` for future teaching/pipeline traceability.
- Adds `walk_animation_cycle_seconds = 0.72` so the authored clip and reference
  cadence stay documented in code.
- Scales walk playback speed slightly from actual horizontal speed, then resets
  to 1.0 for idle.

## Verification intent

The tests lock the asset reference, frame dimensions, loop cadence, rig-track key
counts, movement-driven switching, and playback-speed reset. This keeps Gizmo as a
true 3D rigged character while still using the sprite sheet as concept/timing
source material.
