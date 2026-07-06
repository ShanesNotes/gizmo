extends SceneTree

# Headless integration tests for HZ-032 room transition orchestration.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_orchestrator_tests.gd

const RunScene := preload("res://scenes/run.tscn")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomDoorScript := preload("res://scripts/room_graph/room_door.gd")
const AttackAbilityScript := preload("res://scripts/abilities/attack_ability.gd")

const SURVIVAL_DT := 0.05
const SURVIVAL_RETREAT_SPEED := 4.0
const SURVIVAL_PLAYER_DPS_SCALE := 1.0

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running run orchestrator tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_run_scene_auto_starts_with_default_pool()
	await _test_run_scene_instantiates_and_enters_room()
	await _test_spawn_positions_respect_current_player_distance()
	await _test_spawn_positions_ignore_player_elevation()
	await _test_spawn_position_small_room_uses_farthest_valid_fallback()
	await _test_missing_spawn_bounds_warns_once_for_bare_room()
	await _test_full_boon_exit_cycle_reaches_boss_and_completes_run()
	await _test_enemy_damage_flows_through_guard_hp_and_stops_spawning_on_death()
	await _test_real_attack_damages_front_enemy_only_and_charges_spark()
	await _test_current_room_clears_through_real_attack_path()
	await _test_spark_surge_hits_living_enemies_once_and_empties_meter()
	await _test_spark_surge_skips_spawn_windup_enemies()
	await _test_real_combat_fills_gauge_and_spends_on_surge()
	await _test_spark_charge_persists_across_room_transition()
	await _test_rest_room_does_not_refill_spark_surge_charge()
	await _test_player_death_disconnects_director_and_ignores_posthumous_enemy_deaths()
	await _test_real_orchestrator_survivability_bands()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => run orchestrator failed to load/compile)" if _passed == 0 else ""]
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

func _check_almost(desc: String, actual: float, expected: float, margin: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, margin], absf(actual - expected) <= margin)

func _seeded_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _empty_template_pool() -> Array[RoomTemplate]:
	var pool: Array[RoomTemplate] = []
	return pool

func _new_run():
	var run = RunScene.instantiate()
	run.auto_start = false
	root.add_child(run)
	await process_frame
	return run

func _cleanup_run(run: Node) -> void:
	if run != null and is_instance_valid(run):
		run.queue_free()
	await process_frame

func _test_run_scene_auto_starts_with_default_pool() -> void:
	var run = RunScene.instantiate()
	root.add_child(run)
	await process_frame

	_check("default run scene auto-starts a graph", run.run_controller.graph != null)
	_check("default run scene enters an entry room", run.run_controller.current_room_id != "")
	_check("default run scene instantiates the current room", run.current_room_root != null)
	_check("default run scene spawns enemies from the director", run.spawned_enemy_count() > 0)
	await _cleanup_run(run)

func _test_run_scene_instantiates_and_enters_room() -> void:
	var run = await _new_run()
	var loaded_rooms: Array[RoomNode] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		loaded_rooms.append(room)
	)

	var graph = run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(1))
	await process_frame

	_check("run scene creates a graph", graph != null)
	_check("run scene keeps a RunController", run.run_controller != null)
	_check("run scene keeps a RoomCamera", run.camera != null)
	_check("run scene keeps the real player scene", run.player != null and run.player.is_in_group(&"player"))
	_check("run scene attaches PlayerVitals", run.player_vitals != null)
	_check_eq("entry room is current after start", run.run_controller.current_room_id, graph.entry_room_id)
	_check_eq("one room is loaded on start", loaded_rooms.size(), 1)
	_check("current room root is instanced", run.current_room_root != null)
	_check("player is placed at SpawnMarker", run.player.global_position.distance_to(_spawn_position(run.current_room_root)) < 0.001)
	_check("camera targets the player", run.camera.target == run.player)
	_check("director starts for the entered room", run.current_director != null)
	_check("director spawned at least one greybox enemy", run.spawned_enemy_count() > 0)
	_check("room doors are bound to RoomDoor behavior", _all_bound_doors_are_room_doors(run))
	await _cleanup_run(run)

