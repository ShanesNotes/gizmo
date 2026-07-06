extends SceneTree

# Headless tests for the Hades-pivot RunController core.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_run_controller_tests.gd

const RunControllerScript := preload("res://scripts/room_graph/run_controller.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomGraph := preload("res://scripts/room_graph/room_graph.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running RunController tests...")
	_test_start_run_generates_graph_and_enters_entry()
	_test_clear_room_unlocks_successors_and_opens_doors()
	_test_notify_room_cleared_rejects_unentered_room_without_unlocks()
	_test_notify_room_cleared_without_current_room_does_not_emit()
	_test_generated_branch_exit_path_exercises_public_generator()
	_test_branch_exit_choice_advances_to_either_destination()
	_test_exit_reward_type_reports_destination_rewards()
	_test_choose_exit_before_start_run_is_rejected()
	_test_choose_exit_rejects_uncleared_current_room()
	_test_choose_exit_rejects_locked_destination()
	_test_choose_exit_rejects_missing_destination_without_state_change()
	_test_choose_exit_rejects_wrong_origin_without_state_change()
	_test_clearing_boss_room_completes_run_without_opening_doors()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => RunController failed to load/compile)" if _passed == 0 else ""]
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

func _make_template(template_id: String, room_type: RoomTemplate.RoomType) -> RoomTemplate:
	var template := RoomTemplate.new()
	template.template_id = template_id
	template.biome_id = "test_biome"
	template.room_type = room_type
	return template

func _make_template_pool() -> Array[RoomTemplate]:
	var pool: Array[RoomTemplate] = []
	pool.append(_make_template("combat_a", RoomTemplate.RoomType.COMBAT))
	pool.append(_make_template("combat_b", RoomTemplate.RoomType.COMBAT))
	pool.append(_make_template("elite_a", RoomTemplate.RoomType.ELITE))
	pool.append(_make_template("shop_a", RoomTemplate.RoomType.SHOP))
	pool.append(_make_template("boss_finale", RoomTemplate.RoomType.BOSS))
	return pool

func _seeded_rng(seed: int = 42) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _new_controller():
	var controller = RunControllerScript.new()
	controller.name = "RunControllerHarness"
	root.add_child(controller)
	return controller

func _cleanup(controller: Node) -> void:
	controller.queue_free()

func _test_start_run_generates_graph_and_enters_entry() -> void:
	var controller = _new_controller()
	var entered_rooms: Array[RoomNode] = []
	controller.room_entered.connect(func(room: RoomNode) -> void:
		entered_rooms.append(room)
	)

	var graph: RoomGraph = controller.start_run("test_biome", _make_template_pool(), 6, _seeded_rng(11))
	var entry := graph.get_room(graph.entry_room_id)

	_check("start_run creates a graph", graph != null)
	_check("controller owns the generated graph", controller.graph == graph)
	_check_eq("generated graph records biome_id", graph.biome_id, "test_biome")
	_check_eq("generated graph has requested room count", graph.rooms.size(), 6)
	_check_eq("controller current_room_id starts at entry", controller.current_room_id, graph.entry_room_id)
	_check_eq("entry room enters immediately", entry.state, RoomNode.State.ENTERED)
	_check_eq("room_entered emits once for entry", entered_rooms.size(), 1)
	_check("room_entered payload is the entry room", entered_rooms[0] == entry)
	_cleanup(controller)

