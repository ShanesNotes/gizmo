extends SceneTree

# Headless integration tests for HZ-032 room transition orchestration.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_orchestrator_tests.gd

const RunScene := preload("res://scenes/run.tscn")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomDoorScript := preload("res://scripts/room_graph/room_door.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running run orchestrator tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_run_scene_auto_starts_with_default_pool()
	await _test_run_scene_instantiates_and_enters_room()
	await _test_full_boon_exit_cycle_reaches_boss_and_completes_run()
	await _test_enemy_damage_flows_through_guard_hp_and_stops_spawning_on_death()
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

func _test_full_boon_exit_cycle_reaches_boss_and_completes_run() -> void:
	var run = await _new_run()
	var loaded_room_ids: Array[String] = []
	var opened_batches: Array[Array] = []
	var completed_events: Array[bool] = []
	run.room_loaded.connect(func(room: RoomNode, _room_root: Node3D) -> void:
		loaded_room_ids.append(room.room_id)
	)
	run.doors_bound.connect(func(connections: Array[RoomConnection]) -> void:
		opened_batches.append(connections)
	)
	run.run_completed.connect(func() -> void:
		completed_events.append(true)
	)

	var graph = _start_run_with_first_boon_exit(run)
	loaded_room_ids.clear()
	loaded_room_ids.append(run.run_controller.current_room_id)
	var start_room_id: String = run.run_controller.current_room_id
	await _clear_current_room_by_director_kills(run)

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
	_check("boon draft records the picked boon", run.boon_draft.picked_boons.size() == 1)
	_check_eq("loaded rooms include entry and destination", loaded_room_ids, [start_room_id, next_room_id])
	_check_eq("destination template is boss for this small cycle", graph.get_room(next_room_id).template.room_type, RoomTemplate.RoomType.BOSS)

	await _clear_current_room_by_director_kills(run)

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

func _start_run_with_first_boon_exit(run) -> RoomGraph:
	for seed in range(1, 80):
		var graph: RoomGraph = run.start_run("hearth", _empty_template_pool(), 2, _seeded_rng(seed))
		var entry_connections := graph.get_connections_from(graph.entry_room_id)
		for connection in entry_connections:
			if run.run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON:
				return graph
	_check("found a seed whose first exit telegraphs BOON", false)
	return run.run_controller.graph

func _clear_current_room_by_director_kills(run) -> void:
	var safety := 0
	while run.current_director != null and not run.current_director.is_room_cleared() and safety < 20:
		var ids: Array[String] = run.current_director.remaining_spawn_ids()
		_check("current director exposes spawn ids to kill", not ids.is_empty())
		for spawn_id in ids:
			_check("notify_kill accepts %s" % spawn_id, run.current_director.notify_kill(spawn_id))
		await process_frame
		safety += 1
	_check("room cleared within safety limit", run.current_director == null or run.current_director.is_room_cleared())

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