func _test_spawn_positions_respect_current_player_distance() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var has_min_distance := _object_has_property(run, "min_spawn_distance")
	_check("orchestrator exposes min_spawn_distance", has_min_distance)
	var min_distance := 8.0
	if has_min_distance:
		min_distance = float(run.get("min_spawn_distance"))

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("spawn distance test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return

	run.player.global_position = anchor.global_position + Vector3(0.0, 0.0, 7.2)
	for index in range(12):
		var spawn_position: Vector3 = run._spawn_position_for(index)
		_check(
			"spawn %d is at least %.1fm from the current player" % [index, min_distance],
			_xz_distance(spawn_position, run.player.global_position) + 0.001 >= min_distance
		)

	await _cleanup_run(run)

func _test_spawn_positions_ignore_player_elevation() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("elevation spawn distance test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return

	run.min_spawn_distance = 4.0
	var first_ring_point := anchor.global_position + Vector3(run.min_spawn_distance, 0.0, 0.0)
	run.player.global_position = Vector3(first_ring_point.x, 5.0, first_ring_point.z)
	var spawn_position: Vector3 = run._spawn_position_for(0)

	_check(
		"spawn distance ignores player elevation and rejects a same-XZ candidate",
		_xz_distance(spawn_position, run.player.global_position) + 0.001 >= run.min_spawn_distance
	)

	await _cleanup_run(run)

func _test_spawn_position_small_room_uses_farthest_valid_fallback() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	_check("small-room fallback test has a room CameraAnchor", anchor != null)
	if anchor == null:
		await _cleanup_run(run)
		return

	anchor.set_meta("camera_half_extent_x", 2.0)
	anchor.set_meta("camera_half_extent_z", 2.0)
	run.player.global_position = anchor.global_position

	var first: Vector3 = run._spawn_position_for(1)
	var second: Vector3 = run._spawn_position_for(1)
	var local := first - anchor.global_position
	var distance := _xz_distance(first, run.player.global_position)

	_check("small-room fallback stays within authored X extent", absf(local.x) <= 2.001)
	_check("small-room fallback stays within authored Z extent", absf(local.z) <= 2.001)
	_check("small-room fallback is deterministic for the same index", first.distance_to(second) < 0.001)
	_check("small-room fallback is below the normal min distance because no point can satisfy it", distance < 8.0)
	_check("small-room fallback chooses the farthest valid point", absf(distance - sqrt(8.0)) < 0.01)

	await _cleanup_run(run)

func _test_missing_spawn_bounds_warns_once_for_bare_room() -> void:
	var run = await _new_run()
	var bare_room := Node3D.new()
	bare_room.name = "BareRoomWithoutCameraAnchor"
	run.rooms_root.add_child(bare_room)
	run.current_room_root = bare_room

	var before_count: int = _spawn_bounds_warning_count(run)
	run._spawn_position_for(0)
	var after_first_count: int = _spawn_bounds_warning_count(run)
	run._spawn_position_for(1)
	var after_second_count: int = _spawn_bounds_warning_count(run)

	_check("bare room spawn containment warning is recorded", after_first_count == before_count + 1)
	_check_eq("bare room spawn containment warning is once per room", after_second_count, after_first_count)

	await _cleanup_run(run)

func _test_full_boon_exit_cycle_reaches_boss_and_completes_run() -> void:
	var run = await _new_run()
	var loaded_room_ids: Array[String] = []
	var room_child_counts_at_load: Array[int] = []
	var opened_batches: Array[Array] = []
	var completed_events: Array[bool] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		loaded_room_ids.append(room.room_id)
		room_child_counts_at_load.append(run.rooms_root.get_child_count())
	)
	run.doors_bound.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	run.run_completed.connect(func() -> void:
		completed_events.append(true)
	)

	var graph = _start_run_with_first_boon_exit(run)
	loaded_room_ids.clear()
	room_child_counts_at_load.clear()
	loaded_room_ids.append(run.run_controller.current_room_id)
	var start_room_id: String = run.run_controller.current_room_id
	await _clear_current_room_by_enemy_deaths(run)

	_check_eq("first room becomes CLEARED after director kills", graph.get_room(start_room_id).state, RoomNode.State.CLEARED)
	_check_eq("doors open once after first clear", opened_batches.size(), 1)

	var boon_connection := _first_open_boon_connection(run, opened_batches[0])
	_check("opened doors include a BOON telegraph", boon_connection != null)
	if boon_connection == null:
		await _cleanup_run(run)
		return

	var door := run.bound_doors.get(boon_connection.door_name) as RoomDoor
	_check("BOON door is bound", door != null)
	_check_eq("BOON door telegraph reads destination reward", door.telegraph_data()[&"reward_type"], RoomNode.RewardType.BOON)
	var previous_room_root: Node3D = run.current_room_root

	door.emit_signal(&"body_entered", run.player)
	await process_frame

	_check("BOON exit opens a draft before transition", run.flow_bridge.is_draft_open())
	_check_eq("current room stays loaded while draft is open", run.current_room_root, previous_room_root)
	_check_eq("controller has not advanced before boon choice", run.run_controller.current_room_id, start_room_id)
	_check("real boon UI is visible for the draft", run.boon_draft_ui.visible)
	_check("real boon UI accepts a choice", run.boon_draft_ui.choose_offer(0))
	await process_frame

	var next_room_id: String = boon_connection.to_room_id
	_check_eq("BOON choice marks previous room REWARDED", graph.get_room(start_room_id).state, RoomNode.State.REWARDED)
	_check_eq("BOON choice advances the controller", run.run_controller.current_room_id, next_room_id)
	_check_eq("destination room is ENTERED", graph.get_room(next_room_id).state, RoomNode.State.ENTERED)
	_check("old room was replaced after exit completion", run.current_room_root != previous_room_root)
	var immediate_room_count := -1
	if not room_child_counts_at_load.is_empty():
		immediate_room_count = room_child_counts_at_load[room_child_counts_at_load.size() - 1]
	_check_eq("rooms root has exactly one room child immediately after exit completion", immediate_room_count, 1)
	_check("boon draft records the picked boon", run.boon_draft.picked_boons.size() == 1)
	_check_eq("loaded rooms include entry and destination", loaded_room_ids, [start_room_id, next_room_id])
	_check_eq("destination template is boss for this small cycle", graph.get_room(next_room_id).template.room_type, RoomTemplate.RoomType.BOSS)

	await _clear_current_room_by_enemy_deaths(run)

	_check_eq("boss clear emits run_completed once", completed_events.size(), 1)
	_check_eq("boss room is CLEARED, not REWARDED", graph.get_room(next_room_id).state, RoomNode.State.CLEARED)
	_check_eq("boss clear opens no additional doors", opened_batches.size(), 1)
	await _cleanup_run(run)

func _test_enemy_damage_flows_through_guard_hp_and_stops_spawning_on_death() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame
	var death_events: Array[bool] = []
	run.player_died.connect(func() -> void:
		death_events.append(true)
	)

	var enemy := _first_spawned_enemy(run)
	_check("death test has a spawned enemy", enemy != null)
	if enemy == null:
		await _cleanup_run(run)
		return

	var lethal_damage: int = int(run.player_vitals.max_guard) + int(run.player_vitals.max_hp)
	enemy.damage_event.emit({
		"damage": lethal_damage,
		"spawn_id": enemy.spawn_id,
		"archetype": enemy.archetype,
	})
	await process_frame

	_check_eq("enemy damage drains guard first", run.player_vitals.guard, 0)
	_check_eq("enemy damage drains hp to zero after guard", run.player_vitals.hp, 0)
	_check_eq("orchestrator surfaces player_died once", death_events.size(), 1)
	var count_after_death: int = run.spawned_enemy_count()
	run.current_director.wave_requested.emit(99, [
		{
			"archetype": "chaff",
			"count": 1,
			"spawn_ids": ["after_death_spawn"],
		},
	])
	await process_frame

	_check_eq("wave requests after death do not spawn more enemies", run.spawned_enemy_count(), count_after_death)
	_check("dead player leaves the run inactive", not run._run_active)
	await _cleanup_run(run)

func _test_real_attack_damages_front_enemy_only_and_charges_spark() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("real attack test has an AbilityComponent", kit != null)
	_check("real attack test has at least two enemies", enemies.size() >= 2)
	if kit == null or enemies.size() < 2:
		await _cleanup_run(run)
		return

	var front_enemy := enemies[0]
	var rear_enemy := enemies[1]
	_ready_enemy_for_player_attack(run, front_enemy, _player_forward(run) * 1.2)
	_ready_enemy_for_player_attack(run, rear_enemy, -_player_forward(run) * 1.2)
	front_enemy.max_hp = 100.0
	front_enemy.hp = 100.0
	rear_enemy.max_hp = 100.0
	rear_enemy.hp = 100.0
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.set("spark_damage_dealt_charge_rate", 1.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)

	var attack := kit.get_ability(&"attack") as AttackAbility
	var expected_damage := attack.damage_for_step(1) if attack != null else 0.0
	var front_before := front_enemy.hp
	var rear_before := rear_enemy.hp

	_check("real attack activates through the AbilityComponent", kit.try_activate(&"attack"))
	await process_frame

	_check_almost("front enemy takes the attack step damage", front_before - front_enemy.hp, expected_damage)
	_check_almost("rear enemy outside the forward arc is untouched", rear_before - rear_enemy.hp, 0.0)
	_check_almost("real dealt damage charges the Spark Surge meter", float(run.player_vitals.get("spark_surge_charge")), expected_damage)
	await _cleanup_run(run)

func _test_current_room_clears_through_real_attack_path() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	_check("real room-clear test has an AbilityComponent", kit != null)
	if kit == null:
		await _cleanup_run(run)
		return

	run.player_vitals.set("spark_surge_charge_max", 999.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)
	var room_id := String(run.run_controller.current_room_id)
	var cleared := await _clear_current_room_by_real_attacks(run)
	var room: RoomNode = run.run_controller.graph.get_room(room_id)

	_check("room clears through the real attack signal path", cleared)
	_check("run controller marks the melee-cleared room CLEARED", room != null and room.state == RoomNode.State.CLEARED)
	_check_eq("spawned enemy bookkeeping is empty after real attack clear", run.spawned_enemy_count(), 0)
	_check("real attack room clear charged the Spark Surge meter", float(run.player_vitals.get("spark_surge_charge")) > 0.0)
	await _cleanup_run(run)

func _test_spark_surge_hits_living_enemies_once_and_empties_meter() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	_check("run player kit exists for Spark Surge", kit != null)
	_check("run PlayerVitals can set Spark Surge charge", run.player_vitals != null and run.player_vitals.has_method("set_spark_surge_charge"))
	if kit == null or run.player_vitals == null or not run.player_vitals.has_method("set_spark_surge_charge"):
		await _cleanup_run(run)
		return
	_check("run player kit grants Spark Surge", kit.has_ability(&"surge"))
	var surge := kit.get_ability(&"surge")
	if surge == null:
		await _cleanup_run(run)
		return

	var enemies := _live_spawned_enemies(run)
	_check("Spark Surge test has living enemies", not enemies.is_empty())
	if enemies.is_empty():
		await _cleanup_run(run)
		return
	for enemy in enemies:
		_ready_enemy_for_player_attack(run, enemy, Vector3(1.0 + float(enemies.find(enemy)), 0.0, -1.0))
		enemy.max_hp = 100.0
		enemy.hp = 100.0

	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 100.0)
	var before_hp: Dictionary = {}
	for enemy in enemies:
		before_hp[enemy.spawn_id] = enemy.hp

	_check("full Spark Surge activates through player kit", kit.try_activate(&"surge"))
	await process_frame

	var expected_damage := float(surge.get("damage"))
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			_check("Spark Surge keeps toughened enemy instance valid", false)
			continue
		_check_almost(
			"Spark Surge damages %s exactly once" % enemy.spawn_id,
			float(before_hp[enemy.spawn_id]) - enemy.hp,
			expected_damage,
			0.001
		)
		_check("Spark Surge staggers %s" % enemy.spawn_id, enemy.brain.has_method("is_staggered") and bool(enemy.brain.call("is_staggered")))
	_check_almost("Spark Surge meter empties after burst", float(run.player_vitals.get("spark_surge_charge")), 0.0)
	await _cleanup_run(run)

