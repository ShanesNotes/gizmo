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
	_test_generator_assigns_region_identity_from_graph()
	_test_region_assignment_is_deterministic_and_covers_both_routes()
	_test_trial_beat_spikes_penultimate_room_tier()
	_test_room_node_reward_type_vocabulary_includes_rest_reward()
	_test_rest_reward_seed_sweep_invariants()
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
	pool.append(_make_template("reward_cache", RoomTemplate.RoomType.REWARD, ["cache"]))
	pool.append(_make_template("shop_a", RoomTemplate.RoomType.SHOP, ["shop"]))
	pool.append(_make_template("rest_alcove", RoomTemplate.RoomType.REST, ["rest"]))
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

# Region vocabulary is pinned here as a second copy of the naming source of
# truth (docs/reference/shattered-meridian-region-graph.json macro_topology +
# regions.*.name/landmark) so the generator table cannot drift into invented
# place names without a test catching it.
const REGION_NAMES := {
	"HEARTH": "Hearthwake Basin",
	"BRASS": "Brasswind Highlands",
	"VERDANT": "Verdant Archive",
	"PRISM": "Prism Reach",
	"TEMPEST": "Tempest Verge",
	"NULL": "The Null Crown",
	"RUST": "Rustchain Expanse",
	"ASH": "Ashfall Foundries",
}

const REGION_LANDMARKS := {
	"HEARTH": "The Heart Spire",
	"BRASS": "The Chronarch Keep",
	"VERDANT": "The Memory Tree",
	"PRISM": "The Nebula Prism",
	"TEMPEST": "The Storm Engine",
	"NULL": "The Last Ember",
	"RUST": "The Titan Yard",
	"ASH": "The Ember Crucible",
}

const UPPER_ROUTE := ["HEARTH", "BRASS", "VERDANT", "PRISM", "TEMPEST", "NULL"]
const LOWER_ROUTE := ["HEARTH", "RUST", "ASH", "TEMPEST", "NULL"]

func _test_generator_assigns_region_identity_from_graph() -> void:
	var pool := _make_template_pool()
	for seed in [1, 2, 3, 4, 5, 6, 7, 8]:
		var graph: RoomGraph = RoomGraphGenerator.generate("hearth", pool, 8, _seeded_rng(seed))
		_assert_region_identity_contract(graph, seed)

func _assert_region_identity_contract(graph: RoomGraph, seed: int) -> void:
	var room_count := graph.rooms.size()
	var region_sequence: Array[String] = []
	for i in range(room_count):
		var room := graph.rooms[i]
		_check("seed %d: room_%02d region_id is graph vocabulary" % [seed, i], REGION_NAMES.has(room.region_id))
		if not REGION_NAMES.has(room.region_id):
			continue
		region_sequence.append(room.region_id)
		var expected_landmark := room.template != null and (
			room.template.room_type == RoomTemplate.RoomType.BOSS
			or room.template.room_type == RoomTemplate.RoomType.ELITE
		)
		var expected_name: String = REGION_LANDMARKS[room.region_id] if expected_landmark else REGION_NAMES[room.region_id]
		_check_eq("seed %d: room_%02d display name is drawn from the graph" % [seed, i], room.display_name, expected_name)

	_check_eq("seed %d: run departs from HEARTH" % seed, graph.rooms[0].region_id, "HEARTH")
	var last_room := graph.rooms[room_count - 1]
	_check_eq("seed %d: finale room reaches NULL" % seed, last_room.region_id, "NULL")
	_check_eq("seed %d: boss room is named for The Last Ember" % seed, last_room.display_name, "The Last Ember")
	_check("seed %d: region sequence follows one macro route in order" % seed, _sequence_follows_route(region_sequence))

func _sequence_follows_route(sequence: Array[String]) -> bool:
	for route in [UPPER_ROUTE, LOWER_ROUTE]:
		var cursor := 0
		var matched := true
		for region_id in sequence:
			var found: int = route.find(region_id, 0)
			if found < 0 or found < cursor:
				matched = false
				break
			cursor = found
		if matched:
			return true
	return false

func _test_region_assignment_is_deterministic_and_covers_both_routes() -> void:
	var pool := _make_template_pool()
	var saw_upper := false
	var saw_lower := false
	for seed in range(1, 41):
		var first: RoomGraph = RoomGraphGenerator.generate("hearth", pool, 8, _seeded_rng(seed))
		var second: RoomGraph = RoomGraphGenerator.generate("hearth", pool, 8, _seeded_rng(seed))
		var identical := true
		for i in range(first.rooms.size()):
			if first.rooms[i].region_id != second.rooms[i].region_id:
				identical = false
			if first.rooms[i].display_name != second.rooms[i].display_name:
				identical = false
		_check("seed %d: region assignment is deterministic under the run seed" % seed, identical)
		for room in first.rooms:
			if room.region_id == "BRASS":
				saw_upper = true
			if room.region_id == "RUST":
				saw_lower = true
	_check("seed sweep reaches the upper route", saw_upper)
	_check("seed sweep reaches the lower route", saw_lower)

func _test_trial_beat_spikes_penultimate_room_tier() -> void:
	# encounter-beats.yaml `trial`: a diegetic danger spike before relief/climax,
	# expressed through the existing difficulty_tier knob (no new mechanics).
	var pool := _make_template_pool()
	for seed in [11, 12, 13]:
		var graph: RoomGraph = RoomGraphGenerator.generate("hearth", pool, 8, _seeded_rng(seed))
		var linear_tier := 6.0 / 7.0
		var trial_tier := graph.rooms[6].difficulty_tier
		_check("seed %d: trial room tier spikes above the linear ramp" % seed, trial_tier > linear_tier + 0.01)
		_check("seed %d: trial tier stays clamped" % seed, trial_tier <= 1.0)
		_check_eq("seed %d: entrance stays at tier zero" % seed, graph.rooms[0].difficulty_tier, 0.0)
		_check_eq("seed %d: boss keeps peak tier" % seed, graph.rooms[7].difficulty_tier, 1.0)

	var tiny: RoomGraph = RoomGraphGenerator.generate("hearth", pool, 2, _seeded_rng(11))
	_check_eq("two-room run never spikes the entrance", tiny.rooms[0].difficulty_tier, 0.0)

