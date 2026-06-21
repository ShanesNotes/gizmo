extends Camera3D

## The node to follow — assign Gizmo in the Inspector.
@export var target: Node3D
## Camera position relative to the target — preserves the Diablo height/distance.
@export var offset: Vector3 = Vector3(0.0, 12.0, 10.0)
## How quickly the camera catches up (higher = snappier).
@export var follow_speed: float = 8.0

func _ready() -> void:
	# We move the camera ourselves every render frame, so it must opt out of
	# physics interpolation (otherwise it fights our updates and warns).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _process(delta: float) -> void:
	if target == null:
		return
	# Plain critically-damped follow — no idle bob, no trauma shake (stripped
	# 2026-06-21; the bobbing/shake read as bad juice). Fixed Diablo pitch.
	var target_position := target.get_global_transform_interpolated().origin
	var desired := target_position + offset
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight)