func _test_spark_surge_skips_spawn_windup_enemies() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemy := _first_spawned_enemy(run)
	_check("spawn-windup Surge test has a kit", kit != null)
	_check("spawn-windup Surge test has an enemy", enemy != null)
	if kit == null or enemy == null:
		await _cleanup_run(run)
		return

	enemy.spawn_windup = 2.0
	enemy.configure(enemy.archetype, enemy.spawn_id)
	enemy.global_position = run.player.global_position + Vector3(0.8, 0.0, 0.0)
	enemy.max_hp = 10.0
	enemy.hp = 10.0
	var spawn_id := enemy.spawn_id
	var before_count: int = run.spawned_enemy_count()
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 100.0)

	_check("full Spark Surge activates with a windup enemy present", kit.try_activate(&"surge"))
	await process_frame

	_check("windup enemy remains in spawned-enemy bookkeeping after Surge", run.spawned_enemies.has(spawn_id))
	_check("director kill ledger still tracks the windup enemy", run.current_director.remaining_spawn_ids().has(spawn_id))
	_check_eq("windup Surge skip preserves spawned enemy count", run.spawned_enemy_count(), before_count)
	if is_instance_valid(enemy):
		_check_almost("windup enemy takes no Surge damage", enemy.hp, 10.0)
		_check("windup enemy is not staggered by Surge", not enemy.is_staggered())
	await _cleanup_run(run)

