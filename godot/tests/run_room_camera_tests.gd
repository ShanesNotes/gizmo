extends SceneTree

# Headless tests for HZ-003 RoomCamera.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_room_camera_tests.gd

const RoomCameraScript := preload("res://scripts/room_graph/room_camera.gd")

class BoundsAnchor:
	extends Marker3D
	var camera_half_extent_x: float = 0.0
	var camera_half_extent_z: float = 0.0

class CameraBoundsNode:
	extends Node3D
	var half_extents: Vector2 = Vector2.ZERO

var _passed := 0
var _failed := 0

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("Running RoomCamera tests...")
	_test_clamp_target_math_inside_edges_and_corners()
	_test_zero_half_extents_degenerate_to_static_target()
	_test_follow_step_matches_smoothing_core()
	_test_ready_disables_physics_interpolation()
	_test_enter_room_reads_anchor_bounds_and_hard_cuts()
	_test_enter_room_reads_camera_bounds_child()
	_test_enter_room_zero_extents_stays_static_after_player_moves()
	_test_soft_follow_converges_between_room_cuts()
	_test_missing_camera_anchor_uses_safe_fallback()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => RoomCamera failed to load/compile)" if _passed == 0 else ""]
		)
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s" % desc)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	_check("%s (got %s, expected %s)" % [desc, actual, expected], actual == expected)

func _check_vec3(desc: String, actual: Vector3, expected: Vector3, margin: float = 0.0001) -> void:
	_check("%s (got %s, expected %s)" % [desc, actual, expected], actual.distance_to(expected) <= margin)

func _test_clamp_target_math_inside_edges_and_corners() -> void:
	var center := Vector3(10.0, 3.0, 20.0)
	var half_extents := Vector2(5.0, 2.0)
	var offset := Vector3(0.0, 12.0, 10.0)

	_check_vec3(
		"inside player XZ is not clamped",
		RoomCameraScript.target_position_for(Vector3(12.0, 99.0, 21.0), center, half_extents, offset),
		Vector3(12.0, 15.0, 31.0),
	)
	_check_vec3(
		"edge player XZ is preserved",
		RoomCameraScript.target_position_for(Vector3(15.0, 0.0, 18.0), center, half_extents, offset),
		Vector3(15.0, 15.0, 28.0),
	)
	_check_vec3(
		"positive outside corner clamps to max XZ",
		RoomCameraScript.target_position_for(Vector3(99.0, 0.0, 99.0), center, half_extents, offset),
		Vector3(15.0, 15.0, 32.0),
	)
	_check_vec3(
		"negative outside corner clamps to min XZ",
		RoomCameraScript.target_position_for(Vector3(-99.0, 0.0, -99.0), center, half_extents, offset),
		Vector3(5.0, 15.0, 28.0),
	)

func _test_zero_half_extents_degenerate_to_static_target() -> void:
	_check_vec3(
		"zero half-extents pin target to CameraAnchor center",
		RoomCameraScript.target_position_for(
			Vector3(99.0, 0.0, -99.0),
			Vector3(4.0, 1.0, -6.0),
			Vector2.ZERO,
			RoomCameraScript.DEFAULT_OFFSET,
		),
		Vector3(4.0, 13.0, 4.0),
	)

func _test_follow_step_matches_smoothing_core() -> void:
	var current := Vector3.ZERO
	var desired := Vector3(10.0, 0.0, 0.0)
	var stepped: Vector3 = RoomCameraScript.follow_step(current, desired, 8.0, 0.25)
	var expected_weight := 1.0 - exp(-8.0 * 0.25)

	_check("follow_step moves toward desired", stepped.x > 0.0 and stepped.x < desired.x)
	_check_vec3("follow_step uses exponential weight", stepped, current.lerp(desired, expected_weight))
	_check_vec3("zero delta keeps current position", RoomCameraScript.follow_step(current, desired, 8.0, 0.0), current)

func _test_ready_disables_physics_interpolation() -> void:
	var player := _new_player(Vector3.ZERO)
	var camera = _new_camera(player)

	_check_eq(
		"RoomCamera opts out of physics interpolation",
		camera.physics_interpolation_mode,
		Node.PHYSICS_INTERPOLATION_MODE_OFF,
	)

	_cleanup(camera)
	_cleanup(player)

