extends SceneTree

# Headless tests for per-room encounter pressure.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_room_director_tests.gd

const RoomDirector := preload("res://scripts/room_graph/room_director.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running room director tests...")
	_test_tier_one_has_more_and_harder_budget_than_tier_zero()
	_test_wave_count_is_bounded_and_deterministic()
	_test_start_exposes_spawn_requests_as_plain_data()
	_test_kills_advance_one_wave_at_a_time()
	_test_over_and_under_reporting_are_safe()
	_test_room_cleared_emits_exactly_once()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL — %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks ⇒ room director failed to load/compile)" if _passed == 0 else ""]
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

func _seeded_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _make_director(tier: float, seed: int) -> RoomDirector:
	return RoomDirector.new(tier, _seeded_rng(seed))

func _test_tier_one_has_more_and_harder_budget_than_tier_zero() -> void:
	var low := _make_director(0.0, 90210)
	var high := _make_director(1.0, 90210)

	_check("tier 1.0 computes a larger room budget than tier 0.0", high.room_budget > low.room_budget)
	_check("tier 1.0 has at least as many waves as tier 0.0", high.wave_count >= low.wave_count)
	_check("tier 1.0 spends more encounter budget", high.spent_budget > low.spent_budget)
	_check("tier 1.0 leaves less than one chaff of unspent budget", high.unspent_budget() < RoomDirector.CHAFF_COST)
	_check_eq("tier 0.0 does not request bruisers", _total_archetype_count(low.planned_waves(), RoomDirector.ARCHETYPE_BRUISER), 0)
	_check("tier 1.0 requests bruisers", _total_archetype_count(high.planned_waves(), RoomDirector.ARCHETYPE_BRUISER) > 0)
	_check(
		"tier 1.0 requests at least as many bodies as tier 0.0",
		_total_request_count(high.planned_waves()) >= _total_request_count(low.planned_waves())
	)

func _test_wave_count_is_bounded_and_deterministic() -> void:
	for seed in range(1, 12):
		for tier in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var first := _make_director(tier, seed)
			var second := _make_director(tier, seed)
			_check("seed %d tier %.2f wave count is 1-3" % [seed, tier], first.wave_count >= 1 and first.wave_count <= 3)
			_check_eq("seed %d tier %.2f wave count is deterministic" % [seed, tier], first.wave_count, second.wave_count)
			_check_eq("seed %d tier %.2f wave plan is deterministic" % [seed, tier], first.planned_waves(), second.planned_waves())

func _test_start_exposes_spawn_requests_as_plain_data() -> void:
	var director := _make_director(0.65, 17)
	var requested_waves: Array[Dictionary] = []
	director.wave_requested.connect(func(wave_index: int, requests: Array[Dictionary]) -> void:
		requested_waves.append({"wave_index": wave_index, "requests": requests})
	)

	var first_wave := director.start()
	_check_eq("start begins at wave 0", director.current_wave_index, 0)
	_check_eq("start emits one wave request", requested_waves.size(), 1)
	_check_eq("wave_requested payload uses wave 0", int(requested_waves[0]["wave_index"]), 0)
	_check_eq("start return matches current_spawn_requests", first_wave, director.current_spawn_requests())
	_check("first wave exposes at least one spawn request", first_wave.size() > 0)

	for request: Dictionary in first_wave:
		_check("spawn request has archetype", request.has("archetype"))
		_check("spawn request has count", request.has("count"))
		_check("spawn request archetype stays abstract", [RoomDirector.ARCHETYPE_CHAFF, RoomDirector.ARCHETYPE_BRUISER].has(String(request["archetype"])))
		_check("spawn request count is positive", int(request["count"]) > 0)

