class_name RoomDirector
extends RefCounted

signal wave_requested(wave_index: int, requests: Array[Dictionary])
signal room_cleared()

const ARCHETYPE_CHAFF := "chaff"
const ARCHETYPE_BRUISER := "bruiser"

const MIN_WAVES := 1
const MAX_WAVES := 3
const BASE_ROOM_BUDGET := 3.3
const TIER_BUDGET_GAIN := 8.5
const BUDGET_JITTER := 0.7
const CHAFF_COST := 1.1
const BRUISER_COST := 3.4
const BRUISER_UNLOCK_TIER := 0.45

var difficulty_tier: float = 0.0
var room_budget: float = 0.0
var spent_budget: float = 0.0
var wave_count: int = 0
var current_wave_index: int = -1

var _rng: RandomNumberGenerator
var _waves: Array[Array] = []
var _remaining_by_archetype: Dictionary = {}
var _remaining_spawn_ids: Dictionary = {}
var _reported_kill_spawn_ids: Dictionary = {}
var _started := false
var _cleared := false

func _init(p_difficulty_tier: float = 0.0, p_rng: RandomNumberGenerator = null) -> void:
	configure(p_difficulty_tier, p_rng)

func configure(p_difficulty_tier: float, p_rng: RandomNumberGenerator = null) -> void:
	difficulty_tier = clampf(p_difficulty_tier, 0.0, 1.0)
	_rng = p_rng
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	_rebuild_plan()
	current_wave_index = -1
	_remaining_by_archetype.clear()
	_remaining_spawn_ids.clear()
	_reported_kill_spawn_ids.clear()
	_started = false
	_cleared = false

func start() -> Array[Dictionary]:
	if _started or _cleared:
		return current_spawn_requests()
	_started = true
	current_wave_index = 0
	_prime_current_wave()
	wave_requested.emit(current_wave_index, current_spawn_requests())
	return current_spawn_requests()

func planned_waves() -> Array[Array]:
	var result: Array[Array] = []
	for wave: Array in _waves:
		result.append(_duplicate_requests(wave))
	return result

func current_spawn_requests() -> Array[Dictionary]:
	if current_wave_index < 0 or current_wave_index >= _waves.size():
		var empty: Array[Dictionary] = []
		return empty
	return _duplicate_requests(_waves[current_wave_index])

func remaining_by_archetype() -> Dictionary:
	return _remaining_by_archetype.duplicate()

func remaining_spawn_ids() -> Array[String]:
	var result: Array[String] = []
	for spawn_id in _remaining_spawn_ids.keys():
		result.append(String(spawn_id))
	result.sort()
	return result

func remaining_in_wave() -> int:
	var total := 0
	for archetype in _remaining_by_archetype.keys():
		total += int(_remaining_by_archetype[archetype])
	return total

func is_room_cleared() -> bool:
	return _cleared

func unspent_budget() -> float:
	return maxf(0.0, room_budget - spent_budget)

func notify_kill(spawn_id: String) -> bool:
	var normalized_id := String(spawn_id)
	if normalized_id == "":
		return false
	if _reported_kill_spawn_ids.has(normalized_id):
		push_error("RoomDirector ignored duplicate kill report for spawn_id '%s'." % normalized_id)
		return false
	if not _started or _cleared:
		return false
	if not _remaining_spawn_ids.has(normalized_id):
		return false

	var archetype := String(_remaining_spawn_ids[normalized_id])
	_remaining_spawn_ids.erase(normalized_id)
	_reported_kill_spawn_ids[normalized_id] = true

	var remaining := int(_remaining_by_archetype[archetype])
	remaining -= 1
	if remaining <= 0:
		_remaining_by_archetype.erase(archetype)
	else:
		_remaining_by_archetype[archetype] = remaining

	if remaining_in_wave() == 0:
		_advance_after_wave_dead()
	return true

func _rebuild_plan() -> void:
	_waves.clear()
	spent_budget = 0.0
	wave_count = _calculate_wave_count()
	room_budget = _round_budget(BASE_ROOM_BUDGET + difficulty_tier * TIER_BUDGET_GAIN + _rng.randf_range(0.0, BUDGET_JITTER))

	var budget_remaining := room_budget
	var carry_budget := 0.0
	for wave_index in range(wave_count):
		var waves_left := wave_count - wave_index
		var nominal_budget := budget_remaining / float(waves_left)
		if wave_count > 1 and wave_index < wave_count - 1:
			var late_weight := lerpf(0.88, 1.12, float(wave_index) / float(wave_count - 1))
			nominal_budget = minf(budget_remaining, nominal_budget * late_weight)
		budget_remaining -= nominal_budget

		var usable_budget := nominal_budget + carry_budget
		var wave_requests := _requests_for_budget(usable_budget, wave_index)
		var wave_spend := _requests_cost(wave_requests)
		carry_budget = maxf(0.0, usable_budget - wave_spend)
		spent_budget += wave_spend
		_waves.append(wave_requests)