func _test_enter_room_reads_anchor_bounds_and_hard_cuts() -> void:
	var room := _new_room_with_anchor(Vector3(10.0, 0.0, -4.0), Vector2(2.0, 3.0))
	var player := _new_player(Vector3(99.0, 0.0, -99.0))
	var camera = _new_camera(player)

	_check("enter_room accepts a Marker3D CameraAnchor", camera.enter_room(room))
	_check_vec3(
		"enter_room hard-cuts exactly to clamped target",
		camera.global_position,
		Vector3(12.0, 12.0, 3.0),
	)

	_cleanup(camera)
	_cleanup(player)
	_cleanup(room)

func _test_enter_room_reads_camera_bounds_child() -> void:
	var room := Node3D.new()
	root.add_child(room)
	var anchor := Marker3D.new()
	anchor.name = "CameraAnchor"
	room.add_child(anchor)
	anchor.global_position = Vector3(-3.0, 0.5, 8.0)
	var bounds := CameraBoundsNode.new()
	bounds.name = "CameraBounds"
	bounds.half_extents = Vector2(1.5, 4.0)
	anchor.add_child(bounds)

	var player := _new_player(Vector3(-20.0, 0.0, 20.0))
	var camera = _new_camera(player)

	_check("enter_room reads a CameraBounds child", camera.enter_room(room))
	_check_vec3(
		"CameraBounds child clamps XZ around the anchor",
		camera.global_position,
		Vector3(-4.5, 12.5, 22.0),
	)

	_cleanup(camera)
	_cleanup(player)
	_cleanup(room)

func _test_enter_room_zero_extents_stays_static_after_player_moves() -> void:
	var room := _new_room_with_anchor(Vector3(5.0, 0.0, 6.0), Vector2.ZERO)
	var player := _new_player(Vector3(99.0, 0.0, 99.0))
	var camera = _new_camera(player)

	camera.enter_room(room)
	var static_position: Vector3 = camera.global_position
	player.global_position = Vector3(-99.0, 0.0, -99.0)
	camera.update_follow(0.5)

	_check_vec3("zero half-extents snap to static room frame", static_position, Vector3(5.0, 12.0, 16.0))
	_check_vec3("zero half-extents stay static after player moves", camera.global_position, static_position)

	_cleanup(camera)
	_cleanup(player)
	_cleanup(room)

func _test_soft_follow_converges_between_room_cuts() -> void:
	var room := _new_room_with_anchor(Vector3.ZERO, Vector2(10.0, 10.0))
	var player := _new_player(Vector3.ZERO)
	var camera = _new_camera(player)
	camera.enter_room(room)
	var before: Vector3 = camera.global_position

	player.global_position = Vector3(4.0, 0.0, 0.0)
	var desired: Vector3 = camera.desired_position_for(player.global_position)
	var distance_before: float = before.distance_to(desired)
	camera.update_follow(0.1)
	var distance_after: float = camera.global_position.distance_to(desired)

	_check("soft follow moves after the player target moves", camera.global_position != before)
	_check("soft follow converges toward the new target", distance_after < distance_before)
	_check("soft follow does not hard-snap between room cuts", distance_after > 0.001)

	_cleanup(camera)
	_cleanup(player)
	_cleanup(room)

func _test_missing_camera_anchor_uses_safe_fallback() -> void:
	var room := Node3D.new()
	root.add_child(room)
	var player := _new_player(Vector3(3.0, 0.0, 4.0))
	var camera = _new_camera(player)

	_check_eq("enter_room returns false without CameraAnchor", camera.enter_room(room), false)
	_check_vec3(
		"missing CameraAnchor falls back to the current player frame",
		camera.global_position,
		Vector3(3.0, 12.0, 14.0),
	)

	_cleanup(camera)
	_cleanup(player)
	_cleanup(room)

func _new_camera(player: Node3D):
	var camera = RoomCameraScript.new()
	camera.target = player
	root.add_child(camera)
	return camera

func _new_player(position: Vector3) -> Node3D:
	var player := Node3D.new()
	player.name = "Player"
	root.add_child(player)
	player.global_position = position
	return player

func _new_room_with_anchor(anchor_position: Vector3, half_extents: Vector2) -> Node3D:
	var room := Node3D.new()
	room.name = "Room"
	root.add_child(room)
	var anchor := BoundsAnchor.new()
	anchor.name = "CameraAnchor"
	anchor.camera_half_extent_x = half_extents.x
	anchor.camera_half_extent_z = half_extents.y
	room.add_child(anchor)
	anchor.global_position = anchor_position
	return room

func _cleanup(node: Node) -> void:
	node.queue_free()
