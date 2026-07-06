class_name RoomGraphGenerator
extends RefCounted

## Builds a run's RoomGraph from an authored template pool. Logic lives here
## (not on RoomGraph/RoomNode/RoomTemplate) per the resource-pattern rule that
## Resources hold data, not behavior.
##
## v1 shape: a seeded branch/rejoin DAG over `room_count` indexed rooms. The
## last slot is forced BOSS, each non-terminal room has 1-2 exits, branch exits
## rejoin within one step, and generated rewards are fixed up front for honest
## door telegraphs.

const BRANCH_CHANCE: float = 0.55
const REST_ROOM_CHANCE: float = 0.35
const REWARD_ROOM_CHANCE: float = 0.25
const DOOR_SINGLE: String = "RoomExit"
const DOOR_BRANCH_A: String = "RoomExitA"
const DOOR_BRANCH_B: String = "RoomExitB"

static func generate(
	biome_id: String,
	template_pool: Array[RoomTemplate],
	room_count: int,
	rng: RandomNumberGenerator,
) -> RoomGraph:
	var graph := RoomGraph.new()
	graph.biome_id = biome_id
	if room_count <= 0:
		return graph

	var active_rng := rng
	if active_rng == null:
		active_rng = RandomNumberGenerator.new()
		active_rng.randomize()

	var fixture_indices := _pick_fixture_indices(room_count, active_rng)
	var shop_index := int(fixture_indices["shop"])
	var elite_index := int(fixture_indices["elite"])
	var branch_sources := _pick_branch_sources(room_count, active_rng)
	var non_combat_indices := _pick_non_combat_replacement_indices(
		room_count,
		active_rng,
		template_pool,
		shop_index,
		elite_index,
		branch_sources
	)
	var rest_index := int(non_combat_indices["rest"])
	var reward_indices: Array[int] = non_combat_indices["reward"]

	for i in range(room_count):
		var room := RoomNode.new()
		room.room_id = "room_%02d" % i
		room.template = _pick_template(
			template_pool,
			i,
			room_count,
			active_rng,
			elite_index,
			shop_index,
			rest_index,
			reward_indices
		)
		room.reward_type = _pick_reward_type(i, shop_index, rest_index, reward_indices, active_rng)
		room.difficulty_tier = float(i) / float(maxi(room_count - 1, 1))
		room.state = RoomNode.State.LOCKED if i > 0 else RoomNode.State.AVAILABLE
		graph.rooms.append(room)

	for i in range(room_count - 1):
		if branch_sources.has(i):
			_add_connection(graph, i, i + 1, DOOR_BRANCH_A)
			_add_connection(graph, i, i + 2, DOOR_BRANCH_B)
		else:
			_add_connection(graph, i, i + 1, DOOR_SINGLE)

	graph.entry_room_id = graph.rooms[0].room_id if not graph.rooms.is_empty() else ""
	return graph

static func _pick_template(
	pool: Array[RoomTemplate],
	index: int,
	room_count: int,
	rng: RandomNumberGenerator,
	elite_index: int = -1,
	shop_index: int = -1,
	rest_index: int = -1,
	reward_indices: Array[int] = [],
) -> RoomTemplate:
	if pool.is_empty():
		push_error("RoomGraphGenerator: template pool is empty")
		return null

	var is_boss := index == room_count - 1
	var candidates: Array[RoomTemplate] = []
	if is_boss:
		candidates = _templates_matching_types(pool, [RoomTemplate.RoomType.BOSS])
	elif index == elite_index:
		candidates = _templates_matching_types(pool, [RoomTemplate.RoomType.ELITE])
		if candidates.is_empty():
			push_error("RoomGraphGenerator: template pool has no ELITE template; elite fixture cannot be honored")
			candidates = _standard_room_candidates(pool)
	elif index == shop_index:
		candidates = _templates_matching_types(pool, [RoomTemplate.RoomType.SHOP])
		if candidates.is_empty():
			candidates = _standard_room_candidates(pool)
	elif index == rest_index:
		candidates = _templates_matching_types(pool, [RoomTemplate.RoomType.REST])
		if candidates.is_empty():
			candidates = _standard_room_candidates(pool)
	elif reward_indices.has(index):
		candidates = _templates_matching_types(pool, [RoomTemplate.RoomType.REWARD])
		if candidates.is_empty():
			candidates = _standard_room_candidates(pool)
	else:
		candidates = _standard_room_candidates(pool)

	if candidates.is_empty():
		if is_boss:
			push_error("RoomGraphGenerator: template pool has no BOSS template; final room will not be a boss")
		candidates = _non_boss_candidates(pool) if not is_boss else pool
	return candidates[rng.randi_range(0, candidates.size() - 1)]

static func _pick_fixture_indices(room_count: int, rng: RandomNumberGenerator) -> Dictionary:
	var indices := _mid_biome_indices(room_count)
	if indices.is_empty():
		return {"shop": -1, "elite": -1}

	var shop_index: int = indices[rng.randi_range(0, indices.size() - 1)]
	var elite_index := shop_index
	if indices.size() > 1:
		var elite_candidates := indices.duplicate()
		elite_candidates.erase(shop_index)
		elite_index = elite_candidates[rng.randi_range(0, elite_candidates.size() - 1)]
	return {"shop": shop_index, "elite": elite_index}

