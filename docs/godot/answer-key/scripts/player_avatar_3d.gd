class_name PlayerAvatar3D
extends Node3D

## Display-only 2.5D adapter for the simulation-owned player state.
## Movement and rules remain in Simulation; this node only maps snapshots to stage space.

@onready var _visuals: Node3D = $Visuals
@onready var _face_marker: Node3D = $Visuals/FaceMarker

func apply_snapshot(player: Dictionary) -> void:
	global_position = SimSpace.to_world_from_snapshot(player)
	var facing_x: float = float(player.get("facing_x", 1.0))
	_face_marker.position.x = absf(_face_marker.position.x) * (-1.0 if facing_x < 0.0 else 1.0)
	_visuals.rotation.y = 0.0 if facing_x >= 0.0 else PI