func _test_real_combat_fills_gauge_and_spends_on_surge() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame

	var kit: AbilityComponent = run._player_ability_kit()
	var enemies := _live_spawned_enemies(run)
	_check("real combat gauge test has a kit", kit != null)
	_check("real combat gauge test has at least two enemies", enemies.size() >= 2)
	if kit == null or enemies.size() < 2:
		await _cleanup_run(run)
		return

	var charge_target := enemies[0]
	var surge_target := enemies[1]
	_ready_enemy_for_player_attack(run, charge_target, _player_forward(run) * 1.2)
	_ready_enemy_for_player_attack(run, surge_target, Vector3(3.0, 0.0, 0.0))
	charge_target.max_hp = 100.0
	charge_target.hp = 100.0
	surge_target.max_hp = 100.0
	surge_target.hp = 100.0
	run.player_vitals.set("spark_surge_charge_max", 10.0)
	run.player_vitals.set("spark_damage_dealt_charge_rate", 1.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)

	_check("attack activates to fill the gauge through combat", kit.try_activate(&"attack"))
	await process_frame
	_check_almost("real attack fills the Spark Surge gauge", float(run.player_vitals.get("spark_surge_charge")), 10.0)
	kit.tick(1.0)

	var surge_before := surge_target.hp
	_check("full gauge activates Spark Surge after real combat charge", kit.try_activate(&"surge"))
	await process_frame
	_check("Spark Surge damages the non-melee-range target", surge_target.hp < surge_before)
	_check_almost("Spark Surge empties after real-combat fill", float(run.player_vitals.get("spark_surge_charge")), 0.0)
	await _cleanup_run(run)

