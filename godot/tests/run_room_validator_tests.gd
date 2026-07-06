extends SceneTree

# Headless tests for the room scene contract validator (HZ-005).
# Run with:
#   godot --headless --user-data-dir /tmp/grok-godot-userdata --path godot --script res://tests/run_room_validator_tests.gd

const RoomSceneValidator := preload("res://scripts/room_graph/room_scene_validator.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running room scene validator tests...")
	_test_valid_scene_with_single_exit_returns_empty()
	_test_valid_scene_with_branch_exits_returns_empty()
	_test_null_scene_reports_one_violation()
	_test_uninstantiable_scene_reports_one_violation()
	_test_missing_camera_anchor_reports_one_violation()
	_test_wrong_type_camera_anchor_reports_one_violation()
	_test_missing_spawn_marker_reports_one_violation()
	_test_missing_exit_door_reports_one_violation()
	_test_wrong_type_exit_door_reports_one_violation()
	_test_room_exit_a_without_b_reports_one_violation()
	_test_multiple_violations_each_produce_one_message()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL — %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks ⇒ validator failed to load/compile)" if _passed == 0 else ""]
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

func _pack_room(
	include_camera_anchor: bool = true,
	include_spawn_marker: bool = true,
	exit_doors: Array[String] = ["RoomExit"],
	camera_anchor_type: String = "Marker3D",
) -> PackedScene:
	var root := Node3D.new()
	root.name = "TestRoom"

	if include_camera_anchor:
		var anchor: Node3D
		if camera_anchor_type == "Marker3D":
			anchor = Marker3D.new()
		else:
			anchor = Node3D.new()
		anchor.name = "CameraAnchor"
		root.add_child(anchor)

	if include_spawn_marker:
		var spawn := Marker3D.new()
		spawn.name = "SpawnMarker"
		root.add_child(spawn)

	for door_name in exit_doors:
		var exit: Node3D
		if door_name == "WrongTypeExit":
			exit = Node3D.new()
			exit.name = "RoomExit"
		else:
			exit = Area3D.new()
			exit.name = door_name
		root.add_child(exit)

	for child in root.get_children():
		child.owner = root

	var packed := PackedScene.new()
	var pack_err := packed.pack(root)
	if pack_err != OK:
		push_error("Failed to pack throwaway test room scene: %s" % error_string(pack_err))
	return packed

func _assert_violations(desc: String, scene: PackedScene, expected: Array[String]) -> void:
	var actual := RoomSceneValidator.validate(scene)
	_check_eq("%s: violation count" % desc, actual.size(), expected.size())
	for message in expected:
		_check("%s: contains '%s'" % [desc, message], actual.has(message))

func _test_valid_scene_with_single_exit_returns_empty() -> void:
	_assert_violations("valid single-exit room", _pack_room(), [])

func _test_valid_scene_with_branch_exits_returns_empty() -> void:
	_assert_violations(
		"valid branch-exit room",
		_pack_room(true, true, ["RoomExitA", "RoomExitB"]),
		[],
	)

func _test_null_scene_reports_one_violation() -> void:
	_assert_violations("null scene", null, ["Room scene is null."])

func _test_uninstantiable_scene_reports_one_violation() -> void:
	_assert_violations(
		"uninstantiable scene",
		PackedScene.new(),
		["Room scene failed to instantiate."],
	)

func _test_missing_camera_anchor_reports_one_violation() -> void:
	_assert_violations(
		"missing CameraAnchor",
		_pack_room(false, true, ["RoomExit"]),
		["Room scene is missing a Marker3D named 'CameraAnchor'."],
	)

func _test_wrong_type_camera_anchor_reports_one_violation() -> void:
	_assert_violations(
		"wrong-type CameraAnchor",
		_pack_room(true, true, ["RoomExit"], "Node3D"),
		["Room scene is missing a Marker3D named 'CameraAnchor'."],
	)

func _test_missing_spawn_marker_reports_one_violation() -> void:
	_assert_violations(
		"missing SpawnMarker",
		_pack_room(true, false, ["RoomExit"]),
		["Room scene is missing a Marker3D named 'SpawnMarker'."],
	)

func _test_missing_exit_door_reports_one_violation() -> void:
	_assert_violations(
		"missing exit door",
		_pack_room(true, true, []),
		[
			"Room scene is missing an Area3D exit door named 'RoomExit', 'RoomExitA', or 'RoomExitB'.",
		],
	)

func _test_wrong_type_exit_door_reports_one_violation() -> void:
	_assert_violations(
		"wrong-type exit door",
		_pack_room(true, true, ["WrongTypeExit"]),
		[
			"Room scene is missing an Area3D exit door named 'RoomExit', 'RoomExitA', or 'RoomExitB'.",
		],
	)

func _test_room_exit_a_without_b_reports_one_violation() -> void:
	_assert_violations(
		"RoomExitA without RoomExitB",
		_pack_room(true, true, ["RoomExitA"]),
		["Room scene has 'RoomExitA' but is missing the paired 'RoomExitB' Area3D."],
	)

func _test_multiple_violations_each_produce_one_message() -> void:
	_assert_violations(
		"all contract violations",
		_pack_room(false, false, []),
		[
			"Room scene is missing a Marker3D named 'CameraAnchor'.",
			"Room scene is missing a Marker3D named 'SpawnMarker'.",
			"Room scene is missing an Area3D exit door named 'RoomExit', 'RoomExitA', or 'RoomExitB'.",
		],
	)