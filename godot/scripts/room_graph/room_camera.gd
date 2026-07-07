class_name RoomCamera
extends Camera3D

const DEFAULT_OFFSET: Vector3 = Vector3(0.0, 12.0, 10.0)
const DEFAULT_FOLLOW_SPEED: float = 8.0
const SETTLE_DURATION: float = 0.6
const SETTLE_PULLBACK: float = 0.15
const PUSH_IN_STRENGTH: float = 0.15
const PUSH_RELEASE_SECONDS: float = 0.4

@export var target: Node3D
@export var offset: Vector3 = DEFAULT_OFFSET
@export var follow_speed: float = DEFAULT_FOLLOW_SPEED

# Presentation-beat state (HZ room-entry settle + boss push-in). Like shake,
# these are pure _process overlays: clamp/follow state and the enter_room hard
# cut are untouched, so the follow tests see identical motion.
var settle_time_remaining: float = 0.0
var push_duration: float = 0.0
var push_elapsed: float = 0.0

var _clamp_center: Vector3 = Vector3.ZERO
var _clamp_half_extents: Vector2 = Vector2.ZERO
var _shake_time_remaining: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0
var _push_releasing: bool = false

static func clamped_room_point(
	player_position: Vector3,
	clamp_center: Vector3,
	clamp_half_extents: Vector2,
) -> Vector3:
	var extents := Vector2(absf(clamp_half_extents.x), absf(clamp_half_extents.y))
	return Vector3(
		clampf(player_position.x, clamp_center.x - extents.x, clamp_center.x + extents.x),
		clamp_center.y,
		clampf(player_position.z, clamp_center.z - extents.y, clamp_center.z + extents.y),
	)

static func target_position_for(
	player_position: Vector3,
	clamp_center: Vector3,
	clamp_half_extents: Vector2,
	camera_offset: Vector3 = DEFAULT_OFFSET,
) -> Vector3:
	return clamped_room_point(player_position, clamp_center, clamp_half_extents) + camera_offset

static func follow_step(
	current_position: Vector3,
	desired_position: Vector3,
	speed: float,
	delta: float,
) -> Vector3:
	var weight := 1.0 - exp(-maxf(speed, 0.0) * maxf(delta, 0.0))
	return current_position.lerp(desired_position, weight)

## Room-entry settle: starts pulled back along the camera offset and eases to
## zero as time_remaining runs out (ease-out cubic — lands gently).
static func settle_overlay(
	camera_offset: Vector3,
	time_remaining: float,
	duration: float = SETTLE_DURATION,
	pullback: float = SETTLE_PULLBACK,
) -> Vector3:
	if time_remaining <= 0.0 or duration <= 0.0:
		return Vector3.ZERO
	var fraction := clampf(time_remaining / duration, 0.0, 1.0)
	return camera_offset * (pullback * fraction * fraction * fraction)

## Boss-intro push-in: eases from zero toward the target (negative offset)
## over duration, clamping at full strength (smoothstep ease in-out).
static func push_overlay(
	camera_offset: Vector3,
	elapsed: float,
	duration: float,
	strength: float = PUSH_IN_STRENGTH,
) -> Vector3:
	if duration <= 0.0 or elapsed <= 0.0:
		return Vector3.ZERO
	var t := clampf(elapsed / duration, 0.0, 1.0)
	return camera_offset * (-strength * t * t * (3.0 - 2.0 * t))

func _ready() -> void:
	# Inert while the follow runs in _process (engine interpolation only smooths
	# _physics_process transforms); kept so a future move to _physics_process
	# doesn't re-smooth the enter_room hard cut.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func enter_room(room_root: Node3D) -> bool:
	var anchor := _find_camera_anchor(room_root)
	if anchor == null:
		push_error("RoomCamera: room is missing a Marker3D named 'CameraAnchor'.")
		_apply_fallback_bounds(room_root)
		global_position = desired_position_for(_current_target_position())
		return false

	_clamp_center = anchor.global_position
	_clamp_half_extents = _read_room_half_extents(anchor)
	global_position = desired_position_for(_current_target_position())
	settle_time_remaining = SETTLE_DURATION
	return true

func desired_position_for(player_position: Vector3) -> Vector3:
	return target_position_for(player_position, _clamp_center, _clamp_half_extents, offset)

func update_follow(delta: float) -> void:
	if target == null:
		return

	var desired := desired_position_for(_current_target_position())
	global_position = follow_step(global_position, desired, follow_speed, delta)

## Cosmetic impact shake (HZ-084 punch-up): a brief decaying positional jitter
## layered on top of the follow. Never touches clamp/follow state; a zero
## strength or duration is a no-op, so the follow tests see identical motion.
func shake(strength: float = 0.12, duration: float = 0.1) -> void:
	if strength <= 0.0 or duration <= 0.0:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_duration = maxf(_shake_duration, duration)
	_shake_time_remaining = maxf(_shake_time_remaining, duration)