func _calculate_wave_count() -> int:
	var scaled := difficulty_tier * float(MAX_WAVES - MIN_WAVES) + _rng.randf()
	return clampi(MIN_WAVES + int(floor(scaled)), MIN_WAVES, MAX_WAVES)

func _requests_for_budget(budget: float, wave_index: int) -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	var budget_left := budget

	var bruiser_count := _bruiser_count_for_budget(budget_left, wave_index)
	if bruiser_count > 0:
		requests.append(_spawn_request(ARCHETYPE_BRUISER, bruiser_count, wave_index))
		budget_left -= float(bruiser_count) * BRUISER_COST

	var chaff_count := int(floor((budget_left + 0.001) / CHAFF_COST))
	if chaff_count > 0:
		requests.insert(0, _spawn_request(ARCHETYPE_CHAFF, chaff_count, wave_index))

	return requests

func _bruiser_count_for_budget(budget: float, wave_index: int) -> int:
	if difficulty_tier < BRUISER_UNLOCK_TIER:
		return 0

	var max_bruisers := int(floor((budget + 0.001) / BRUISER_COST))
	if max_bruisers <= 0:
		return 0

	var tier_alpha := (difficulty_tier - BRUISER_UNLOCK_TIER) / (1.0 - BRUISER_UNLOCK_TIER)
	var bruiser_budget_share := lerpf(0.15, 0.55, tier_alpha)
	var desired := int(floor((budget * bruiser_budget_share + _rng.randf() * 0.6) / BRUISER_COST))
	if difficulty_tier >= 0.85 and wave_index > 0:
		desired = maxi(desired, 1)
	return clampi(desired, 0, max_bruisers)

func _prime_current_wave() -> void:
	_remaining_by_archetype.clear()
	_remaining_spawn_ids.clear()
	for request: Dictionary in current_spawn_requests():
		var archetype := String(request.get("archetype", ""))
		var count := int(request.get("count", 0))
		if archetype != "" and count > 0:
			_remaining_by_archetype[archetype] = int(_remaining_by_archetype.get(archetype, 0)) + count
			for spawn_id in request.get("spawn_ids", []):
				var normalized_id := String(spawn_id)
				if normalized_id != "":
					_remaining_spawn_ids[normalized_id] = archetype

func _advance_after_wave_dead() -> void:
	if _cleared:
		return

	var next_wave_index := current_wave_index + 1
	if next_wave_index < _waves.size():
		current_wave_index = next_wave_index
		_prime_current_wave()
		wave_requested.emit(current_wave_index, current_spawn_requests())
		return

	_cleared = true
	current_wave_index = _waves.size()
	_remaining_by_archetype.clear()
	_remaining_spawn_ids.clear()
	room_cleared.emit()

func _duplicate_requests(requests: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for request: Dictionary in requests:
		result.append(request.duplicate(true))
	return result

func _spawn_request(archetype: String, count: int, wave_index: int) -> Dictionary:
	var spawn_ids: Array[String] = []
	for ordinal in range(maxi(count, 0)):
		spawn_ids.append(_spawn_id(wave_index, archetype, ordinal))
	return {
		"archetype": archetype,
		"count": count,
		"spawn_ids": spawn_ids,
	}

func _spawn_id(wave_index: int, archetype: String, ordinal: int) -> String:
	return "w%d:%s:%d" % [wave_index, archetype, ordinal]

func _requests_cost(requests: Array[Dictionary]) -> float:
	var total := 0.0
	for request: Dictionary in requests:
		var archetype := String(request.get("archetype", ""))
		var count := int(request.get("count", 0))
		match archetype:
			ARCHETYPE_BRUISER:
				total += float(count) * BRUISER_COST
			ARCHETYPE_CHAFF:
				total += float(count) * CHAFF_COST
			_:
				pass
	return total

func _round_budget(value: float) -> float:
	return floor(value * 100.0 + 0.5) / 100.0
