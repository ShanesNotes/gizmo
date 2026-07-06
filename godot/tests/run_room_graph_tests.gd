extends SceneTree

# Headless tests for the Hades-pivot room-graph scaffold.
# Run with:
#   godot --headless --user-data-dir /tmp/godot-user --path godot --script res://tests/run_room_graph_tests.gd

const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomGraph := preload("res://scripts/room_graph/room_graph.gd")
const RoomGraphGenerator := preload("res://scripts/room_graph/room_graph_generator.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running room-graph tests...")
	_test_generator_produces_branching_graphs_with_honest_rewards()
	_test_room_node_state_transitions_to_cleared()
	_test_room_connection_links_two_nodes_one_way()
	_test_room_graph_lookups()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL — %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks ⇒ room graph failed to load/compile)" if _passed == 0 else ""]
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

func _make_template(
	template_id: String,
	room_type: RoomTemplate.RoomType,
	tags: Array[String] = [],
) -> RoomTemplate:
	var template := RoomTemplate.new()
	template.template_id = template_id
	template.room_type = room_type
	template.tags = tags
	return template

func _make_template_pool() -> Array[RoomTemplate]:
	var pool: Array[RoomTemplate] = []
	pool.append(_make_template("combat_a", RoomTemplate.RoomType.COMBAT, ["arena"]))
	pool.append(_make_template("combat_b", RoomTemplate.RoomType.COMBAT, ["narrow"]))
	pool.append(_make_template("elite_a", RoomTemplate.RoomType.ELITE, ["elite"]))
	pool.append(_make_template("shop_a", RoomTemplate.RoomType.SHOP, ["shop"]))
	pool.append(_make_template("boss_finale", RoomTemplate.RoomType.BOSS, ["boss"]))
	return pool

func _seeded_rng(seed: int = 42) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _test_generator_produces_branching_graphs_with_honest_rewards() -> void:
	var pool := _make_template_pool()
	for seed in [1, 2, 3, 4, 5]:
		_assert_generated_graph_contract(pool, 8, seed)

func _assert_generated_graph_contract(pool: Array[RoomTemplate], room_count: int, seed: int) -> void:
	var graph: RoomGraph = RoomGraphGenerator.generate("test_biome", pool, room_count, _seeded_rng(seed))

	_check_eq("seed %d: generator sets biome_id" % seed, graph.biome_id, "test_biome")
	_check_eq("seed %d: generator produces expected room count" % seed, graph.rooms.size(), room_count)
	_check_eq("seed %d: entry room is room_00" % seed, graph.entry_room_id, "room_00")
	_check_eq("seed %d: all rooms are reachable" % seed, _reachable_room_count(graph), room_count)

	var shop_rewards := 0
	var elite_rooms := 0
	var branch_nodes := 0
	for i in range(room_count):
		var room := graph.rooms[i]
		_check_eq("seed %d: room id follows index naming" % seed, room.room_id, "room_%02d" % i)
		if room.reward_type == RoomNode.RewardType.SHOP:
			shop_rewards += 1
		if room.template.room_type == RoomTemplate.RoomType.ELITE:
			elite_rooms += 1
			_check("seed %d: elite room is not first or last" % seed, i > 0 and i < room_count - 1)

	var last_room := graph.rooms[room_count - 1]
	_check_eq("seed %d: last room uses a BOSS template" % seed, last_room.template.room_type, RoomTemplate.RoomType.BOSS)
	_check("seed %d: last room template carries boss tag" % seed, last_room.template.tags.has("boss"))
	_check_eq("seed %d: exactly one SHOP reward is assigned" % seed, shop_rewards, 1)
	_check("seed %d: at least one ELITE room is placed" % seed, elite_rooms >= 1)

	for i in range(room_count - 1):
		var outgoing := graph.get_connections_from("room_%02d" % i)
		_check_eq(
			"seed %d: non-terminal room has 1-2 exits" % seed,
			outgoing.size() >= 1 and outgoing.size() <= 2,
			true,
		)
		if outgoing.size() == 2:
			branch_nodes += 1
			_check("seed %d: branch at room_%02d rejoins within one step" % [seed, i], _branch_rejoins_within_one_step(graph, i))

	_check("seed %d: generated graph has at least one branch node" % seed, branch_nodes >= 1)
	_check_eq("seed %d: terminal room has no outgoing connections" % seed, graph.get_connections_from("room_%02d" % (room_count - 1)).size(), 0)