func _test_spark_charge_persists_across_room_transition() -> void:
	var run = await _new_run()
	var graph = _start_run_with_first_boon_exit(run)
	await process_frame
	if run.player_vitals == null or not run.player_vitals.has_method("set_spark_surge_charge"):
		_check("run PlayerVitals can set Spark Surge charge for room persistence", false)
		await _cleanup_run(run)
		return

	var opened_batches: Array[Array] = []
	run.doors_bound.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	await _clear_current_room_by_enemy_deaths(run)
	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 42.0)
	var start_room_id: String = run.run_controller.current_room_id
	var boon_connection := _first_open_boon_connection(run, opened_batches[0])
	_check("room-persistence test found a BOON exit", boon_connection != null)
	if boon_connection == null:
		await _cleanup_run(run)
		return
	var door := run.bound_doors.get(boon_connection.door_name) as RoomDoor
	door.emit_signal(&"body_entered", run.player)
	await process_frame
	run.boon_draft_ui.choose_offer(0)
	await process_frame

	_check("room transition advanced", graph != null and run.run_controller.current_room_id != start_room_id)
	_check_almost("Spark Surge charge persists across room transition", float(run.player_vitals.get("spark_surge_charge")), 42.0)
	await _cleanup_run(run)

func _test_rest_room_does_not_refill_spark_surge_charge() -> void:
	var run = await _new_run()
	run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(5))
	await process_frame
	if run.player_vitals == null or not run.player_vitals.has_method("set_spark_surge_charge"):
		_check("run PlayerVitals can set Spark Surge charge before REST fixture", false)
		await _cleanup_run(run)
		return

	run.player_vitals.set("spark_surge_charge_max", 100.0)
	run.player_vitals.call("set_spark_surge_charge", 37.0)
	var rest_template := RoomTemplate.new()
	rest_template.room_type = RoomTemplate.RoomType.REST
	var rest_room := RoomNode.new()
	rest_room.room_id = "rest_probe"
	rest_room.template = rest_template
	run._start_room_director(rest_room)
	await process_frame

	_check_almost("REST room auto-clear does not refill Spark Surge charge", float(run.player_vitals.get("spark_surge_charge")), 37.0)
	await _cleanup_run(run)

func _test_player_death_disconnects_director_and_ignores_posthumous_enemy_deaths() -> void:
	var run = await _new_run()
	var graph: RoomGraph = null
	for seed in range(1, 120):
		graph = run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(seed))
		await process_frame
		if run.current_director != null and run.current_director.wave_count == 1 and run.spawned_enemy_count() > 0:
			break

	var director: RoomDirector = run.current_director
	_check("posthumous death test found a one-wave director", director != null and director.wave_count == 1)
	_check("posthumous death test has spawned enemies", run.spawned_enemy_count() > 0)
	if director == null or director.wave_count != 1 or run.spawned_enemy_count() == 0:
		await _cleanup_run(run)
		return

	var director_clears: Array[bool] = []
	var controller_clears: Array[RoomNode] = []
	director.room_cleared.connect(func() -> void:
		director_clears.append(true)
	)
	run.run_controller.room_cleared.connect(func(room: RoomNode) -> void:
		controller_clears.append(room)
	)

	var lethal_damage: int = int(run.player_vitals.max_guard) + int(run.player_vitals.max_hp)
	run.player_vitals.apply_damage(lethal_damage)
	await process_frame
	_check("posthumous death test leaves run inactive", not run._run_active)

	for enemy in _live_spawned_enemies(run):
		enemy.take_damage(maxf(enemy.hp, enemy.max_hp))
	await process_frame

	_check_eq("posthumous enemy deaths do not clear the stale director", director_clears.size(), 0)
	_check("stale director remains uncleared after ignored posthumous deaths", not director.is_room_cleared())
	_check_eq("posthumous enemy deaths do not notify run controller room_cleared", controller_clears.size(), 0)
	_check("posthumous enemy deaths do not crash the run", is_instance_valid(run))
	_check("posthumous death test kept graph alive for inspection", graph != null)
	await _cleanup_run(run)

