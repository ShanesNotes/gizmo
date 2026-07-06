extends SceneTree

# Headless tests for per-room encounter pressure.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_room_director_tests.gd

const RoomDirector := preload("res://scripts/room_graph/room_director.gd")
const EnemyArchetypesScript := preload("res://scripts/enemies/enemy_archetypes.gd")
const AttackAbilityScript := preload("res://scripts/abilities/attack_ability.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running room director tests...")
	_test_tier_one_has_more_and_harder_budget_than_tier_zero()
	_test_combat_room_budget_estimates_scale_by_tier()
	_test_elite_room_budget_requests_punctuation_enemy()
	_test_high_tier_elite_room_ends_with_double_elite_seed_sweep()
	_test_tier_zero_opening_pressure_is_capped_across_seed_sweep()
	_test_wave_count_is_bounded_and_deterministic()
	_test_planned_waves_never_empty_across_seed_sweep()
	_test_start_exposes_spawn_requests_as_plain_data()
	_test_kills_advance_one_wave_at_a_time()
	_test_spawn_id_kill_reports_are_deduped()
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

func _check_between(desc: String, value: float, low: float, high: float) -> void:
	_check("%s (%.2f in [%.2f, %.2f])" % [desc, value, low, high], value >= low and value <= high)

func _seeded_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _make_director(tier: float, seed: int) -> RoomDirector:
	return RoomDirector.new(tier, _seeded_rng(seed))

func _make_director_for_kind(tier: float, seed: int, room_kind: String) -> RoomDirector:
	return RoomDirector.new(tier, _seeded_rng(seed), room_kind)

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

func _test_combat_room_budget_estimates_scale_by_tier() -> void:
	var low := _make_director(0.0, 90210)
	var mid := _make_director(0.5, 90210)
	var high := _make_director(1.0, 90210)

	var low_seconds := _estimated_room_clear_seconds(low.planned_waves())
	var mid_seconds := _estimated_room_clear_seconds(mid.planned_waves())
	var high_seconds := _estimated_room_clear_seconds(high.planned_waves())

	_check_between("tier 0.0 combat estimate is an opening-room bite", low_seconds, 1.5, 5.0)
	_check_between("tier 0.5 combat estimate is a real room", mid_seconds, 6.0, 14.0)
	_check_between("tier 1.0 combat estimate approaches Hades room pacing before movement tax", high_seconds, 12.0, 24.0)
	_check("combat estimates scale upward by tier", low_seconds < mid_seconds and mid_seconds < high_seconds)
	_check_eq("combat directors do not spend elite budget", _total_archetype_count(high.planned_waves(), "elite"), 0)

func _test_elite_room_budget_requests_punctuation_enemy() -> void:
	var combat := _make_director(0.65, 17)
	var elite := _make_director_for_kind(0.65, 17, RoomDirector.ROOM_KIND_ELITE)

	_check("elite room computes a larger budget than same-tier combat", elite.room_budget > combat.room_budget)
	_check("elite room spends more budget than same-tier combat", elite.spent_budget > combat.spent_budget)
	_check_eq("same-tier combat room requests no elites", _total_archetype_count(combat.planned_waves(), RoomDirector.ARCHETYPE_ELITE), 0)
	_check("elite room requests at least one elite", _total_archetype_count(elite.planned_waves(), RoomDirector.ARCHETYPE_ELITE) >= 1)
	_check(
		"elite room estimated clear time is noticeably harder than combat",
		_estimated_room_clear_seconds(elite.planned_waves()) >= _estimated_room_clear_seconds(combat.planned_waves()) * 1.35
	)

func _test_high_tier_elite_room_ends_with_double_elite_seed_sweep() -> void:
	var misses: Array[String] = []
	for seed in range(1, 51):
		for tier in [RoomDirector.ELITE_DOUBLE_TIER, 1.0]:
			var director := _make_director_for_kind(tier, seed, RoomDirector.ROOM_KIND_ELITE)
			var waves := director.planned_waves()
			var final_wave: Array = []
			if not waves.is_empty():
				final_wave = waves[waves.size() - 1]
			var final_elites := _wave_archetype_count(final_wave, RoomDirector.ARCHETYPE_ELITE)
			if final_elites != 2:
				misses.append("seed %d tier %.2f final_elites %d" % [seed, tier, final_elites])

	_check_eq("high-tier elite seed sweep ends on a double-elite final wave", misses.size(), 0)

