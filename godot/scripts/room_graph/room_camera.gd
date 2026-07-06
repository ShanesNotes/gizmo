class_name RoomCamera
extends Camera3D

const DEFAULT_OFFSET: Vector3 = Vector3(0.0, 12.0, 10.0)
const DEFAULT_FOLLOW_SPEED: float = 8.0

@export var target: Node3D
@export var offset: Vector3 = DEFAULT_OFFSET
@export var follow_speed: float = DEFAULT_FOLLOW_SPEED

var _clamp_center: Vector3 = Vector3.ZERO
var _clamp_half_extents: Vector2 = Vector2.ZERO

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

func _ready() -> void:
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
	return true

func desired_position_for(player_position: Vector3) -> Vector3:
	return target_position_for(player_position, _clamp_center, _clamp_half_extents, offset)

func update_follow(delta: float) -> void:
	if target == null:
		return

	var desired := desired_position_for(_current_target_position())
	global_position = follow_step(global_position, desired, follow_speed, delta)

func _process(delta: float) -> void:
	update_follow(delta)

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
