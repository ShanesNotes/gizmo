class_name CameraRig3D
extends Node3D

## Display-only camera follow adapter for the orthographic 2.5D stage.
## Simulation owns positions; this rig follows already-mapped stage coordinates.

@onready var camera: Camera3D = $Camera3D

func follow_stage_position(stage_position: Vector3) -> void:
	global_position = stage_position
	camera.current = true
