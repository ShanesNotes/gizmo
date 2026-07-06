extends SceneTree

# Headless tests for HZ-030 room doors.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_room_door_tests.gd

const RoomDoorScript := preload("res://scripts/room_graph/room_door.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const GizmoPlayerScene := preload("res://scenes/gizmo_player.tscn")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running room door tests...")
	await _test_sealed_door_ignores_player_body()
	await _test_open_door_emits_once_with_bound_connection()
	await _test_reentry_while_open_does_not_double_fire()
	await _test_seal_reopen_cycle_rearms()
	await _test_non_player_bodies_are_ignored()
	await _test_gizmo_player_class_without_player_group_is_ignored()
	await _test_open_door_detects_player_already_overlapping_in_physics()
	await _test_open_door_polls_existing_overlap_without_body_entered_signal()
	await _test_open_for_shows_telegraph_for_all_reward_types()
	await _test_seal_hides_telegraph_label()
	await _test_reopen_updates_telegraph_text_and_color()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => RoomDoor failed to load/compile)" if _passed == 0 else ""]
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

func _new_door():
	var door = RoomDoorScript.new()
	door.name = "RoomExitA"
	root.add_child(door)
	await process_frame
	return door

func _new_physics_door():
	var door = RoomDoorScript.new()
	door.name = "RoomExitA"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	shape.shape = box
	door.add_child(shape)
	root.add_child(door)
	await process_frame
	return door

func _new_player_body() -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "PlayerBody"
	body.add_to_group(&"player")
	root.add_child(body)
	return body

func _new_physics_player_body() -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.name = "PlayerBody"
	body.add_to_group(&"player")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.1
	shape.shape = capsule
	body.add_child(shape)
	root.add_child(body)
	return body

func _new_ungrouped_gizmo_player():
	var player = GizmoPlayerScene.instantiate()
	player.remove_from_group(&"player")
	root.add_child(player)
	await process_frame
	player.remove_from_group(&"player")
	return player

func _make_connection(door_name_value: String = "RoomExitA") -> RoomConnection:
	var connection := RoomConnection.new()
	connection.from_room_id = "room_00"
	connection.to_room_id = "room_01"
	connection.door_name = door_name_value
	return connection

func _cleanup(nodes: Array[Node]) -> void:
	for node in nodes:
		if node != null:
			node.queue_free()
	await process_frame

func _test_sealed_door_ignores_player_body() -> void:
	var door: Variant = await _new_door()
	var player := _new_player_body()
	var requested_connections: Array[RoomConnection] = []
	door.exit_requested.connect(func(connection: RoomConnection) -> void:
		requested_connections.append(connection)
	)

	_check_eq("door starts SEALED", door.state, RoomDoorScript.State.SEALED)
	_check_eq("sealed door monitoring starts off", door.monitoring, false)

	door.emit_signal(&"body_entered", player)

	_check_eq("sealed door ignores player body", requested_connections.size(), 0)
	await _cleanup([door, player])

func _test_open_door_emits_once_with_bound_connection() -> void:
	var door: Variant = await _new_door()
	var player := _new_player_body()
	var connection := _make_connection("RoomExitA")
	var requested_connections: Array[RoomConnection] = []
	door.exit_requested.connect(func(requested_connection: RoomConnection) -> void:
		requested_connections.append(requested_connection)
	)

	door.open_for(connection, RoomNode.RewardType.HAMMER)

	_check_eq("open_for moves door to OPEN", door.state, RoomDoorScript.State.OPEN)
	_check_eq("open_for enables monitoring", door.monitoring, true)
	_check("open_for stores the bound connection", door.bound_connection == connection)
	_check_eq("open_for stores telegraph reward_type", door.reward_type, RoomNode.RewardType.HAMMER)
	_check_eq("open_for stores telegraph door_name", door.door_name, "RoomExitA")
	_check_eq("telegraph_data exposes reward_type", door.telegraph_data()[&"reward_type"], RoomNode.RewardType.HAMMER)
	_check_eq("telegraph_data exposes door_name", door.telegraph_data()[&"door_name"], "RoomExitA")

	door.emit_signal(&"body_entered", player)

	_check_eq("open door emits one exit request", requested_connections.size(), 1)
	_check("exit request payload is the bound connection", requested_connections[0] == connection)
	await _cleanup([door, player])

func _test_reentry_while_open_does_not_double_fire() -> void:
	var door: Variant = await _new_door()
	var player := _new_player_body()
	var connection := _make_connection("RoomExit")
	var requested_connections: Array[RoomConnection] = []
	door.exit_requested.connect(func(requested_connection: RoomConnection) -> void:
		requested_connections.append(requested_connection)
	)
	door.open_for(connection, RoomNode.RewardType.SCRAP)

	door.emit_signal(&"body_entered", player)
	door.emit_signal(&"body_entered", player)
	door.emit_signal(&"body_entered", player)

	_check_eq("re-entry while still OPEN emits exactly once", requested_connections.size(), 1)
	_check("one-shot payload remains the bound connection", requested_connections[0] == connection)
	await _cleanup([door, player])