func _test_room_node_reward_type_vocabulary_includes_rest_reward() -> void:
	_check("RewardType exposes REST for Ember Alcove door telegraphs", RoomNode.RewardType.has("REST"))
	_check("RewardType exposes REWARD for Scrap Cache door telegraphs", RoomNode.RewardType.has("REWARD"))

func _test_rest_reward_seed_sweep_invariants() -> void:
	var pool := _make_template_pool()
	var saw_rest := false
	var saw_reward := false
	var reward_room_count := 0
	var combat_room_count := 0
	var room_counts := [2, 5, 7, 8, 11, 16]
	# Pre-fix repro found by this sweep: room_count 7 seed 51 placed a
	# REWARD at room_02, with SHOP at room_04 over branch edge room_02->room_04.
	for room_count in room_counts:
		for seed in range(1, 61):
			var graph: RoomGraph = RoomGraphGenerator.generate("test_biome", pool, room_count, _seeded_rng(seed))
			var result := _assert_rest_reward_rules(graph, seed, room_count)
			saw_rest = saw_rest or bool(result["saw_rest"])
			saw_reward = saw_reward or bool(result["saw_reward"])
			reward_room_count += int(result["reward_count"])
			combat_room_count += int(result["combat_count"])

	_check("seed sweep generates at least one REST room when a REST template is available", saw_rest)
	_check("seed sweep generates at least one REWARD room when a REWARD template is available", saw_reward)
	_check("REWARD rooms stay lower-frequency than combat rooms", reward_room_count > 0 and reward_room_count < combat_room_count)

func _assert_rest_reward_rules(graph: RoomGraph, seed: int, room_count: int) -> Dictionary:
	var rest_indices: Array[int] = []
	var reward_indices: Array[int] = []
	var shop_indices: Array[int] = []
	var elite_indices: Array[int] = []
	var combat_count := 0
	for i in range(graph.rooms.size()):
		var room := graph.rooms[i]
		if room.template == null:
			continue
		match room.template.room_type:
			RoomTemplate.RoomType.REST:
				rest_indices.append(i)
			RoomTemplate.RoomType.REWARD:
				reward_indices.append(i)
			RoomTemplate.RoomType.SHOP:
				shop_indices.append(i)
			RoomTemplate.RoomType.ELITE:
				elite_indices.append(i)
			RoomTemplate.RoomType.COMBAT:
				combat_count += 1

	_check_eq("room_count %d seed %d: at most one REST room per biome" % [room_count, seed], rest_indices.size() <= 1, true)
	for rest_index in rest_indices:
		_assert_non_combat_index_rule(graph, seed, room_count, rest_index, "REST", shop_indices, elite_indices)
		_check_eq("room_count %d seed %d: REST is placed in the back half" % [room_count, seed], rest_index >= graph.rooms.size() / 2, true)
		if RoomNode.RewardType.has("REST"):
			_check_eq("room_count %d seed %d: REST room telegraphs REST" % [room_count, seed], graph.rooms[rest_index].reward_type, _reward_type_value("REST", -1))

	for reward_index in reward_indices:
		_assert_non_combat_index_rule(graph, seed, room_count, reward_index, "REWARD", shop_indices, elite_indices)
		if RoomNode.RewardType.has("REWARD"):
			_check_eq("room_count %d seed %d: REWARD room telegraphs REWARD" % [room_count, seed], graph.rooms[reward_index].reward_type, _reward_type_value("REWARD", -1))

	return {
		"saw_rest": not rest_indices.is_empty(),
		"saw_reward": not reward_indices.is_empty(),
		"reward_count": reward_indices.size(),
		"combat_count": combat_count,
	}

func _assert_non_combat_index_rule(
	graph: RoomGraph,
	seed: int,
	room_count: int,
	index: int,
	label: String,
	shop_indices: Array[int],
	elite_indices: Array[int],
) -> void:
	_check("%s room_count %d seed %d: never first room" % [label, room_count, seed], index > 0)
	_check("%s room_count %d seed %d: never boss-adjacent" % [label, room_count, seed], index < graph.rooms.size() - 2)
	_check("%s room_count %d seed %d: does not replace an ELITE fixture" % [label, room_count, seed], not elite_indices.has(index))
	for shop_index in shop_indices:
		_check(
			"%s room_count %d seed %d: room_%02d never door-adjacent to SHOP room_%02d" % [label, room_count, seed, index, shop_index],
			not _rooms_share_direct_connection(graph, index, shop_index)
		)

func _rooms_share_direct_connection(graph: RoomGraph, first_index: int, second_index: int) -> bool:
	if first_index < 0 or second_index < 0:
		return false
	if first_index >= graph.rooms.size() or second_index >= graph.rooms.size():
		return false
	var first_room_id := graph.rooms[first_index].room_id
	var second_room_id := graph.rooms[second_index].room_id
	for connection in graph.connections:
		if connection.from_room_id == first_room_id and connection.to_room_id == second_room_id:
			return true
		if connection.from_room_id == second_room_id and connection.to_room_id == first_room_id:
			return true
	return false

func _reward_type_value(name: String, fallback: int) -> int:
	if RoomNode.RewardType.has(name):
		return int(RoomNode.RewardType[name])
	return fallback

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