func _test_clear_room_unlocks_successors_and_opens_doors() -> void:
	var controller = _new_controller()
	var graph: RoomGraph = controller.start_run("test_biome", _make_template_pool(), 6, _seeded_rng(3))
	var current := graph.get_room(controller.current_room_id)
	var expected_connections := graph.get_connections_from(controller.current_room_id)
	var cleared_rooms: Array[RoomNode] = []
	var opened_batches: Array[Array] = []
	var completed_events: Array[bool] = []
	controller.room_cleared.connect(func(room: RoomNode) -> void:
		cleared_rooms.append(room)
	)
	controller.doors_opened.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	controller.run_completed.connect(func() -> void:
		completed_events.append(true)
	)

	controller.notify_room_cleared()

	_check_eq("notify_room_cleared marks current room CLEARED", current.state, RoomNode.State.CLEARED)
	_check_eq("room_cleared emits once", cleared_rooms.size(), 1)
	_check("room_cleared payload is the current room", cleared_rooms[0] == current)
	_check_eq("non-boss clear does not complete run", completed_events.size(), 0)
	_check_eq("doors_opened emits once", opened_batches.size(), 1)
	_check_eq("doors_opened payload has outgoing connection count", opened_batches[0].size(), expected_connections.size())

	for connection in expected_connections:
		var destination := graph.get_room(connection.to_room_id)
		_check_eq("successor %s becomes AVAILABLE" % connection.to_room_id, destination.state, RoomNode.State.AVAILABLE)
		_check("opened door exposes door_name", connection.door_name != "")
		_check("opened door destination exposes reward_type", destination.reward_type >= RoomNode.RewardType.BOON)

	controller.notify_room_cleared()

	_check_eq("double clear leaves room_cleared emission count at one", cleared_rooms.size(), 1)
	_check_eq("double clear leaves doors_opened emission count at one batch", opened_batches.size(), 1)
	_check_eq("double clear still does not complete non-boss run", completed_events.size(), 0)
	_cleanup(controller)

func _test_notify_room_cleared_rejects_unentered_room_without_unlocks() -> void:
	var controller = _new_controller()
	var graph := _make_branch_graph()
	controller.graph = graph
	controller.current_room_id = "room_00"
	var current := graph.get_room("room_00")
	var left := graph.get_room("room_left")
	var right := graph.get_room("room_right")
	current.state = RoomNode.State.AVAILABLE
	var cleared_rooms: Array[RoomNode] = []
	var opened_batches: Array[Array] = []
	var completed_events: Array[bool] = []
	controller.room_cleared.connect(func(room: RoomNode) -> void:
		cleared_rooms.append(room)
	)
	controller.doors_opened.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	controller.run_completed.connect(func() -> void:
		completed_events.append(true)
	)

	controller.notify_room_cleared()

	_check_eq("unentered clear leaves current room AVAILABLE", current.state, RoomNode.State.AVAILABLE)
	_check_eq("unentered clear leaves left successor LOCKED", left.state, RoomNode.State.LOCKED)
	_check_eq("unentered clear leaves right successor LOCKED", right.state, RoomNode.State.LOCKED)
	_check_eq("unentered clear emits no room_cleared signal", cleared_rooms.size(), 0)
	_check_eq("unentered clear emits no doors_opened signal", opened_batches.size(), 0)
	_check_eq("unentered clear emits no run_completed signal", completed_events.size(), 0)
	_cleanup(controller)

func _test_notify_room_cleared_without_current_room_does_not_emit() -> void:
	var controller = _new_controller()
	var cleared_rooms: Array[RoomNode] = []
	var opened_batches: Array[Array] = []
	var completed_events: Array[bool] = []
	controller.room_cleared.connect(func(room: RoomNode) -> void:
		cleared_rooms.append(room)
	)
	controller.doors_opened.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	controller.run_completed.connect(func() -> void:
		completed_events.append(true)
	)

	controller.notify_room_cleared()
	_check_eq("clear before start_run emits no room_cleared signal", cleared_rooms.size(), 0)
	_check_eq("clear before start_run emits no doors_opened signal", opened_batches.size(), 0)
	_check_eq("clear before start_run emits no run_completed signal", completed_events.size(), 0)

	controller.graph = RoomGraph.new()
	controller.current_room_id = ""
	controller.notify_room_cleared()
	_check_eq("clear with empty graph emits no room_cleared signal", cleared_rooms.size(), 0)
	_check_eq("clear with empty graph emits no doors_opened signal", opened_batches.size(), 0)
	_check_eq("clear with empty graph emits no run_completed signal", completed_events.size(), 0)
	_cleanup(controller)