func _test_seal_reopen_cycle_rearms() -> void:
	var door: Variant = await _new_door()
	var player := _new_player_body()
	var first_connection := _make_connection("RoomExitA")
	var second_connection := _make_connection("RoomExitB")
	second_connection.to_room_id = "room_02"
	var requested_connections: Array[RoomConnection] = []
	door.exit_requested.connect(func(requested_connection: RoomConnection) -> void:
		requested_connections.append(requested_connection)
	)

	door.open_for(first_connection, RoomNode.RewardType.SPARKS)
	door.emit_signal(&"body_entered", player)
	door.seal()
	door.emit_signal(&"body_entered", player)

	_check_eq("seal moves door back to SEALED", door.state, RoomDoorScript.State.SEALED)
	_check_eq("seal disables monitoring", door.monitoring, false)
	_check("seal clears bound connection", door.bound_connection == null)
	_check_eq("sealed body entry does not re-fire", requested_connections.size(), 1)

	door.open_for(second_connection, RoomNode.RewardType.HEAL)
	door.emit_signal(&"body_entered", player)

	_check_eq("reopened door re-arms exit request", requested_connections.size(), 2)
	_check("first request used first connection", requested_connections[0] == first_connection)
	_check("second request used reopened connection", requested_connections[1] == second_connection)
	_check_eq("reopen replaces telegraph reward_type", door.reward_type, RoomNode.RewardType.HEAL)
	_check_eq("reopen replaces telegraph door_name", door.door_name, "RoomExitB")
	await _cleanup([door, player])

func _test_non_player_bodies_are_ignored() -> void:
	var door: Variant = await _new_door()
	var player := _new_player_body()
	var non_player_body := CharacterBody3D.new()
	var scenery := Node3D.new()
	root.add_child(non_player_body)
	root.add_child(scenery)
	var requested_connections: Array[RoomConnection] = []
	door.exit_requested.connect(func(requested_connection: RoomConnection) -> void:
		requested_connections.append(requested_connection)
	)
	door.open_for(_make_connection("RoomExitA"), RoomNode.RewardType.SHOP)

	door.emit_signal(&"body_entered", non_player_body)
	door.emit_signal(&"body_entered", scenery)

	_check_eq("non-player overlaps do not request exits", requested_connections.size(), 0)

	door.emit_signal(&"body_entered", player)

	_check_eq("player body still requests the exit after ignored overlaps", requested_connections.size(), 1)
	await _cleanup([door, player, non_player_body, scenery])

func _test_gizmo_player_class_without_player_group_is_ignored() -> void:
	var door: Variant = await _new_door()
	var player = await _new_ungrouped_gizmo_player()
	var requested_connections: Array[RoomConnection] = []
	door.exit_requested.connect(func(requested_connection: RoomConnection) -> void:
		requested_connections.append(requested_connection)
	)
	door.open_for(_make_connection("RoomExitA"), RoomNode.RewardType.BOON)

	door.emit_signal(&"body_entered", player)
	_check_eq("GizmoPlayer class alone does not bypass the player group", requested_connections.size(), 0)

	player.add_to_group(&"player")
	door.emit_signal(&"body_entered", player)
	_check_eq("GizmoPlayer in the player group requests the exit", requested_connections.size(), 1)
	await _cleanup([door, player])

func _test_open_door_detects_player_already_overlapping_in_physics() -> void:
	var door: Variant = await _new_physics_door()
	var player := _new_physics_player_body()
	var connection := _make_connection("RoomExitA")
	var requested_connections: Array[RoomConnection] = []
	door.exit_requested.connect(func(requested_connection: RoomConnection) -> void:
		requested_connections.append(requested_connection)
	)

	await physics_frame
	door.open_for(connection, RoomNode.RewardType.BOON)
	await physics_frame

	_check_eq("open_for catches an already-overlapping player exactly once", requested_connections.size(), 1)
	if requested_connections.size() == 1:
		_check("already-overlap exit request payload is the bound connection", requested_connections[0] == connection)

	await physics_frame
	_check_eq("already-overlap polling stays single-shot across later physics frames", requested_connections.size(), 1)
	await _cleanup([door, player])