func _test_tier_zero_opening_pressure_is_capped_across_seed_sweep() -> void:
	const OPENING_PRESSURE_CAP := 3
	const OPENING_TOTAL_FLOOR := 4
	const OPENING_TOTAL_CEILING := 6
	const OPENING_WAVE_CEILING := 2
	var over_cap_seeds: Array[int] = []
	var over_wave_count_seeds: Array[int] = []
	var outside_total_band: Array[String] = []
	var lowest_first_wave := 999
	var highest_first_wave := 0

	for seed in range(1, 101):
		var director := _make_director(0.0, seed)
		var waves := director.planned_waves()
		var total_count := _total_request_count(waves)
		if director.wave_count > OPENING_WAVE_CEILING:
			over_wave_count_seeds.append(seed)
		if total_count < OPENING_TOTAL_FLOOR or total_count > OPENING_TOTAL_CEILING:
			outside_total_band.append("seed %d total %d" % [seed, total_count])
		var first_wave_count := _wave_request_count(waves[0]) if not waves.is_empty() else 0
		lowest_first_wave = mini(lowest_first_wave, first_wave_count)
		highest_first_wave = maxi(highest_first_wave, first_wave_count)
		for wave in waves:
			if _wave_request_count(wave) > OPENING_PRESSURE_CAP:
				over_cap_seeds.append(seed)
				break

	_check_eq("tier-0 seed sweep has no wave over the opening pressure cap", over_cap_seeds.size(), 0)
	_check_eq("tier-0 seed sweep caps total waves at two", over_wave_count_seeds.size(), 0)
	_check_eq("tier-0 seed sweep keeps total enemies in the warm-up band", outside_total_band.size(), 0)
	_check_between("tier-0 first wave keeps the Hades chamber pressure floor", float(lowest_first_wave), 2.0, 4.0)
	_check_between("tier-0 first wave keeps the Hades chamber pressure ceiling", float(highest_first_wave), 2.0, 4.0)

func _test_wave_count_is_bounded_and_deterministic() -> void:
	for seed in range(1, 12):
		for tier in [0.0, 0.15, 0.25, 0.5, 0.75, 1.0]:
			var first := _make_director(tier, seed)
			var second := _make_director(tier, seed)
			var max_waves := 2 if tier <= 0.15 else 3
			_check("seed %d tier %.2f wave count respects tier ceiling" % [seed, tier], first.wave_count >= 1 and first.wave_count <= max_waves)
			_check_eq("seed %d tier %.2f wave count is deterministic" % [seed, tier], first.wave_count, second.wave_count)
			_check_eq("seed %d tier %.2f wave plan is deterministic" % [seed, tier], first.planned_waves(), second.planned_waves())

func _test_planned_waves_never_empty_across_seed_sweep() -> void:
	for seed in range(1, 101):
		for tier in [0.0, 0.5, 1.0]:
			for room_kind in [RoomDirector.ROOM_KIND_COMBAT, RoomDirector.ROOM_KIND_ELITE]:
				var director := _make_director_for_kind(tier, seed, room_kind)
				var waves := director.planned_waves()
				for wave_index in range(waves.size()):
					var wave: Array = waves[wave_index]
					_check(
						"seed %d tier %.1f %s wave %d has at least one planned spawn"
						% [seed, tier, room_kind, wave_index],
						_wave_request_count(wave) > 0
					)

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
		_check("spawn request has spawn_ids", request.has("spawn_ids"))
		_check("spawn request archetype stays abstract", [
			RoomDirector.ARCHETYPE_CHAFF,
			RoomDirector.ARCHETYPE_BRUISER,
			"elite",
		].has(String(request["archetype"])))
		_check("spawn request count is positive", int(request["count"]) > 0)
		var spawn_ids: Array = request.get("spawn_ids", [])
		_check_eq("spawn request ids match count", spawn_ids.size(), int(request["count"]))
		for spawn_id in spawn_ids:
			_check("spawn id is non-empty", String(spawn_id) != "")
			_check("spawn id includes wave index", String(spawn_id).begins_with("w0:"))
			_check("spawn id includes archetype", String(spawn_id).contains(":%s:" % String(request["archetype"])))

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

