class_name GizmoVisual
extends Node3D

@export_group("Facing")
@export var turn_speed: float = 10.0

@export_group("Procedural Motion")
@export var idle_bob_amplitude: float = 0.045
@export var idle_bob_frequency_hz: float = 1.25
@export var movement_bob_amplitude: float = 0.018
@export var movement_bob_frequency_hz: float = 2.4
@export var max_lean_radians: float = 0.12
@export var lean_response: float = 12.0
@export var movement_speed_reference: float = 4.0
@export var model_path: NodePath = NodePath("Model")

@onready var model: Node3D = get_node_or_null(model_path) as Node3D

var _time_seconds: float = 0.0
var _base_model_position: Vector3 = Vector3.ZERO
var _base_model_rotation: Vector3 = Vector3.ZERO
var _base_model_scale: Vector3 = Vector3.ONE
var _current_lean: Vector3 = Vector3.ZERO

func _ready() -> void:
	if model == null:
		return
	_base_model_position = model.position
	_base_model_rotation = model.rotation
	_base_model_scale = model.scale
	update_visual(0.0)

func _physics_process(delta: float) -> void:
	update_visual(delta)

func update_visual(delta: float) -> void:
	var safe_delta: float = maxf(delta, 0.0)
	_time_seconds += safe_delta
	_turn_to_direction(_parent_facing_direction(), safe_delta)
	_apply_procedural_motion(safe_delta)

func visual_forward_direction() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.000001:
		return Vector3(0.0, 0.0, -1.0)
	return forward.normalized()

func reset_procedural_motion() -> void:
	_time_seconds = 0.0
	_current_lean = Vector3.ZERO
	if model == null:
		return
	model.position = _base_model_position
	model.rotation = _base_model_rotation
	model.scale = _base_model_scale

func _turn_to_direction(direction: Vector3, delta: float) -> void:
	var flat_direction := _flatten_direction(direction)
	if flat_direction == Vector3.ZERO:
		return
	var target_yaw := atan2(-flat_direction.x, -flat_direction.z)
	var turn_weight := 1.0
	if turn_speed > 0.0:
		turn_weight = 1.0 - exp(-turn_speed * delta)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_weight)

func _apply_procedural_motion(delta: float) -> void:
	if model == null:
		return

	var move_amount := _movement_amount()
	var idle_bob := sin(_time_seconds * TAU * idle_bob_frequency_hz) * idle_bob_amplitude
	var movement_bob := sin(_time_seconds * TAU * movement_bob_frequency_hz) * movement_bob_amplitude * move_amount
	model.position = _base_model_position + Vector3(0.0, idle_bob + movement_bob, 0.0)

	var lean_weight := 1.0
	if lean_response > 0.0:
		lean_weight = 1.0 - exp(-lean_response * maxf(delta, 0.0))
	_current_lean = _current_lean.lerp(_target_lean(move_amount), lean_weight)
	model.rotation = _base_model_rotation + _current_lean
	model.scale = _base_model_scale

func _target_lean(move_amount: float) -> Vector3:
	if move_amount <= 0.0:
		return Vector3.ZERO
	var velocity := _parent_horizontal_velocity()
	if velocity == Vector3.ZERO:
		return Vector3.ZERO

	var local_velocity := global_transform.basis.inverse() * velocity.normalized()
	var lean_x := clampf(local_velocity.z, -1.0, 1.0) * max_lean_radians * move_amount
	var lean_z := clampf(-local_velocity.x, -1.0, 1.0) * max_lean_radians * move_amount
	return Vector3(lean_x, 0.0, lean_z)

func _movement_amount() -> float:
	var speed := _parent_horizontal_velocity().length()
	return clampf(speed / maxf(movement_speed_reference, 0.001), 0.0, 1.0)

func _parent_horizontal_velocity() -> Vector3:
	var parent_node := get_parent()
	if parent_node is CharacterBody3D:
		var body := parent_node as CharacterBody3D
		return Vector3(body.velocity.x, 0.0, body.velocity.z)
	return Vector3.ZERO

func _parent_facing_direction() -> Vector3:
	var parent_node := get_parent()
	if parent_node != null:
		var motor_value: Variant = parent_node.get("motor")
		if motor_value is Object:
			var facing_value: Variant = motor_value.get("facing_direction")
			if facing_value is Vector3:
				var facing_direction := _flatten_direction(facing_value)
				if facing_direction != Vector3.ZERO:
					return facing_direction

	var velocity_direction := _flatten_direction(_parent_horizontal_velocity())
	if velocity_direction != Vector3.ZERO:
		return velocity_direction
	return Vector3(0.0, 0.0, -1.0)

func _flatten_direction(direction: Vector3) -> Vector3:
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() > 1.0:
		return flat_direction.normalized()
	if flat_direction.length_squared() <= 0.000001:
		return Vector3.ZERO
	return flat_direction