## Cosmetic boss-intro push-in: eases the camera toward the target over
## duration seconds and holds until release_push() eases it back out.
func push_in(duration: float = 1.0) -> void:
	if duration <= 0.0:
		return
	push_duration = duration
	push_elapsed = 0.0
	_push_releasing = false

func release_push() -> void:
	if push_duration > 0.0:
		_push_releasing = true

func _process(delta: float) -> void:
	update_follow(delta)
	_apply_shake(delta)
	_apply_presentation_overlays(delta)

func _apply_presentation_overlays(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if settle_time_remaining > 0.0:
		settle_time_remaining = maxf(0.0, settle_time_remaining - step)
		global_position += settle_overlay(offset, settle_time_remaining)
	if push_duration <= 0.0:
		return
	if _push_releasing:
		push_elapsed = maxf(0.0, push_elapsed - step * (push_duration / PUSH_RELEASE_SECONDS))
		if push_elapsed <= 0.0:
			push_duration = 0.0
			_push_releasing = false
			return
	else:
		push_elapsed = minf(push_duration, push_elapsed + step)
	global_position += push_overlay(offset, push_elapsed, push_duration)

func _apply_shake(delta: float) -> void:
	if _shake_time_remaining <= 0.0:
		return
	_shake_time_remaining = maxf(0.0, _shake_time_remaining - maxf(delta, 0.0))
	var falloff := _shake_time_remaining / maxf(_shake_duration, 0.001)
	var amplitude := _shake_strength * falloff
	global_position += Vector3(
		randf_range(-amplitude, amplitude),
		randf_range(-amplitude, amplitude) * 0.5,
		randf_range(-amplitude, amplitude),
	)
	if _shake_time_remaining <= 0.0:
		_shake_strength = 0.0
		_shake_duration = 0.0

func _find_camera_anchor(room_root: Node3D) -> Marker3D:
	if room_root == null:
		return null
	var anchor := room_root.find_child("CameraAnchor", true, false)
	if anchor is Marker3D:
		return anchor
	return null

func _apply_fallback_bounds(room_root: Node3D) -> void:
	if target != null:
		_clamp_center = _current_target_position()
	elif room_root != null:
		_clamp_center = room_root.global_position
	else:
		_clamp_center = Vector3.ZERO
	_clamp_half_extents = Vector2.ZERO

func _current_target_position() -> Vector3:
	if target != null:
		return target.get_global_transform_interpolated().origin
	return _clamp_center

static func _read_room_half_extents(anchor: Marker3D) -> Vector2:
	var bounds: Node = anchor.find_child("CameraBounds", true, false)
	if bounds != null:
		var bounds_extents: Variant = _read_half_extents_from_object(bounds)
		if bounds_extents is Vector2:
			return Vector2(bounds_extents.x, bounds_extents.y)

	var anchor_extents: Variant = _read_half_extents_from_object(anchor)
	if anchor_extents is Vector2:
		return Vector2(anchor_extents.x, anchor_extents.y)
	return Vector2.ZERO

static func _read_half_extents_from_object(source: Object) -> Variant:
	var vector_value: Variant = _get_property_or_meta_value(
		source,
		[
			"camera_half_extents",
			"bounds_half_extents",
			"half_extents",
			"camera_bounds_half_extents",
		],
	)
	if vector_value is Vector2:
		return Vector2(absf(vector_value.x), absf(vector_value.y))
	if vector_value is Vector3:
		return Vector2(absf(vector_value.x), absf(vector_value.z))

	var x_value: Variant = _get_property_or_meta_value(
		source,
		[
			"camera_half_extent_x",
			"bounds_half_extent_x",
			"half_extent_x",
			"half_extents_x",
			"x_half_extent",
		],
	)
	var z_value: Variant = _get_property_or_meta_value(
		source,
		[
			"camera_half_extent_z",
			"bounds_half_extent_z",
			"half_extent_z",
			"half_extents_z",
			"z_half_extent",
		],
	)
	if (x_value is float or x_value is int) and (z_value is float or z_value is int):
		return Vector2(absf(float(x_value)), absf(float(z_value)))

	return null

static func _get_property_or_meta_value(source: Object, names: Array[String]) -> Variant:
	if source == null:
		return null
	for property_name in names:
		if _has_property(source, property_name):
			return source.get(property_name)
		if source is Node:
			var node := source as Node
			if node.has_meta(property_name):
				return node.get_meta(property_name)
	return null

static func _has_property(source: Object, property_name: String) -> bool:
	for property in source.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false