func _test_real_orchestrator_survivability_bands() -> void:
	var stationary := await _run_survivability_probe(&"stationary", 90.0, 1)
	_check("motionless real-run probe eventually dies", bool(stationary["died"]))
	_check_between("motionless real-run death is not an instant spawn melt", float(stationary["survived_seconds"]), 20.0, 75.0)
	_check("motionless real-run damage stays chip-sized", int(stationary["max_hit_delta"]) <= 1)

	var retreating := await _run_survivability_probe(&"retreat", 12.0, 3)
	_check("retreating real-run DPS probe avoids death while clearing three rooms", not bool(retreating["died"]))
	_check_between("retreating real-run DPS clear time", float(retreating["survived_seconds"]), 2.0, 3.5)
	_check("retreating real-run enters at least three rooms", int(retreating["rooms_entered"]) >= 3)
	_check("retreating real-run clears at least three rooms", int(retreating["rooms_cleared"]) >= 3)
	_check("retreating real-run damage stays chip-sized", int(retreating["max_hit_delta"]) <= 1)

func _start_run_with_first_boon_exit(run) -> RoomGraph:
	for seed in range(1, 80):
		var graph: RoomGraph = run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(seed))
		var entry_connections := graph.get_connections_from(graph.entry_room_id)
		for connection in entry_connections:
			if run.run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON:
				return graph
	_check("found a seed whose first exit telegraphs BOON", false)
	return run.run_controller.graph

func _run_survivability_probe(profile: StringName, max_seconds: float, target_rooms: int) -> Dictionary:
	var run = await _new_run()
	var entered_room_ids: Array[String] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		entered_room_ids.append(room.room_id)
	)
	run.start_run("hearth", _empty_template_pool(), 8, _seeded_rng(70))
	await process_frame
	if entered_room_ids.is_empty() and run.run_controller.current_room_id != "":
		entered_room_ids.append(run.run_controller.current_room_id)

	var previous_total := _vital_total(run)
	var damage_events := 0
	var max_hit_delta := 0
	var first_damage := -1.0
	var elapsed := 0.0
	var melee_model := _survival_melee_model(run)

	while elapsed < max_seconds and run._run_active:
		if profile == &"retreat":
			_drive_retreating_player(run, SURVIVAL_DT)
			_tick_survival_melee(run, melee_model, SURVIVAL_DT)

		run._process(SURVIVAL_DT)
		if run.player_vitals != null:
			run.player_vitals.tick_guard_recharge(SURVIVAL_DT)
		_step_live_enemies(run, SURVIVAL_DT)

		elapsed += SURVIVAL_DT
		var total := _vital_total(run)
		if total < previous_total:
			damage_events += 1
			max_hit_delta = maxi(max_hit_delta, previous_total - total)
			if first_damage < 0.0:
				first_damage = elapsed
		previous_total = total

		if profile == &"retreat" and _current_room_is_cleared(run) and run._run_active:
			if run.rooms_cleared >= target_rooms:
				break
			if _current_room_has_exit(run):
				await _take_first_available_exit(run)
				previous_total = _vital_total(run)

	var result := {
		"died": not run._run_active and run.player_vitals != null and run.player_vitals.is_dead(),
		"survived_seconds": elapsed,
		"rooms_entered": entered_room_ids.size(),
		"rooms_cleared": run.rooms_cleared,
		"damage_events": damage_events,
		"max_hit_delta": max_hit_delta,
		"first_damage": first_damage,
		"melee_swings": int(melee_model["swings"]),
	}
	await _cleanup_run(run)
	return result