static func _pick_non_combat_replacement_indices(
	room_count: int,
	rng: RandomNumberGenerator,
	pool: Array[RoomTemplate],
	shop_index: int,
	elite_index: int,
	branch_sources: Dictionary,
) -> Dictionary:
	var rest_index := -1
	if _has_template_type(pool, RoomTemplate.RoomType.REST):
		var rest_candidates := _eligible_non_combat_indices(room_count, shop_index, elite_index, branch_sources, true)
		if not rest_candidates.is_empty() and rng.randf() < REST_ROOM_CHANCE:
			rest_index = rest_candidates[rng.randi_range(0, rest_candidates.size() - 1)]

	var reward_indices: Array[int] = []
	if _has_template_type(pool, RoomTemplate.RoomType.REWARD):
		var reward_candidates := _eligible_non_combat_indices(room_count, shop_index, elite_index, branch_sources, false)
		if rest_index >= 0:
			reward_candidates.erase(rest_index)
		if not reward_candidates.is_empty() and rng.randf() < REWARD_ROOM_CHANCE:
			reward_indices.append(reward_candidates[rng.randi_range(0, reward_candidates.size() - 1)])

	return {
		"rest": rest_index,
		"reward": reward_indices,
	}

static func _eligible_non_combat_indices(
	room_count: int,
	shop_index: int,
	elite_index: int,
	branch_sources: Dictionary,
	back_half_only: bool,
) -> Array[int]:
	var result: Array[int] = []
	var first_allowed := 1
	var last_allowed := room_count - 3
	if last_allowed < first_allowed:
		return result

	var first_back_half := int(ceil(float(room_count) * 0.5))
	for i in range(first_allowed, last_allowed + 1):
		if back_half_only and i < first_back_half:
			continue
		if i == shop_index or i == elite_index:
			continue
		# Non-combat room eligibility is based on the graph edges this generator
		# will build, including branch skips, not only neighboring room indices.
		if _is_shop_graph_adjacent_candidate(i, shop_index, branch_sources):
			continue
		result.append(i)
	return result

static func _is_shop_graph_adjacent_candidate(index: int, shop_index: int, branch_sources: Dictionary) -> bool:
	if shop_index < 0:
		return false
	if absi(index - shop_index) <= 1:
		return true
	if branch_sources.has(shop_index - 2) and index == shop_index - 2:
		return true
	if branch_sources.has(shop_index) and index == shop_index + 2:
		return true
	return false

static func _mid_biome_indices(room_count: int) -> Array[int]:
	var result: Array[int] = []
	var first_interior := 1
	var last_interior := room_count - 2
	if last_interior < first_interior:
		return result

	var first_mid := clampi(int(floor(float(room_count) * 0.35)), first_interior, last_interior)
	var last_mid := clampi(int(ceil(float(room_count) * 0.75)), first_interior, last_interior)
	if first_mid > last_mid:
		first_mid = first_interior
		last_mid = last_interior
	for i in range(first_mid, last_mid + 1):
		result.append(i)
	return result

static func _pick_branch_sources(room_count: int, rng: RandomNumberGenerator) -> Dictionary:
	var sources: Dictionary = {}
	if room_count < 3:
		return sources

	var i := 0
	while i <= room_count - 3:
		if rng.randf() < BRANCH_CHANCE:
			sources[i] = true
			i += 2
		else:
			i += 1

	if sources.is_empty():
		sources[rng.randi_range(0, room_count - 3)] = true
	return sources

static func _add_connection(graph: RoomGraph, from_index: int, to_index: int, door_name: String) -> void:
	if to_index >= graph.rooms.size():
		return
	var connection := RoomConnection.new()
	connection.from_room_id = graph.rooms[from_index].room_id
	connection.to_room_id = graph.rooms[to_index].room_id
	connection.door_name = door_name
	graph.connections.append(connection)

static func _pick_reward_type(
	index: int,
	shop_index: int,
	rest_index: int,
	reward_indices: Array[int],
	rng: RandomNumberGenerator,
) -> RoomNode.RewardType:
	if index == rest_index:
		return RoomNode.RewardType.REST
	if reward_indices.has(index):
		return RoomNode.RewardType.REWARD
	if index == shop_index:
		return RoomNode.RewardType.SHOP

	var weighted_rewards := [
		[RoomNode.RewardType.BOON, 45.0],
		[RoomNode.RewardType.SCRAP, 20.0],
		[RoomNode.RewardType.SPARKS, 18.0],
		[RoomNode.RewardType.HAMMER, 8.0],
		[RoomNode.RewardType.HEAL, 9.0],
	]
	var total_weight := 0.0
	for entry in weighted_rewards:
		total_weight += float(entry[1])

	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for entry in weighted_rewards:
		cursor += float(entry[1])
		if roll <= cursor:
			return entry[0]
	return RoomNode.RewardType.BOON

static func _templates_matching_types(pool: Array[RoomTemplate], room_types: Array) -> Array[RoomTemplate]:
	var candidates: Array[RoomTemplate] = []
	for template in pool:
		if template != null and room_types.has(template.room_type):
			candidates.append(template)
	return candidates

static func _has_template_type(pool: Array[RoomTemplate], room_type: RoomTemplate.RoomType) -> bool:
	for template in pool:
		if template != null and template.room_type == room_type:
			return true
	return false

static func _standard_room_candidates(pool: Array[RoomTemplate]) -> Array[RoomTemplate]:
	var candidates: Array[RoomTemplate] = []
	for template in pool:
		if template == null:
			continue
		if template.room_type == RoomTemplate.RoomType.BOSS:
			continue
		if template.room_type == RoomTemplate.RoomType.ELITE:
			continue
		if template.room_type == RoomTemplate.RoomType.SHOP:
			continue
		if template.room_type == RoomTemplate.RoomType.REST:
			continue
		if template.room_type == RoomTemplate.RoomType.REWARD:
			continue
		candidates.append(template)
	return candidates

static func _non_boss_candidates(pool: Array[RoomTemplate]) -> Array[RoomTemplate]:
	var candidates: Array[RoomTemplate] = []
	for template in pool:
		if template != null and template.room_type != RoomTemplate.RoomType.BOSS:
			candidates.append(template)
	return candidates