func _test_spawn_id_kill_reports_are_deduped() -> void:
	var director := _make_director(1.0, 42)
	director.start()
	var initial_remaining := director.remaining_in_wave()
	var first_spawn_id := _first_live_spawn_id(director)
	_check("dedup test has a live spawn id", first_spawn_id != "")
	if first_spawn_id == "":
		return

	_check("first report for spawn id is accepted", director.notify_kill(first_spawn_id))
	_check_eq("first spawn-id report decrements once", director.remaining_in_wave(), initial_remaining - 1)
	_check_eq("duplicate spawn-id report is rejected", director.notify_kill(first_spawn_id), false)
	_check_eq("duplicate spawn-id report does not double decrement", director.remaining_in_wave(), initial_remaining - 1)
	_check_eq("duplicate spawn-id report does not advance while wave is still live", director.current_wave_index, 0)
	_check_eq("unknown spawn id is rejected safely", director.notify_kill("missing:spawn:id"), false)
	_check_eq("unknown spawn id leaves remaining unchanged", director.remaining_in_wave(), initial_remaining - 1)

func _test_over_and_under_reporting_are_safe() -> void:
	var director := _make_director(0.0, 5)
	director.start()
	var initial_remaining := director.remaining_in_wave()

	_check_eq("unknown spawn id kill is rejected", director.notify_kill("unknown"), false)
	_check_eq("archetype string is not accepted as a spawn id", director.notify_kill(RoomDirector.ARCHETYPE_CHAFF), false)
	_check_eq("over-report attempts do not change remaining count", director.remaining_in_wave(), initial_remaining)

	var accepted := director.notify_kill(_first_live_spawn_id(director))
	_check("valid spawn id kill is accepted", accepted)
	_check_eq("one valid kill decrements by exactly one", director.remaining_in_wave(), initial_remaining - 1)
	_check_eq("under-reporting one kill does not clear the room", director.is_room_cleared(), false)

	_kill_current_wave(director)
	_check("room clears after the exact remaining kills", director.is_room_cleared())
	_check_eq("extra kill after clear is rejected", director.notify_kill("already:clear"), false)
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
	_check_eq("notify_kill after clear is ignored", director.notify_kill("after:clear"), false)
	_check_eq("room_cleared still emitted only once after over-report", clear_events.size(), 1)
	director.start()
	_check_eq("calling start after clear does not re-emit room_cleared", clear_events.size(), 1)

func _kill_current_wave(director: RoomDirector) -> void:
	while director.remaining_in_wave() > 0:
		if not _kill_one_remaining(director):
			return

func _kill_wave_until_one_remains(director: RoomDirector) -> void:
	while director.remaining_in_wave() > 1:
		if not _kill_one_remaining(director):
			return

func _kill_one_remaining(director: RoomDirector) -> bool:
	var spawn_id := _first_live_spawn_id(director)
	if spawn_id == "":
		_check("test helper found a remaining spawn id", false)
		return false
	var accepted := director.notify_kill(spawn_id)
	_check("kill for %s is accepted" % spawn_id, accepted)
	return accepted

func _total_request_count(waves: Array[Array]) -> int:
	var total := 0
	for wave: Array in waves:
		total += _wave_request_count(wave)
	return total

func _total_archetype_count(waves: Array[Array], archetype: String) -> int:
	var total := 0
	for wave: Array in waves:
		for request: Dictionary in wave:
			if String(request.get("archetype", "")) == archetype:
				total += int(request.get("count", 0))
	return total

func _estimated_room_clear_seconds(waves: Array[Array]) -> float:
	var hp_total := 0.0
	for wave: Array in waves:
		for request: Dictionary in wave:
			var archetype := String(request.get("archetype", ""))
			if not EnemyArchetypesScript.has_archetype(archetype):
				continue
			var stats := EnemyArchetypesScript.stats_for(archetype)
			hp_total += float(stats["max_hp"]) * float(int(request.get("count", 0)))
	return hp_total / _sustained_melee_dps()

func _sustained_melee_dps() -> float:
	var attack := AttackAbilityScript.new()
	var damage := 0.0
	var recovery := 0.0
	for step in range(1, attack.combo_steps + 1):
		damage += attack.damage_for_step(step)
		recovery += attack.recovery_for_step(step)
	return damage / maxf(recovery, 0.001)

func _wave_request_count(wave: Array) -> int:
	var total := 0
	for request: Dictionary in wave:
		total += int(request.get("count", 0))
	return total

func _wave_archetype_count(wave: Array, archetype: String) -> int:
	var total := 0
	for request: Dictionary in wave:
		if String(request.get("archetype", "")) == archetype:
			total += int(request.get("count", 0))
	return total

func _first_live_spawn_id(director: RoomDirector) -> String:
	if not director.has_method("remaining_spawn_ids"):
		return ""
	var remaining_ids: Array = director.call("remaining_spawn_ids")
	if remaining_ids.is_empty():
		return ""
	return String(remaining_ids[0])