func _survival_melee_model(run) -> Dictionary:
	var kit: AbilityComponent = run._player_ability_kit()
	var attack := kit.get_ability(&"attack") as AttackAbility if kit != null else null
	if attack == null:
		attack = AttackAbilityScript.new()
	return {
		"attack": attack,
		"cooldown": 0.0,
		"combo_step": 0,
		"combo_remaining": 0.0,
		"swings": 0,
	}

func _tick_survival_melee(run, model: Dictionary, delta: float) -> void:
	var attack := model["attack"] as AttackAbility
	if attack == null:
		return

	model["cooldown"] = maxf(0.0, float(model["cooldown"]) - delta)
	model["combo_remaining"] = maxf(0.0, float(model["combo_remaining"]) - delta)
	if float(model["cooldown"]) > 0.0:
		return

	var target := _nearest_live_enemy(run)
	if target == null:
		return

	# DPS model uses the real default melee kit from godot/scripts/abilities/attack_ability.gd:
	# step_damage [18, 20, 26], step_recovery [0.16, 0.18, 0.24], combo_window 0.45.
	var current_step := int(model["combo_step"])
	if float(model["combo_remaining"]) <= 0.0:
		current_step = 0
	var next_step := (current_step % maxi(attack.combo_steps, 1)) + 1
	var damage := attack.damage_for_step(next_step)
	target.take_damage(damage)

	model["combo_step"] = next_step
	model["combo_remaining"] = attack.combo_window
	model["cooldown"] = maxf(attack.recovery_for_step(next_step) / maxf(SURVIVAL_PLAYER_DPS_SCALE, 0.001), SURVIVAL_DT)
	model["swings"] = int(model["swings"]) + 1

func _clear_current_room_by_real_attacks(run) -> bool:
	var kit: AbilityComponent = run._player_ability_kit()
	if kit == null:
		return false

	var safety := 0
	while run.current_director != null and not run.current_director.is_room_cleared() and safety < 60:
		var enemies := _live_spawned_enemies(run)
		if enemies.is_empty():
			await process_frame
			safety += 1
			continue

		var target := enemies[0]
		_ready_enemy_for_player_attack(run, target, _player_forward(run) * 1.1)
		if kit.try_activate(&"attack"):
			await process_frame
		kit.tick(1.0)
		await process_frame
		safety += 1

	return run.current_director == null or run.current_director.is_room_cleared()

func _ready_enemy_for_player_attack(run, enemy: GreyboxEnemy, offset: Vector3) -> void:
	if enemy == null:
		return
	var motor = run.player.get("motor") if run.player != null else null
	if motor != null:
		motor.set("facing_direction", _player_forward(run))
	while enemy.is_spawning():
		enemy.tick_chase(run.player.global_position, maxf(enemy.spawn_windup_remaining(), 0.1))
	enemy.global_position = run.player.global_position + offset
	enemy.velocity = Vector3.ZERO

func _player_forward(run) -> Vector3:
	var default_forward := Vector3(0.0, 0.0, -1.0)
	if run == null or run.player == null:
		return default_forward
	var motor = run.player.get("motor")
	if motor != null:
		var facing := Vector3(motor.get("facing_direction"))
		if facing.length_squared() > 0.000001:
			return facing.normalized()
	return default_forward