func _test_generated_branch_exit_path_exercises_public_generator() -> void:
	var controller = _new_controller()
	var graph: RoomGraph = controller.start_run("test_biome", _make_template_pool(), 8, _seeded_rng(11))
	var branch_room_id := _first_branch_source_id(graph)
	_check("seed 11 public generator emits at least one 2-door room", branch_room_id != "")
	if branch_room_id == "":
		_cleanup(controller)
		return

	var safety := 0
	while controller.current_room_id != branch_room_id and safety < graph.rooms.size():
		var previous_room := graph.get_room(controller.current_room_id)
		controller.notify_room_cleared()
		var outgoing := graph.get_connections_from(previous_room.room_id)
		_check_eq("public generator path before first branch has one exit", outgoing.size(), 1)
		_check("public generator single exit advances", controller.choose_exit(outgoing[0]))
		_check_eq("public generator marks traversed room REWARDED", previous_room.state, RoomNode.State.REWARDED)
		safety += 1

	_check_eq("public generator traversal reaches branch source", controller.current_room_id, branch_room_id)
	var branch_room := graph.get_room(branch_room_id)
	var opened_batches: Array[Array] = []
	controller.doors_opened.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)

	controller.notify_room_cleared()
	var branch_connections := graph.get_connections_from(branch_room_id)

	_check_eq("public generator branch exposes two outgoing connections", branch_connections.size(), 2)
	_check_eq("public generator branch emits one doors_opened batch", opened_batches.size(), 1)
	if branch_connections.size() == 2:
		var chosen: RoomConnection = branch_connections[1]
		var destination := graph.get_room(chosen.to_room_id)
		_check_eq(
			"public generator branch reward helper reads destination reward",
			_controller_exit_reward_type(controller, chosen),
			destination.reward_type
		)
		_check("public generator branch exit advances", controller.choose_exit(chosen))
		_check_eq("public generator branch source becomes REWARDED", branch_room.state, RoomNode.State.REWARDED)
		_check_eq("public generator branch destination is current room", controller.current_room_id, destination.room_id)
		_check_eq("public generator branch destination is ENTERED", destination.state, RoomNode.State.ENTERED)
	_cleanup(controller)

func _test_branch_exit_choice_advances_to_either_destination() -> void:
	_assert_branch_exit_advances(0)
	_assert_branch_exit_advances(1)

func _assert_branch_exit_advances(connection_index: int) -> void:
	var controller = _new_controller()
	var graph := _make_branch_graph()
	controller.graph = graph
	controller.current_room_id = "room_00"
	graph.get_room("room_00").state = RoomNode.State.ENTERED
	var entered_rooms: Array[RoomNode] = []
	var opened_batches: Array[Array] = []
	controller.room_entered.connect(func(room: RoomNode) -> void:
		entered_rooms.append(room)
	)
	controller.doors_opened.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)

	controller.notify_room_cleared()
	var opened_connections: Array = opened_batches[0]
	var chosen: RoomConnection = opened_connections[connection_index]
	var previous_room := graph.get_room("room_00")
	var destination := graph.get_room(chosen.to_room_id)

	_check_eq("branch clear opens two doors for choice %d" % connection_index, opened_connections.size(), 2)
	_check_eq(
		"branch reward helper reports destination reward for door %d" % connection_index,
		_controller_exit_reward_type(controller, chosen),
		RoomNode.RewardType.SCRAP if connection_index == 0 else RoomNode.RewardType.HAMMER
	)
	_check("choose_exit accepts branch door %d" % connection_index, controller.choose_exit(chosen))
	_check_eq("chosen branch marks previous room REWARDED", previous_room.state, RoomNode.State.REWARDED)
	_check_eq("chosen branch advances current_room_id", controller.current_room_id, chosen.to_room_id)
	_check_eq("chosen branch enters destination", destination.state, RoomNode.State.ENTERED)
	_check_eq("room_entered fires for chosen destination", entered_rooms, [destination])
	_cleanup(controller)

func _test_exit_reward_type_reports_destination_rewards() -> void:
	var controller = _new_controller()
	var graph := _make_branch_graph()
	controller.graph = graph
	controller.current_room_id = "room_00"
	var connections := graph.get_connections_from("room_00")

	_check_eq("left exit reports SCRAP destination reward", _controller_exit_reward_type(controller, connections[0]), RoomNode.RewardType.SCRAP)
	_check_eq("right exit reports HAMMER destination reward", _controller_exit_reward_type(controller, connections[1]), RoomNode.RewardType.HAMMER)

	var missing_destination := _make_connection("room_00", "missing_room", "BrokenExit")
	_check_eq(
		"missing destination reward helper returns default BOON",
		_controller_exit_reward_type(controller, missing_destination),
		RoomNode.RewardType.BOON
	)
	_cleanup(controller)