func _test_open_door_polls_existing_overlap_without_body_entered_signal() -> void:
	var door: Variant = await _new_physics_door()
	var player := _new_physics_player_body()
	var connection := _make_connection("RoomExitA")
	var requested_connections: Array[RoomConnection] = []
	var body_entered_handler := Callable(door, "_on_body_entered")
	if door.body_entered.is_connected(body_entered_handler):
		door.body_entered.disconnect(body_entered_handler)
	door.exit_requested.connect(func(requested_connection: RoomConnection) -> void:
		requested_connections.append(requested_connection)
	)

	await physics_frame
	door.open_for(connection, RoomNode.RewardType.BOON)
	await physics_frame
	await physics_frame

	_check_eq("explicit overlap poll catches already-overlapping player", requested_connections.size(), 1)
	if requested_connections.size() == 1:
		_check("explicit overlap poll uses the bound connection", requested_connections[0] == connection)
	await physics_frame
	_check_eq("explicit overlap poll remains single-shot", requested_connections.size(), 1)
	await _cleanup([door, player])

const PINNED_TELEGRAPH_TEXT := {
	RoomNode.RewardType.BOON: "BOON",
	RoomNode.RewardType.SCRAP: "SCRAP",
	RoomNode.RewardType.SPARKS: "SPARKS",
	RoomNode.RewardType.HAMMER: "HAMMER",
	RoomNode.RewardType.HEAL: "HEAL",
	RoomNode.RewardType.SHOP: "SHOP",
}

const PINNED_TELEGRAPH_COLORS := {
	RoomNode.RewardType.BOON: Color(1.0, 0.843, 0.0),
	RoomNode.RewardType.SCRAP: Color(0.804, 0.498, 0.196),
	RoomNode.RewardType.SPARKS: Color(0.259, 0.522, 0.957),
	RoomNode.RewardType.HAMMER: Color(1.0, 0.549, 0.0),
	RoomNode.RewardType.HEAL: Color(0.298, 0.686, 0.314),
	RoomNode.RewardType.SHOP: Color(0.612, 0.153, 0.690),
}

func _telegraph_label(door: Variant) -> Label3D:
	return door.get_node_or_null(NodePath(RoomDoorScript.TELEGRAPH_LABEL_NAME)) as Label3D

func _test_open_for_shows_telegraph_for_all_reward_types() -> void:
	for reward_type in PINNED_TELEGRAPH_TEXT.keys():
		var door: Variant = await _new_door()
		var connection := _make_connection("RoomExitA")
		door.open_for(connection, reward_type)
		await process_frame

		var label := _telegraph_label(door)
		_check(
			"open_for creates telegraph label for %s" % PINNED_TELEGRAPH_TEXT[reward_type],
			label != null
		)
		if label == null:
			await _cleanup([door])
			continue

		_check_eq(
			"%s telegraph text" % PINNED_TELEGRAPH_TEXT[reward_type],
			label.text,
			PINNED_TELEGRAPH_TEXT[reward_type]
		)
		_check(
			"%s telegraph color" % PINNED_TELEGRAPH_TEXT[reward_type],
			label.modulate.is_equal_approx(PINNED_TELEGRAPH_COLORS[reward_type])
		)
		_check(
			"%s telegraph billboard enabled" % PINNED_TELEGRAPH_TEXT[reward_type],
			label.billboard == BaseMaterial3D.BILLBOARD_ENABLED
		)
		_check(
			"%s telegraph visible when OPEN" % PINNED_TELEGRAPH_TEXT[reward_type],
			label.visible
		)
		await _cleanup([door])

func _test_seal_hides_telegraph_label() -> void:
	var door: Variant = await _new_door()
	door.open_for(_make_connection("RoomExitA"), RoomNode.RewardType.BOON)
	await process_frame

	var label := _telegraph_label(door)
	_check("open door exposes telegraph label before seal", label != null)
	if label != null:
		_check("telegraph visible while OPEN", label.visible)

	door.seal()
	await process_frame

	label = _telegraph_label(door)
	_check("telegraph label still exists after seal", label != null)
	if label != null:
		_check("seal hides telegraph label", not label.visible)
	await _cleanup([door])

func _test_reopen_updates_telegraph_text_and_color() -> void:
	var door: Variant = await _new_door()
	door.open_for(_make_connection("RoomExitA"), RoomNode.RewardType.SPARKS)
	await process_frame

	var label := _telegraph_label(door)
	_check_eq("first open telegraph text", label.text if label != null else "", "SPARKS")
	if label != null:
		_check("first open telegraph color", label.modulate.is_equal_approx(PINNED_TELEGRAPH_COLORS[RoomNode.RewardType.SPARKS]))

	door.seal()
	door.open_for(_make_connection("RoomExitB"), RoomNode.RewardType.HEAL)
	await process_frame

	label = _telegraph_label(door)
	_check_eq("reopen replaces telegraph text", label.text if label != null else "", "HEAL")
	if label != null:
		_check("reopen replaces telegraph color", label.modulate.is_equal_approx(PINNED_TELEGRAPH_COLORS[RoomNode.RewardType.HEAL]))
		_check("reopen shows telegraph again", label.visible)
	await _cleanup([door])