func _nearest_live_enemy(run) -> GreyboxEnemy:
	var nearest: GreyboxEnemy = null
	var nearest_distance := INF
	for enemy in _live_spawned_enemies(run):
		if enemy.is_dead():
			continue
		var distance := _xz_distance(enemy.global_position, run.player.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	return nearest

func _step_live_enemies(run, delta: float) -> void:
	for enemy in _live_spawned_enemies(run):
		if enemy.is_dead():
			continue
		var result: Dictionary = enemy.tick_chase(run.player.global_position, delta)
		var velocity := Vector3(result["velocity"])
		enemy.global_position += velocity * delta

func _drive_retreating_player(run, delta: float) -> void:
	var direction := _retreat_direction(run)
	var next_position: Vector3 = run.player.global_position + direction * SURVIVAL_RETREAT_SPEED * delta
	run.player.global_position = _clamp_to_current_room(run, next_position)
	run.player.velocity = Vector3.ZERO

func _retreat_direction(run) -> Vector3:
	var position: Vector3 = run.player.global_position
	var danger := Vector3.ZERO
	for enemy in _live_spawned_enemies(run):
		var away: Vector3 = position - enemy.global_position
		away.y = 0.0
		var distance := away.length()
		if distance > 0.05:
			danger += away / maxf(distance * distance, 0.25)

	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	if anchor != null:
		var half_x := float(anchor.get_meta("camera_half_extent_x", 6.0))
		var half_z := float(anchor.get_meta("camera_half_extent_z", 6.0))
		var margin := 1.4
		if position.x > anchor.global_position.x + half_x - margin:
			danger.x -= 2.5
		elif position.x < anchor.global_position.x - half_x + margin:
			danger.x += 2.5
		if position.z > anchor.global_position.z + half_z - margin:
			danger.z -= 2.5
		elif position.z < anchor.global_position.z - half_z + margin:
			danger.z += 2.5

	if danger.length_squared() <= 0.0001:
		return Vector3.RIGHT
	return danger.normalized()

func _clamp_to_current_room(run, position: Vector3) -> Vector3:
	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D
	if anchor == null:
		return position
	var half_x := maxf(float(anchor.get_meta("camera_half_extent_x", 6.0)) - 0.4, 0.5)
	var half_z := maxf(float(anchor.get_meta("camera_half_extent_z", 6.0)) - 0.4, 0.5)
	return Vector3(
		clampf(position.x, anchor.global_position.x - half_x, anchor.global_position.x + half_x),
		position.y,
		clampf(position.z, anchor.global_position.z - half_z, anchor.global_position.z + half_z)
	)

func _take_first_available_exit(run) -> void:
	var graph: RoomGraph = run.run_controller.graph
	var connections: Array[RoomConnection] = graph.get_connections_from(run.run_controller.current_room_id)
	_check("survivability helper has an exit to take", not connections.is_empty())
	if connections.is_empty():
		return
	var connection := connections[0]
	var door := run.bound_doors.get(connection.door_name) as RoomDoor
	if door == null:
		door = run.bound_doors.get("RoomExit") as RoomDoor
	_check("survivability helper found a bound exit door", door != null)
	if door == null:
		return

	var reward_type: int = run.run_controller.exit_reward_type(connection)
	door.emit_signal(&"body_entered", run.player)
	await process_frame
	if reward_type == RoomNode.RewardType.BOON and run.flow_bridge.is_draft_open():
		_check("survivability helper can accept boon exit draft", run.boon_draft_ui.choose_offer(0))
		await process_frame

func _current_room_is_cleared(run) -> bool:
	return run.current_director != null and run.current_director.is_room_cleared()

func _current_room_has_exit(run) -> bool:
	var graph: RoomGraph = run.run_controller.graph
	return graph != null and not graph.get_connections_from(run.run_controller.current_room_id).is_empty()

func _vital_total(run) -> int:
	if run.player_vitals == null:
		return 0
	return run.player_vitals.hp + run.player_vitals.guard

func _clear_current_room_by_enemy_deaths(run) -> void:
	var safety := 0
	while run.current_director != null and not run.current_director.is_room_cleared() and safety < 20:
		var enemies := _live_spawned_enemies(run)
		_check("current room exposes spawned enemies to kill", not enemies.is_empty())
		for enemy in enemies:
			enemy.take_damage(maxf(enemy.hp, enemy.max_hp))
		await process_frame
		safety += 1
	_check("room cleared within safety limit", run.current_director == null or run.current_director.is_room_cleared())
	if run.current_director != null and run.current_director.is_room_cleared():
		_check_eq("spawned enemy bookkeeping is empty after room clear", run.spawned_enemy_count(), 0)

func _first_open_boon_connection(run, connections: Array) -> RoomConnection:
	for connection in connections:
		if run.run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON:
			return connection
	return null

func _spawn_position(room_root: Node3D) -> Vector3:
	var marker := room_root.find_child("SpawnMarker", true, false) as Marker3D
	if marker == null:
		return Vector3.INF
	return marker.global_position

func _all_bound_doors_are_room_doors(run) -> bool:
	if run.bound_doors.is_empty():
		return false
	for door in run.bound_doors.values():
		if not (door is RoomDoor):
			return false
		if door.state != RoomDoorScript.State.SEALED:
			return false
	return true

func _first_spawned_enemy(run) -> GreyboxEnemy:
	for enemy in run.spawned_enemies.values():
		if enemy is GreyboxEnemy:
			return enemy as GreyboxEnemy
	return null

func _live_spawned_enemies(run) -> Array[GreyboxEnemy]:
	var enemies: Array[GreyboxEnemy] = []
	for enemy in run.spawned_enemies.values():
		if enemy is GreyboxEnemy and is_instance_valid(enemy):
			enemies.append(enemy as GreyboxEnemy)
	return enemies

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _spawn_bounds_warning_count(run) -> int:
	if not _object_has_property(run, "_spawn_bounds_warning_room_ids"):
		return 0
	var warnings: Dictionary = run.get("_spawn_bounds_warning_room_ids")
	return warnings.size()

func _object_has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