func _test_kills_advance_one_wave_at_a_time() -> void:
	var director := _make_director(1.0, 42)
	var requested_wave_indices: Array[int] = []
	director.wave_requested.connect(func(wave_index: int, _requests: Array[Dictionary]) -> void:
		requested_wave_indices.append(wave_index)
	)
	director.start()
	_check_eq("high-tier director starts with three waves", director.wave_count, 3)
	_check_eq("only the first wave is requested on start", requested_wave_indices, [0])

	for expected_wave in range(director.wave_count):
		_check_eq("wave %d is active before its kills" % expected_wave, director.current_wave_index, expected_wave)
		var total_for_wave := director.remaining_in_wave()
		_check("wave %d starts with live enemies" % expected_wave, total_for_wave > 0)

		_kill_wave_until_one_remains(director)
		_check_eq("partial kills do not advance wave %d" % expected_wave, director.current_wave_index, expected_wave)
		_check_eq("partial kills leave exactly one enemy in wave %d" % expected_wave, director.remaining_in_wave(), 1)
		_kill_one_remaining(director)

		if expected_wave < director.wave_count - 1:
			_check_eq("final kill requests next wave after wave %d" % expected_wave, director.current_wave_index, expected_wave + 1)
			_check_eq("wave_requested emitted through wave %d" % (expected_wave + 1), requested_wave_indices.size(), expected_wave + 2)
		else:
			_check("final kill clears the room", director.is_room_cleared())

func _test_over_and_under_reporting_are_safe() -> void:
	var director := _make_director(0.0, 5)
	director.start()
	var initial_remaining := director.remaining_in_wave()

	_check_eq("unknown archetype kill is rejected", director.notify_kill("unknown"), false)
	_check_eq("wrong archetype kill is rejected", director.notify_kill(RoomDirector.ARCHETYPE_BRUISER), false)
	_check_eq("over-report attempts do not change remaining count", director.remaining_in_wave(), initial_remaining)

	var accepted := director.notify_kill(RoomDirector.ARCHETYPE_CHAFF)
	_check("valid chaff kill is accepted", accepted)
	_check_eq("one valid kill decrements by exactly one", director.remaining_in_wave(), initial_remaining - 1)
	_check_eq("under-reporting one kill does not clear the room", director.is_room_cleared(), false)

	_kill_current_wave(director)
	_check("room clears after the exact remaining kills", director.is_room_cleared())
	_check_eq("extra kill after clear is rejected", director.notify_kill(RoomDirector.ARCHETYPE_CHAFF), false)
	_check_eq("extra kill after clear leaves remaining at zero", director.remaining_in_wave(), 0)

func _test_room_cleared_emits_exactly_once() -> void:
	var director := _make_director(0.0, 123)
	var clear_events: Array[bool] = []
	director.room_cleared.connect(func() -> void:
		clear_events.append(true)
	)

	director.start()
	_kill_current_wave(director)
	_check("room_cleared flag is set", director.is_room_cleared())
	_check_eq("room_cleared emits once", clear_events.size(), 1)
	_check_eq("notify_kill after clear is ignored", director.notify_kill(RoomDirector.ARCHETYPE_CHAFF), false)
	_check_eq("room_cleared still emitted only once after over-report", clear_events.size(), 1)
	director.start()
	_check_eq("calling start after clear does not re-emit room_cleared", clear_events.size(), 1)

func _kill_current_wave(director: RoomDirector) -> void:
	while director.remaining_in_wave() > 0:
		_kill_one_remaining(director)

func _kill_wave_until_one_remains(director: RoomDirector) -> void:
	while director.remaining_in_wave() > 1:
		_kill_one_remaining(director)

func _kill_one_remaining(director: RoomDirector) -> void:
	var remaining := director.remaining_by_archetype()
	for archetype in remaining.keys():
		if int(remaining[archetype]) > 0:
			var accepted := director.notify_kill(String(archetype))
			_check("kill for %s is accepted" % String(archetype), accepted)
			return
	_check("test helper found a remaining kill target", false)

func _total_request_count(waves: Array[Array]) -> int:
	var total := 0
	for wave: Array in waves:
		for request: Dictionary in wave:
			total += int(request.get("count", 0))
	return total

func _total_archetype_count(waves: Array[Array], archetype: String) -> int:
	var total := 0
	for wave: Array in waves:
		for request: Dictionary in wave:
			if String(request.get("archetype", "")) == archetype:
				total += int(request.get("count", 0))
	return total
