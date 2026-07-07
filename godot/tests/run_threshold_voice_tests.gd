extends SceneTree

# Headless tests for RunOrchestrator threshold-address voice logic.
# Run with:
#   godot --headless --user-data-dir /tmp/godot-night-lore --path godot --script res://tests/run_threshold_voice_tests.gd

const RunOrchestratorScript := preload("res://scripts/room_graph/run_orchestrator.gd")
const RunScene := preload("res://scenes/run.tscn")
const RunControllerScript := preload("res://scripts/room_graph/run_controller.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomGraph := preload("res://scripts/room_graph/room_graph.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")

var _passed := 0
var _failed := 0

class CapturingAudioDirector:
	extends Node

	var voice_lines: Array[StringName] = []
	var zone_states: Array[StringName] = []
	var vitals_payloads: Array[Array] = []

	func play_voice_line(line_id: StringName) -> void:
		voice_lines.append(line_id)

	func set_zone_state(state: StringName) -> void:
		zone_states.append(state)

	func notify_vitals(guard: float, guard_max: float, hp: float, hp_max: float) -> void:
		vitals_payloads.append([guard, guard_max, hp, hp_max])

	func clear_voice_lines() -> void:
		voice_lines.clear()

func _initialize() -> void:
	print("Running threshold voice tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_region_change_speaks_once_until_region_changes()
	_test_pattern_door_speaks_once_when_boss_is_next()
	_test_vitals_drop_sets_damage_and_flawless_speaks_once_without_damage()
	_test_low_hp_clear_speaks_near_death_before_flawless()
	_test_reset_voice_run_state_rearms_region_and_milestones()
	await _test_missing_audio_director_noops_without_crash()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => threshold voice tests failed to load/compile)" if _passed == 0 else ""]
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

func _new_run(audio_director: Node = null):
	var run = RunOrchestratorScript.new()
	run.auto_start = false
	run.audio_director = audio_director
	run.player_vitals = PlayerVitalsScript.new()
	run.player_vitals.max_hp = 10
	run.player_vitals.hp = 10
	run.player_vitals.max_guard = 100
	run.player_vitals.guard = 100
	run._reset_voice_run_state()
	return run

func _make_template(template_id: String, room_type: RoomTemplate.RoomType) -> RoomTemplate:
	var template := RoomTemplate.new()
	template.template_id = template_id
	template.biome_id = "test_biome"
	template.room_type = room_type
	return template

func _make_room(
	room_id: String,
	room_type: RoomTemplate.RoomType = RoomTemplate.RoomType.COMBAT,
	region_id: String = "",
) -> RoomNode:
	var room := RoomNode.new()
	room.room_id = room_id
	room.template = _make_template("%s_template" % room_id, room_type)
	room.state = RoomNode.State.ENTERED
	room.reward_type = RoomNode.RewardType.BOON
	room.region_id = region_id
	return room

func _make_connection(from_room_id: String, to_room_id: String, door_name: String) -> RoomConnection:
	var connection := RoomConnection.new()
	connection.from_room_id = from_room_id
	connection.to_room_id = to_room_id
	connection.door_name = door_name
	return connection

func _attach_graph(run, current_room: RoomNode, next_rooms: Array[RoomNode] = []) -> void:
	var graph := RoomGraph.new()
	graph.biome_id = "test_biome"
	graph.entry_room_id = current_room.room_id
	graph.rooms.append(current_room)
	for i in range(next_rooms.size()):
		var next_room := next_rooms[i]
		graph.rooms.append(next_room)
		graph.connections.append(_make_connection(current_room.room_id, next_room.room_id, "Exit%d" % i))

	var controller = run.run_controller
	if controller == null:
		controller = RunControllerScript.new()
		run.run_controller = controller
	controller.graph = graph
	controller.current_room_id = current_room.room_id

func _line_strings(audio_director: CapturingAudioDirector) -> Array[String]:
	var result: Array[String] = []
	for line_id in audio_director.voice_lines:
		result.append(String(line_id))
	return result

func _run_flawless_clear(run) -> void:
	run._set_audio_zone_state(&"COMBAT")
	run._notify_audio_vitals()
	run._set_audio_zone_state(&"CLEARED")

func _test_region_change_speaks_once_until_region_changes() -> void:
	var audio_director := CapturingAudioDirector.new()
	var run = _new_run(audio_director)
	var hearth := _make_room("room_hearth", RoomTemplate.RoomType.COMBAT, "HEARTH")
	_attach_graph(run, hearth)

	run._notify_audio_room_entered(hearth)
	run._notify_audio_room_entered(hearth)
	_check_eq(
		"same region speaks one margin line",
		_line_strings(audio_director),
		["margin_region_hearth"]
	)

	var mist := _make_room("room_mist", RoomTemplate.RoomType.COMBAT, "LOWER_MIST")
	_attach_graph(run, mist)
	run._notify_audio_room_entered(mist)
	_check_eq(
		"second region change speaks the new region line",
		_line_strings(audio_director),
		["margin_region_hearth", "margin_region_lower_mist"]
	)
	_cleanup_bare_run(run, audio_director)

func _test_pattern_door_speaks_once_when_boss_is_next() -> void:
	var audio_director := CapturingAudioDirector.new()
	var run = _new_run(audio_director)
	var antechamber := _make_room("room_antechamber", RoomTemplate.RoomType.COMBAT, "PATTERN_GATE")
	var boss := _make_room("room_boss", RoomTemplate.RoomType.BOSS, "PATTERN_CORE")
	_attach_graph(run, antechamber, [boss])

	run._notify_audio_room_entered(antechamber)
	run._notify_audio_room_entered(antechamber)
	_check_eq(
		"boss-next entry speaks pattern_door once and suppresses first region line",
		_line_strings(audio_director),
		["pattern_door"]
	)
	_cleanup_bare_run(run, audio_director)

func _test_vitals_drop_sets_damage_and_flawless_speaks_once_without_damage() -> void:
	var audio_director := CapturingAudioDirector.new()
	var run = _new_run(audio_director)
	_attach_graph(run, _make_room("room_clear"))

	run._set_audio_zone_state(&"COMBAT")
	run._notify_audio_vitals()
	run.player_vitals.guard = 90
	run._notify_audio_vitals()
	_check("guard drop marks the room as damaged", bool(run.get("_voice_room_took_damage")))
	run._set_audio_zone_state(&"CLEARED")
	_check_eq("damaged clear does not speak flawless", _line_strings(audio_director), [])

	run._reset_voice_run_state()
	audio_director.clear_voice_lines()
	run.player_vitals.guard = run.player_vitals.max_guard
	run.player_vitals.hp = run.player_vitals.max_hp
	_run_flawless_clear(run)
	_check_eq("undamaged combat clear speaks flawless", _line_strings(audio_director), ["margin_flawless"])

	run._set_audio_zone_state(&"COMBAT")
	run._notify_audio_vitals()
	run._set_audio_zone_state(&"CLEARED")
	_check_eq("second flawless room is silent in the same run", _line_strings(audio_director), ["margin_flawless"])
	_cleanup_bare_run(run, audio_director)

func _test_low_hp_clear_speaks_near_death_before_flawless() -> void:
	var audio_director := CapturingAudioDirector.new()
	var run = _new_run(audio_director)
	_attach_graph(run, _make_room("room_low_hp"))
	run.player_vitals.max_hp = 10
	run.player_vitals.hp = 2
	run.player_vitals.guard = run.player_vitals.max_guard

	_run_flawless_clear(run)
	_check_eq(
		"hp at 20 percent speaks near-death instead of flawless",
		_line_strings(audio_director),
		["margin_near_death"]
	)

	run._set_audio_zone_state(&"COMBAT")
	run._notify_audio_vitals()
	run._set_audio_zone_state(&"CLEARED")
	_check_eq(
		"near-death milestone stays once; later undamaged clear can still speak flawless",
		_line_strings(audio_director),
		["margin_near_death", "margin_flawless"]
	)
	_cleanup_bare_run(run, audio_director)

func _test_reset_voice_run_state_rearms_region_and_milestones() -> void:
	var audio_director := CapturingAudioDirector.new()
	var run = _new_run(audio_director)
	var room := _make_room("room_reset", RoomTemplate.RoomType.COMBAT, "HEARTH")
	_attach_graph(run, room)

	run._notify_audio_room_entered(room)
	_run_flawless_clear(run)
	_check_eq(
		"pre-reset region and flawless lines fire once",
		_line_strings(audio_director),
		["margin_region_hearth", "margin_flawless"]
	)

	run._reset_voice_run_state()
	audio_director.clear_voice_lines()
	run._notify_audio_room_entered(room)
	_run_flawless_clear(run)
	_check_eq(
		"reset re-arms region and flawless milestones",
		_line_strings(audio_director),
		["margin_region_hearth", "margin_flawless"]
	)
	_cleanup_bare_run(run, audio_director)

func _cleanup_bare_run(run, audio_director: Node = null) -> void:
	if run != null and is_instance_valid(run):
		var controller = run.run_controller
		var vitals = run.player_vitals
		run.run_controller = null
		run.player_vitals = null
		run.audio_director = null
		run.free()
		if controller != null and is_instance_valid(controller) and not controller.is_inside_tree():
			controller.free()
		if vitals != null and is_instance_valid(vitals) and not vitals.is_inside_tree():
			vitals.free()
	if audio_director != null and is_instance_valid(audio_director) and not audio_director.is_inside_tree():
		audio_director.free()

func _test_missing_audio_director_noops_without_crash() -> void:
	var autoload := root.get_node_or_null("AudioDirector")
	if autoload != null:
		root.remove_child(autoload)

	var run = RunScene.instantiate()
	run.auto_start = false
	root.add_child(run)
	await process_frame
	run.audio_director = null
	var room := _make_room("room_no_audio", RoomTemplate.RoomType.COMBAT, "HEARTH")
	_attach_graph(run, room)

	run._notify_audio_room_entered(room)
	run._notify_audio_vitals()
	run._set_audio_zone_state(&"COMBAT")
	run._set_audio_zone_state(&"CLEARED")
	run._reset_voice_run_state()
	_check("missing audio director leaves threshold calls as no-ops", run.audio_director == null)
	run.queue_free()
	await process_frame
	if autoload != null and is_instance_valid(autoload):
		root.add_child(autoload)