func _reachable_room_count(graph: RoomGraph) -> int:
	var seen: Dictionary = {}
	var stack: Array[String] = [graph.entry_room_id]
	while not stack.is_empty():
		var room_id: String = stack.pop_back()
		if room_id == "" or seen.has(room_id):
			continue
		seen[room_id] = true
		for next_id in graph.get_next_room_ids(room_id):
			if not seen.has(next_id):
				stack.append(next_id)
	return seen.size()

func _branch_rejoins_within_one_step(graph: RoomGraph, branch_index: int) -> bool:
	var side_room_id := "room_%02d" % (branch_index + 1)
	var rejoin_room_id := "room_%02d" % (branch_index + 2)
	var branch_next_ids := graph.get_next_room_ids("room_%02d" % branch_index)
	if not branch_next_ids.has(side_room_id) or not branch_next_ids.has(rejoin_room_id):
		return false
	return graph.get_next_room_ids(side_room_id).has(rejoin_room_id)

func _test_room_node_state_transitions_to_cleared() -> void:
	var graph := RoomGraph.new()
	var room := RoomNode.new()
	room.room_id = "room_00"
	room.state = RoomNode.State.AVAILABLE
	room.reward_type = RoomNode.RewardType.BOON
	graph.rooms.append(room)

	_check_eq("room starts uncleared (not CLEARED)", room.state == RoomNode.State.CLEARED, false)
	_check_eq("room exposes a generation-time reward type", room.reward_type, RoomNode.RewardType.BOON)

	graph.mark_state("room_00", RoomNode.State.ENTERED)
	_check_eq("mark_state transitions to ENTERED", room.state, RoomNode.State.ENTERED)
	_check_eq("ENTERED is still uncleared", room.state == RoomNode.State.CLEARED, false)

	graph.mark_state("room_00", RoomNode.State.CLEARED)
	_check_eq("mark_state transitions uncleared room to CLEARED", room.state, RoomNode.State.CLEARED)

	graph.mark_state("room_00", RoomNode.State.REWARDED)
	_check_eq("mark_state can advance CLEARED to REWARDED", room.state, RoomNode.State.REWARDED)

	graph.mark_state("missing_room", RoomNode.State.CLEARED)
	_check_eq("mark_state ignores unknown room ids", room.state, RoomNode.State.REWARDED)

func _test_room_connection_links_two_nodes_one_way() -> void:
	var graph := RoomGraph.new()
	var from_room := RoomNode.new()
	from_room.room_id = "room_a"
	var to_room := RoomNode.new()
	to_room.room_id = "room_b"
	graph.rooms.append(from_room)
	graph.rooms.append(to_room)

	var connection := RoomConnection.new()
	connection.from_room_id = "room_a"
	connection.to_room_id = "room_b"
	connection.door_name = "NorthExit"
	graph.connections.append(connection)

	var from_links := graph.get_connections_from("room_a")
	_check_eq("one-way link exposes a single outgoing connection", from_links.size(), 1)
	_check_eq("outgoing connection starts at from_room_id", from_links[0].from_room_id, "room_a")
	_check_eq("outgoing connection ends at to_room_id", from_links[0].to_room_id, "room_b")
	_check_eq("connection preserves authored door_name", from_links[0].door_name, "NorthExit")
	_check_eq("get_next_room_ids returns only the downstream room", graph.get_next_room_ids("room_a"), ["room_b"])

	var reverse_links := graph.get_connections_from("room_b")
	_check_eq("destination room has no reverse outgoing connection", reverse_links.size(), 0)
	_check_eq("get_next_room_ids is empty for the destination", graph.get_next_room_ids("room_b").size(), 0)

func _test_room_graph_lookups() -> void:
	var pool := _make_template_pool()
	var graph: RoomGraph = RoomGraphGenerator.generate("lookup_biome", pool, 3, _seeded_rng(99))

	var entry := graph.get_room("room_00")
	_check("get_room returns the entry node", entry != null)
	_check_eq("entry room starts AVAILABLE", entry.state, RoomNode.State.AVAILABLE)
	_check_eq("locked successor starts LOCKED", graph.get_room("room_01").state, RoomNode.State.LOCKED)
	_check("get_room returns null for unknown ids", graph.get_room("room_missing") == null)
