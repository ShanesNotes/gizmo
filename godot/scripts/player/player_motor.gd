class_name PlayerMotor
extends RefCounted

const DEFAULT_FACING_DIRECTION: Vector3 = Vector3(0.0, 0.0, -1.0)

var move_speed: float = 4.0
var acceleration: float = 32.0
var friction: float = 40.0
var dash_speed: float = 14.0
var dash_duration: float = 0.25
var facing_direction: Vector3 = DEFAULT_FACING_DIRECTION

var _dash_direction: Vector3 = Vector3.ZERO
var _dash_speed: float = 0.0
var _dash_time_remaining: float = 0.0

func step(current_velocity: Vector3, input_direction: Vector3, delta: float) -> Vector3:
	var safe_delta: float = maxf(delta, 0.0)
	var desired_direction: Vector3 = flatten_direction(input_direction)
	if desired_direction != Vector3.ZERO:
		facing_direction = desired_direction

	var horizontal_velocity := Vector3(current_velocity.x, 0.0, current_velocity.z)
	if is_dashing():
		horizontal_velocity = _dash_direction * _dash_speed
		_dash_time_remaining = maxf(0.0, _dash_time_remaining - safe_delta)
		if is_dashing():
			return horizontal_velocity

	var target_velocity: Vector3 = desired_direction * move_speed
	var change_rate: float = acceleration if desired_direction != Vector3.ZERO else friction
	return horizontal_velocity.move_toward(target_velocity, change_rate * safe_delta)

func begin_dash(direction: Vector3 = Vector3.ZERO, speed: float = -1.0, duration: float = -1.0) -> void:
	var chosen_direction: Vector3 = flatten_direction(direction)
	if chosen_direction == Vector3.ZERO:
		chosen_direction = facing_direction
	if chosen_direction == Vector3.ZERO:
		chosen_direction = DEFAULT_FACING_DIRECTION

	var burst_speed := speed if speed > 0.0 else dash_speed
	var burst_duration := duration if duration > 0.0 else dash_duration
	_dash_direction = chosen_direction
	_dash_speed = burst_speed
	_dash_time_remaining = burst_duration

func clear_dash() -> void:
	_dash_direction = Vector3.ZERO
	_dash_speed = 0.0
	_dash_time_remaining = 0.0

func is_dashing() -> bool:
	return _dash_time_remaining > 0.0

func dash_direction() -> Vector3:
	return _dash_direction

func dash_time_remaining() -> float:
	return _dash_time_remaining

static func input_vector_to_world_direction(input_vector: Vector2) -> Vector3:
	return flatten_direction(Vector3(input_vector.x, 0.0, input_vector.y))

static func flatten_direction(direction: Vector3) -> Vector3:
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() > 1.0:
		return flat_direction.normalized()
	if flat_direction.length_squared() <= 0.000001:
		return Vector3.ZERO
	return flat_direction