func _test_choose_exit_before_start_run_is_rejected() -> void:
	var controller = _new_controller()
	var connection := _make_connection("room_00", "room_left", "LeftExit")

	_check("choose_exit before start_run is rejected", not controller.choose_exit(connection))
	_check_eq("choose_exit before start_run leaves current_room_id empty", controller.current_room_id, "")
	_cleanup(controller)

func _test_choose_exit_rejects_uncleared_current_room() -> void:
	var controller = _new_controller()
	var graph := _make_branch_graph()
	controller.graph = graph
	controller.current_room_id = "room_00"
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_left")
	current.state = RoomNode.State.ENTERED
	destination.state = RoomNode.State.AVAILABLE
	var entered_rooms: Array[RoomNode] = []
	controller.room_entered.connect(func(room: RoomNode) -> void:
		entered_rooms.append(room)
	)
	var connection := graph.get_connections_from("room_00")[0]

	_check("choose_exit before notify_room_cleared is rejected", not controller.choose_exit(connection))
	_check_eq("uncleared exit leaves current_room_id unchanged", controller.current_room_id, "room_00")
	_check_eq("uncleared exit leaves current room ENTERED", current.state, RoomNode.State.ENTERED)
	_check_eq("uncleared exit leaves destination AVAILABLE", destination.state, RoomNode.State.AVAILABLE)
	_check_eq("uncleared exit emits no room_entered signal", entered_rooms.size(), 0)
	_cleanup(controller)

func _test_choose_exit_rejects_locked_destination() -> void:
	var controller = _new_controller()
	var graph := _make_branch_graph()
	controller.graph = graph
	controller.current_room_id = "room_00"
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_left")
	current.state = RoomNode.State.CLEARED
	destination.state = RoomNode.State.LOCKED
	var entered_rooms: Array[RoomNode] = []
	controller.room_entered.connect(func(room: RoomNode) -> void:
		entered_rooms.append(room)
	)
	var connection := graph.get_connections_from("room_00")[0]

	_check("choose_exit to LOCKED destination is rejected", not controller.choose_exit(connection))
	_check_eq("locked-destination exit leaves current_room_id unchanged", controller.current_room_id, "room_00")
	_check_eq("locked-destination exit leaves current room CLEARED", current.state, RoomNode.State.CLEARED)
	_check_eq("locked-destination exit leaves destination LOCKED", destination.state, RoomNode.State.LOCKED)
	_check_eq("locked-destination exit emits no room_entered signal", entered_rooms.size(), 0)
	_cleanup(controller)

func _test_choose_exit_rejects_missing_destination_without_state_change() -> void:
	var controller = _new_controller()
	var graph := _make_branch_graph()
	controller.graph = graph
	controller.current_room_id = "room_00"
	var current := graph.get_room("room_00")
	current.state = RoomNode.State.CLEARED
	var entered_rooms: Array[RoomNode] = []
	controller.room_entered.connect(func(room: RoomNode) -> void:
		entered_rooms.append(room)
	)
	var connection := _make_connection("room_00", "missing_room", "BrokenExit")

	_check("choose_exit to missing destination is rejected", not controller.choose_exit(connection))
	_check_eq("missing-destination exit leaves current_room_id unchanged", controller.current_room_id, "room_00")
	_check_eq("missing-destination exit leaves current room CLEARED", current.state, RoomNode.State.CLEARED)
	_check_eq("missing-destination exit emits no room_entered signal", entered_rooms.size(), 0)
	_cleanup(controller)

func _test_choose_exit_rejects_wrong_origin_without_state_change() -> void:
	var controller = _new_controller()
	var graph := _make_branch_graph()
	controller.graph = graph
	controller.current_room_id = "room_00"
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_left")
	current.state = RoomNode.State.ENTERED
	controller.notify_room_cleared()
	var entered_rooms: Array[RoomNode] = []
	controller.room_entered.connect(func(_room: RoomNode) -> void:
		entered_rooms.append(_room)
	)
	var wrong_connection := RoomConnection.new()
	wrong_connection.from_room_id = "room_other"
	wrong_connection.to_room_id = destination.room_id
	wrong_connection.door_name = "WrongDoor"

	_check("wrong-origin choose_exit is rejected", not controller.choose_exit(wrong_connection))
	_check_eq("wrong-origin choice leaves current_room_id unchanged", controller.current_room_id, "room_00")
	_check_eq("wrong-origin choice leaves current room CLEARED", current.state, RoomNode.State.CLEARED)
	_check_eq("wrong-origin choice does not enter destination", destination.state, RoomNode.State.AVAILABLE)
	_check_eq("wrong-origin choice emits no room_entered signal", entered_rooms.size(), 0)
	_cleanup(controller)

