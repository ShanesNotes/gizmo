# First Enemy Visual Log — Nibbler 01

## Goal

Create the first real enemy body for the 3D Godot slice without changing the rule source of truth. `Simulation` still owns enemy stats, spawning, chasing, contact damage, defeat, and Spark drops; `godot/scenes/enemy.tscn` is the renderable view that `GameController` moves to each simulated enemy position.

## Meshy generation

- Tool: `meshy_text_to_3d`
- Model: `meshy-5`
- Credits: 5
- Task ID: `019ee730-a647-73a5-93f1-964386c56e55`
- Output format: `glb`
- Imported asset: `godot/assets/enemies/nibbler_01.glb`

Prompt:

> Low-poly corrupted clockwork trash mob enemy for a fixed-camera Godot 3D rogue-lite, small skittering scrap creature, brass claws, dark iron shell, teal cracked rune glow, cute but hostile silhouette, readable from a Diablo-style camera, no text, no background, game asset.

## Godot integration

- `godot/scenes/enemy.tscn` now mounts the generated GLB at `MeshyImportSlot/GeneratedGLB`.
- The GLB is scaled to `0.8` and lifted by `0.6034m` so its imported bounds sit on the ground plane.
- `godot/scripts/enemy_visual.gd` keeps metadata and tiny test helpers on the visual scene.
- `AnimationPlayer` adds a looping `skitter_bob` child animation so the spawned enemy reads as alive while the root remains controlled by `GameController`.
- `GeneratedMeshStyler` applies a dark teal/iron material override so the enemy separates from Gizmo and the arena under the fixed camera.
- The old red sphere proxy remains hidden as a readable fallback reference, but the generated Meshy mesh is the active visible enemy.

## Import inspection

After `godot --headless --path godot --import --quit`, the raw imported GLB bounds were approximately:

- position: `(-0.681, -0.754, -0.702)`
- size: `(1.358, 1.493, 1.401)`
- center: `(-0.002, -0.008, -0.001)`

The wrapper keeps the asset Y-up. No extra corrective rotation is applied.