func _test_clearing_boss_room_completes_run_without_opening_doors() -> void:
	var controller = _new_controller()
	var graph := RoomGraph.new()
	graph.biome_id = "test_biome"
	graph.entry_room_id = "boss_room"
	var boss := _make_room("boss_room", RoomTemplate.RoomType.BOSS, RoomNode.RewardType.BOON)
	boss.state = RoomNode.State.ENTERED
	graph.rooms.append(boss)
	controller.graph = graph
	controller.current_room_id = boss.room_id
	var cleared_rooms: Array[RoomNode] = []
	var opened_events: Array[bool] = []
	var completed_events: Array[bool] = []
	controller.room_cleared.connect(func(room: RoomNode) -> void:
		cleared_rooms.append(room)
	)
	controller.doors_opened.connect(func(_connections: Array[RoomConnection]) -> void:
		opened_events.append(true)
	)
	controller.run_completed.connect(func() -> void:
		completed_events.append(true)
	)

	controller.notify_room_cleared()

	_check_eq("boss clear marks boss CLEARED", boss.state, RoomNode.State.CLEARED)
	_check_eq("boss clear emits room_cleared", cleared_rooms, [boss])
	_check_eq("boss clear emits run_completed once", completed_events.size(), 1)
	_check_eq("boss clear does not emit doors_opened", opened_events.size(), 0)

	controller.notify_room_cleared()

	_check_eq("boss double clear leaves room_cleared emission count at one", cleared_rooms.size(), 1)
	_check_eq("boss double clear leaves run_completed emission count at one", completed_events.size(), 1)
	_check_eq("boss double clear still emits no doors_opened", opened_events.size(), 0)
	_cleanup(controller)

func _make_room(
	room_id: String,
	room_type: RoomTemplate.RoomType,
	reward_type: RoomNode.RewardType,
) -> RoomNode:
	var room := RoomNode.new()
	room.room_id = room_id
	room.template = _make_template("%s_template" % room_id, room_type)
	room.reward_type = reward_type
	room.state = RoomNode.State.LOCKED
	return room

func _make_connection(from_room_id: String, to_room_id: String, door_name: String) -> RoomConnection:
	var connection := RoomConnection.new()
	connection.from_room_id = from_room_id
	connection.to_room_id = to_room_id
	connection.door_name = door_name
	return connection

func _make_branch_graph() -> RoomGraph:
	var graph := RoomGraph.new()
	graph.biome_id = "test_biome"
	graph.entry_room_id = "room_00"
	var entry := _make_room("room_00", RoomTemplate.RoomType.COMBAT, RoomNode.RewardType.BOON)
	var left := _make_room("room_left", RoomTemplate.RoomType.COMBAT, RoomNode.RewardType.SCRAP)
	var right := _make_room("room_right", RoomTemplate.RoomType.COMBAT, RoomNode.RewardType.HAMMER)
	left.state = RoomNode.State.LOCKED
	right.state = RoomNode.State.LOCKED
	graph.rooms.append(entry)
	graph.rooms.append(left)
	graph.rooms.append(right)
	graph.connections.append(_make_connection(entry.room_id, left.room_id, "LeftExit"))
	graph.connections.append(_make_connection(entry.room_id, right.room_id, "RightExit"))
	return graph

func _first_branch_source_id(graph: RoomGraph) -> String:
	for room in graph.rooms:
		if graph.get_connections_from(room.room_id).size() == 2:
			return room.room_id
	return ""

func _controller_exit_reward_type(controller, connection: RoomConnection) -> RoomNode.RewardType:
	if not controller.has_method("exit_reward_type"):
		_check("RunController exposes exit_reward_type", false)
		return RoomNode.RewardType.BOON
	return controller.exit_reward_type(connection)
