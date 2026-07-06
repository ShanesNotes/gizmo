extends SceneTree

# Full real-scene HZ-061 ship gate.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_integration_gate_tests.gd

const AppScene := preload("res://scenes/app.tscn")
const AppShellScript := preload("res://scripts/app_shell.gd")
const HubControllerScript := preload("res://scripts/hub_controller.gd")
const RunOrchestratorScript := preload("res://scripts/room_graph/run_orchestrator.gd")
const AttackAbilityScript := preload("res://scripts/abilities/attack_ability.gd")
const RoomDirectorScript := preload("res://scripts/room_graph/room_director.gd")
const BoonDef := preload("res://scripts/boons/boon_def.gd")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")

const EXPECTED_MAIN_SCENE := "res://scenes/app.tscn"
const EXPECTED_RUN_SCENE := "res://scenes/run.tscn"
const SCRAP_REWARD_VALUE := 10
const SPAWN_SEPARATION_DISTANCE := 1.1
const TEST_SAVE_SUBDIR := "saves"

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running full-run integration gate tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_save_root_is_user_scoped()
	await _test_empty_boon_pool_replacement_reward_in_real_run()
	await _test_live_enemy_ttk_texture_uses_real_attack_scale()
	await _test_real_elite_room_clears_through_live_attack_dps()
	await _test_victory_run_returns_to_hub_with_summary_and_persisted_scrap()
	await _test_death_run_returns_to_hub_with_summary_and_persisted_scrap()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => integration gate failed to load/compile)" if _passed == 0 else ""]
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

func _test_save_root_is_user_scoped() -> void:
	_ensure_test_save_root()
	var save_root := _test_save_root()
	var user_data_dir := _requested_user_data_dir()
	_check("integration test save root is absolute", save_root.is_absolute_path())
	_check("integration test save root resolves under the requested user data dir", save_root.begins_with(user_data_dir))

func _test_victory_run_returns_to_hub_with_summary_and_persisted_scrap() -> void:
	var save_path := _new_save_path("victory")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	_check_eq("project main scene points at app.tscn", ProjectSettings.get_setting("application/run/main_scene"), EXPECTED_MAIN_SCENE)
	_check("AppShell default run surface is real run.tscn", app.run_surface_scene != null and app.run_surface_scene.resource_path == EXPECTED_RUN_SCENE)
	_check("boot content is the hub", _current_hub(app) != null)

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var gate := _new_gate_state(run)
	await _drive_run_to_victory(run, gate)
	await _flush_frames(2)

	var returned_hub := _current_hub(app)
	var screen := _summary_screen(app)
	var loaded: MetaState = MetaState.load_from_path(save_path)

	_check("victory returns content to hub", returned_hub != null and returned_hub.get_script() == HubControllerScript)
	_check("victory summary overlay is visible above hub", _summary_visible(screen))
	_check_eq("victory flag is true", app.last_run_summary.get("victory", false), true)
	_check_eq("victory rooms_cleared summary matches driven rooms", int(app.last_run_summary.get("rooms_cleared", -1)), gate["cleared_room_ids"].size())
	_check_eq("victory boons_taken summary matches draft picks", int(app.last_run_summary.get("boons_taken", -1)), int(gate["boons_taken"]))
	_check_eq("victory scrap summary matches accepted SCRAP rewards", int(app.last_run_summary.get("scrap_banked", -1)), int(gate["scrap_earned"]))
	_check("victory elapsed is recorded", float(app.last_run_summary.get("survived_seconds", 0.0)) > 0.0)
	_check("victory path clears multiple rooms", gate["cleared_room_ids"].size() >= 2)
	_check("victory path included a boon draft pick", int(gate["boons_taken"]) >= 1)
	_check("victory path included bankable Scrap", int(gate["scrap_earned"]) > 0)
	_assert_summary_labels(screen, app.last_run_summary, "victory")
	_check_eq("victory save persists banked scrap", loaded.scrap_banked, int(gate["scrap_earned"]))
	_check_eq("victory hub scrap label reflects persisted bank", _hub_scrap_label(returned_hub), "SCRAP %d" % int(gate["scrap_earned"]))

	await _dismiss_summary_and_assert_hub(app, screen, "victory")
	await _cleanup_app(app, save_path)

func _test_empty_boon_pool_replacement_reward_in_real_run() -> void:
	var save_path := _new_save_path("empty_boon_pool")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return
	var empty_pool: Array[BoonDef] = []
	run.flow_bridge.set_boon_pool(empty_pool)

	var gate := _new_gate_state(run)
	var connection: RoomConnection = null
	var safety := 0
	while is_instance_valid(run) and run._run_active and safety < 10:
		await _clear_current_room_by_enemy_deaths(run, gate)
		connection = _select_progress_connection(run, true, false)
		if connection == null:
			break
		if run.run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON:
			break
		await _take_exit(run, connection, gate)
		safety += 1

	_check("empty-pool integration found a BOON exit", connection != null and run.run_controller.exit_reward_type(connection) == RoomNode.RewardType.BOON)
	if connection == null or run.run_controller.exit_reward_type(connection) != RoomNode.RewardType.BOON:
		await _cleanup_app(app, save_path)
		return

	var previous_scrap: int = run.scrap_earned
	var destination_id := connection.to_room_id
	var door := run.bound_doors.get(connection.door_name) as RoomDoor
	_check("empty-pool BOON exit has a real bound door", door != null)
	if door != null:
		door.emit_signal(&"body_entered", run.player)
		await process_frame

	_check("empty-pool BOON exit skips the draft overlay", not run.flow_bridge.is_draft_open() and not run.boon_draft_ui.visible)
	_check_eq("empty-pool BOON exit grants Scrap replacement", run.scrap_earned, previous_scrap + SCRAP_REWARD_VALUE)
	_check_eq("empty-pool BOON exit advances to its destination", run.run_controller.current_room_id, destination_id)
	await _cleanup_app(app, save_path)

func _test_live_enemy_ttk_texture_uses_real_attack_scale() -> void:
	var save_path := _new_save_path("live_ttk_texture")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var attack := AttackAbilityScript.new()
	var enemy := _first_spawned_enemy(run)
	_check("live TTK texture test has a real spawned enemy", enemy != null)
	if enemy != null:
		var ttk := _melee_ttk_for_hp(enemy.max_hp, attack)
		_check_eq("first live enemy is entry-room chaff", enemy.archetype, "chaff")
		_check("first live chaff survives the opening melee hit", enemy.max_hp > attack.damage_for_step(1))
		_check_between("first live chaff remains in trash TTK band", float(ttk["seconds"]), 0.0, 0.5)
		_check_eq("first live chaff takes two real melee hits", int(ttk["hits"]), 2)
	_assert_spawned_enemies_inside_current_room_bounds(run, "integration live TTK texture")
	await _cleanup_app(app, save_path)

func _test_real_elite_room_clears_through_live_attack_dps() -> void:
	var save_path := _new_save_path("elite_room_live_dps")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var graph: RoomGraph = run.run_controller.graph
	var elite_room_id := _first_room_id_by_type(graph, RoomTemplate.RoomType.ELITE)
	_check("elite integration graph includes a real ELITE room", elite_room_id != "")
	if elite_room_id == "":
		await _cleanup_app(app, save_path)
		return

	var gate := _new_gate_state(run)
	var reached_elite := await _drive_to_room(run, elite_room_id, gate)
	_check("elite integration drive reaches the ELITE room", reached_elite)
	if not reached_elite:
		await _cleanup_app(app, save_path)
		return

	var elite_room := graph.get_room(elite_room_id)
	_check("current room is the generated ELITE template", elite_room != null and elite_room.template != null and elite_room.template.room_type == RoomTemplate.RoomType.ELITE)
	_check("ELITE template starts an elite director", run.current_director != null and run.current_director.room_kind == RoomDirectorScript.ROOM_KIND_ELITE)

	var clear_result := await _clear_current_room_by_real_attack_dps(run)
	_check("real attack DPS killed at least one live elite", int(clear_result["elite_kills"]) >= 1)
	_check_between("real attack DPS elite TTK lands in the 3-10s band", float(clear_result["first_elite_ttk"]), 3.0, 10.0)
	_check("real attack DPS clears the elite room", run.current_director != null and run.current_director.is_room_cleared())
	_check("RunController marks the elite room cleared", elite_room != null and elite_room.state == RoomNode.State.CLEARED)
	await _cleanup_app(app, save_path)

func _test_death_run_returns_to_hub_with_summary_and_persisted_scrap() -> void:
	var save_path := _new_save_path("death")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var gate := _new_gate_state(run)
	await _drive_until_scrap_reward(run, gate)
	_check("death scenario earned Scrap before dying", int(gate["scrap_earned"]) > 0)

	var enemy := _first_spawned_enemy(run)
	_check("death scenario has a real spawned enemy", enemy != null)
	if enemy != null:
		var lethal_damage: int = int(run.player_vitals.max_guard) + int(run.player_vitals.max_hp)
		enemy.damage_event.emit({
			"damage": lethal_damage,
			"spawn_id": enemy.spawn_id,
			"archetype": enemy.archetype,
		})
	await _flush_frames(2)

	var returned_hub := _current_hub(app)
	var screen := _summary_screen(app)
	var loaded: MetaState = MetaState.load_from_path(save_path)

	_check("death returns content to hub", returned_hub != null and returned_hub.get_script() == HubControllerScript)
	_check("death summary overlay is visible above hub", _summary_visible(screen))
	_check_eq("death flag is false", app.last_run_summary.get("victory", true), false)
	_check_eq("death rooms_cleared summary matches driven rooms", int(app.last_run_summary.get("rooms_cleared", -1)), gate["cleared_room_ids"].size())
	_check_eq("death boons_taken summary matches draft picks", int(app.last_run_summary.get("boons_taken", -1)), int(gate["boons_taken"]))
	_check_eq("death scrap summary matches accepted SCRAP rewards", int(app.last_run_summary.get("scrap_banked", -1)), int(gate["scrap_earned"]))
	_assert_summary_labels(screen, app.last_run_summary, "death")
	_check_eq("death save persists banked scrap", loaded.scrap_banked, int(gate["scrap_earned"]))
	_check_eq("death hub scrap label reflects persisted bank", _hub_scrap_label(returned_hub), "SCRAP %d" % int(gate["scrap_earned"]))

	await _dismiss_summary_and_assert_hub(app, screen, "death")
	await _cleanup_app(app, save_path)

func _new_app(save_path: String) -> Node:
	var app := AppScene.instantiate()
	if app == null:
		_check("app scene instantiates", false)
		return null
	if app.get_script() != AppShellScript:
		_check("app scene has AppShell script", false)
		app.queue_free()
		return null
	app.meta_save_path = save_path
	root.add_child(app)
	await _flush_frames(2)
	return app

func _start_real_run_from_hub(app: Node) -> Variant:
	var hub := _current_hub(app)
	_check("hub is present before run request", hub != null and hub.get_script() == HubControllerScript)
	if hub == null:
		return null

	hub.run_requested.emit()
	await _flush_frames(2)

	var run: Variant = _current_run(app)
	_check("hub run_requested swaps to the real run scene", run != null and run.get_script() == RunOrchestratorScript)
	if run == null:
		return null

	_check_eq("AppShell starts lifecycle RUNNING", app.lifecycle.phase, app.lifecycle.Phase.RUNNING)
	_check("real run graph is seeded and active", run.run_controller.graph != null and run.run_controller.current_room_id != "")
	_check("shell-owned run disables scene auto_start before ready", run.auto_start == false)
	_assert_hud_matches_run_start(run)
	return run

func _drive_run_to_victory(run, gate: Dictionary) -> void:
	var safety := 0
	while is_instance_valid(run) and run._run_active and safety < 24:
		var room: RoomNode = run.run_controller.graph.get_room(run.run_controller.current_room_id)
		if room == null:
			_check("victory drive has a current room", false)
			return

		await _clear_current_room_by_enemy_deaths(run, gate)
		if room.template != null and room.template.room_type == RoomTemplate.RoomType.BOSS:
			return

		var connection := _select_progress_connection(run, not bool(gate["picked_boon"]), not bool(gate["picked_scrap"]))
		if connection == null:
			_check("victory drive found a usable exit", false)
			return
		await _take_exit(run, connection, gate)
		safety += 1

	_check("victory drive reached run completion within safety limit", false)

func _drive_until_scrap_reward(run, gate: Dictionary) -> void:
	var safety := 0
	while is_instance_valid(run) and run._run_active and int(gate["scrap_earned"]) <= 0 and safety < 16:
		var room: RoomNode = run.run_controller.graph.get_room(run.run_controller.current_room_id)
		if room == null:
			_check("death drive has a current room", false)
			return
		if room.template != null and room.template.room_type == RoomTemplate.RoomType.BOSS:
			_check("death drive found Scrap before boss", false)
			return

		await _clear_current_room_by_enemy_deaths(run, gate)
		var connection := _select_progress_connection(run, false, true)
		if connection == null:
			_check("death drive found a Scrap-leading exit", false)
			return
		await _take_exit(run, connection, gate)
		safety += 1

func _clear_current_room_by_enemy_deaths(run, gate: Dictionary) -> void:
	var room_id := String(run.run_controller.current_room_id)
	var graph: RoomGraph = run.run_controller.graph
	var safety := 0
	while is_instance_valid(run) and run.current_director != null and not run.current_director.is_room_cleared() and safety < 24:
		var enemies := _live_spawned_enemies(run)
		_check("current room exposes spawned enemies to damage", not enemies.is_empty())
		for enemy in enemies:
			enemy.take_damage(maxf(enemy.hp, enemy.max_hp))
		await process_frame
		safety += 1

	var room: RoomNode = graph.get_room(room_id)
	_check("room clears through enemy death path", room != null and room.state == RoomNode.State.CLEARED)
	if room != null and room.state == RoomNode.State.CLEARED and not (gate["cleared_room_ids"] as Array).has(room_id):
		(gate["cleared_room_ids"] as Array).append(room_id)
	if is_instance_valid(run):
		_check_eq("orchestrator rooms_cleared counter tracks driven clears", run.rooms_cleared, (gate["cleared_room_ids"] as Array).size())

func _take_exit(run, connection: RoomConnection, gate: Dictionary) -> void:
	var reward_type: int = run.run_controller.exit_reward_type(connection)
	var hud_reference: Hud = gate["hud"]
	var door := run.bound_doors.get(connection.door_name) as RoomDoor
	_check("selected exit is bound to a real RoomDoor", door != null)
	if door == null:
		return

	door.emit_signal(&"body_entered", run.player)
	await process_frame

	if reward_type == RoomNode.RewardType.BOON:
		if run.flow_bridge.is_draft_open() and run.boon_draft_ui.visible:
			var picked: bool = run.boon_draft_ui.choose_offer(0)
			_check("BOON draft choice succeeds through real UI", picked)
			await process_frame
			if picked:
				gate["picked_boon"] = true
				gate["boons_taken"] = int(gate["boons_taken"]) + 1
				_check_eq("orchestrator boons_taken counter tracks draft picks", run.boons_taken, int(gate["boons_taken"]))
				_check("HUD renders current picked boon slots", _boon_loadout_count(run.hud) == run.boon_draft.picked_boons.size())
		else:
			var expected_scrap := int(gate["scrap_earned"]) + SCRAP_REWARD_VALUE
			_check_eq("empty BOON replacement grants Scrap", run.scrap_earned, expected_scrap)
			if run.scrap_earned == expected_scrap:
				gate["picked_scrap"] = true
				gate["scrap_earned"] = expected_scrap
	elif reward_type == RoomNode.RewardType.SCRAP:
		gate["picked_scrap"] = true
		gate["scrap_earned"] = int(gate["scrap_earned"]) + SCRAP_REWARD_VALUE
		_check_eq("orchestrator tracks accepted SCRAP reward", run.scrap_earned, int(gate["scrap_earned"]))
	else:
		await process_frame

	_check("HUD survives room transitions", run.hud == hud_reference)
	_check("current room remains loaded after accepted exit", run.current_room_root != null)
	_assert_spawned_enemies_inside_current_room_bounds(run, "integration accepted exit")

func _select_progress_connection(run, need_boon: bool, need_scrap: bool) -> RoomConnection:
	var graph: RoomGraph = run.run_controller.graph
	var current_room_id := String(run.run_controller.current_room_id)
	var connections: Array[RoomConnection] = graph.get_connections_from(current_room_id)
	if connections.is_empty():
		return null

	if need_boon:
		var boon_connection := _first_step_toward_reward(graph, connections, RoomNode.RewardType.BOON)
		if boon_connection != null:
			return boon_connection
	if need_scrap:
		var scrap_connection := _first_step_toward_reward(graph, connections, RoomNode.RewardType.SCRAP)
		if scrap_connection != null:
			return scrap_connection

	for connection in connections:
		var destination := graph.get_room(connection.to_room_id)
		if destination != null and destination.template != null and destination.template.room_type != RoomTemplate.RoomType.BOSS:
			return connection
	return connections[0]

func _drive_to_room(run, target_room_id: String, gate: Dictionary) -> bool:
	var graph: RoomGraph = run.run_controller.graph
	var safety := 0
	while is_instance_valid(run) and run._run_active and run.run_controller.current_room_id != target_room_id and safety < graph.rooms.size() + 4:
		await _clear_current_room_by_enemy_deaths(run, gate)
		var connections: Array[RoomConnection] = graph.get_connections_from(run.run_controller.current_room_id)
		var connection := _select_connection_toward_room(graph, connections, target_room_id)
		_check("elite integration found an exit path toward %s" % target_room_id, connection != null)
		if connection == null:
			return false
		await _take_exit(run, connection, gate)
		safety += 1
	return is_instance_valid(run) and run.run_controller.current_room_id == target_room_id

func _select_connection_toward_room(
	graph: RoomGraph,
	connections: Array[RoomConnection],
	target_room_id: String
) -> RoomConnection:
	for connection in connections:
		if _connection_leads_to_room(graph, connection, target_room_id, {}):
			return connection
	return null

func _connection_leads_to_room(
	graph: RoomGraph,
	connection: RoomConnection,
	target_room_id: String,
	visited: Dictionary
) -> bool:
	if connection == null:
		return false
	var destination := graph.get_room(connection.to_room_id)
	if destination == null:
		return false
	if destination.room_id == target_room_id:
		return true
	if visited.has(destination.room_id):
		return false
	visited[destination.room_id] = true
	for next_connection in graph.get_connections_from(destination.room_id):
		if _connection_leads_to_room(graph, next_connection, target_room_id, visited):
			return true
	return false

func _first_step_toward_reward(
	graph: RoomGraph,
	connections: Array[RoomConnection],
	reward_type: RoomNode.RewardType
) -> RoomConnection:
	for connection in connections:
		if _connection_leads_to_reward(graph, connection, reward_type, {}):
			return connection
	return null

func _connection_leads_to_reward(
	graph: RoomGraph,
	connection: RoomConnection,
	reward_type: RoomNode.RewardType,
	visited: Dictionary
) -> bool:
	if connection == null:
		return false
	var destination := graph.get_room(connection.to_room_id)
	if destination == null:
		return false
	if destination.reward_type == reward_type:
		return true
	if visited.has(destination.room_id):
		return false
	visited[destination.room_id] = true
	for next_connection in graph.get_connections_from(destination.room_id):
		if _connection_leads_to_reward(graph, next_connection, reward_type, visited):
			return true
	return false

func _new_gate_state(run) -> Dictionary:
	return {
		"hud": run.hud,
		"cleared_room_ids": [],
		"boons_taken": 0,
		"scrap_earned": 0,
		"picked_boon": false,
		"picked_scrap": false,
	}

func _assert_hud_matches_run_start(run) -> void:
	_check("run HUD stays outside the room root", run.hud != null and run.hud.get_parent() == run)
	_check_eq("HUD HP label reflects player vitals", _hp_label_text(run.hud), "%d / %d" % [run.player_vitals.hp, run.player_vitals.max_hp])
	_check("HUD guard pips are visible from player vitals", _guard_pips_visible(run.hud))
	_check("HUD ability bar renders the kit", _ability_bar_count(run.hud) >= 4)
	_assert_spawned_enemies_inside_current_room_bounds(run, "integration run start")

func _assert_summary_labels(screen: EndScreen, summary: Dictionary, prefix: String) -> void:
	_check_eq("%s summary result label" % prefix, _summary_label(screen, "ResultValue"), "COMPLETE" if bool(summary.get("victory", false)) else "LOST")
	_check_eq("%s summary rooms label" % prefix, _summary_label(screen, "RoomsValue"), str(int(summary.get("rooms_cleared", -1))))
	_check_eq("%s summary boons label" % prefix, _summary_label(screen, "BoonsValue"), str(int(summary.get("boons_taken", -1))))
	_check_eq("%s summary scrap label" % prefix, _summary_label(screen, "ScrapValue"), str(int(summary.get("scrap_banked", -1))))

func _dismiss_summary_and_assert_hub(app: Node, screen: EndScreen, prefix: String) -> void:
	var retry := screen.get_node("Root/Center/Panel/Margin/VBox/RetryButton") as Button
	retry.emit_signal(&"pressed")
	await _flush_frames(2)
	_check("%s summary dismiss removes overlay" % prefix, not is_instance_valid(screen))
	_check("%s summary dismiss leaves hub active" % prefix, _current_hub(app) != null)

func _current_content(app: Node) -> Node:
	var slot := app.get_node_or_null("ContentSlot")
	if slot == null or slot.get_child_count() == 0:
		return null
	return slot.get_child(0)

func _current_hub(app: Node) -> Node:
	var content := _current_content(app)
	if content != null and content.get_script() == HubControllerScript:
		return content
	return null

func _current_run(app: Node):
	var content := _current_content(app)
	if content != null and content.get_script() == RunOrchestratorScript:
		return content
	return null

func _summary_screen(app: Node) -> EndScreen:
	return app.get_node_or_null("EndScreen") as EndScreen

func _summary_visible(screen: EndScreen) -> bool:
	if screen == null:
		return false
	var root_node := screen.get_node_or_null("Root") as Control
	return root_node != null and root_node.visible

func _summary_label(screen: EndScreen, label_name: String) -> String:
	if screen == null:
		return ""
	var label := screen.get_node_or_null("Root/Center/Panel/Margin/VBox/Stats/%s" % label_name) as Label
	return label.text if label != null else ""

func _hub_scrap_label(hub: Node) -> String:
	if hub == null:
		return ""
	var label := hub.get_node_or_null("HubUi/Root/ScrapLabel") as Label
	return label.text if label != null else ""

func _hp_label_text(hud: Hud) -> String:
	var label := hud.get_node_or_null("Root/Nameplate/Margin/VBox/HpRow/HpLabel") as Label
	return label.text if label != null else ""

func _guard_pips_visible(hud: Hud) -> bool:
	var guard_pips := hud.get_node_or_null("Root/Nameplate/Margin/VBox/GuardPips") as HBoxContainer
	return guard_pips != null and guard_pips.visible

func _ability_bar_count(hud: Hud) -> int:
	var ability_bar := hud.get_node_or_null("Root/AbilityBar") as HBoxContainer
	return ability_bar.get_child_count() if ability_bar != null and ability_bar.visible else 0

func _boon_loadout_count(hud: Hud) -> int:
	var boon_loadout := hud.get_node_or_null("Root/BoonLoadout") as VBoxContainer
	return boon_loadout.get_child_count() if boon_loadout != null and boon_loadout.visible else 0

func _first_spawned_enemy(run) -> GreyboxEnemy:
	for enemy in run.spawned_enemies.values():
		if enemy is GreyboxEnemy and is_instance_valid(enemy):
			return enemy as GreyboxEnemy
	return null

func _first_room_id_by_type(graph: RoomGraph, room_type: RoomTemplate.RoomType) -> String:
	if graph == null:
		return ""
	for room in graph.rooms:
		if room != null and room.template != null and room.template.room_type == room_type:
			return room.room_id
	return ""

func _live_spawned_enemies(run) -> Array[GreyboxEnemy]:
	var enemies: Array[GreyboxEnemy] = []
	for enemy in run.spawned_enemies.values():
		if enemy is GreyboxEnemy and is_instance_valid(enemy):
			enemies.append(enemy as GreyboxEnemy)
	return enemies

func _clear_current_room_by_real_attack_dps(run) -> Dictionary:
	var kit: AbilityComponent = run._player_ability_kit()
	var attack := kit.get_ability(&"attack") as AttackAbility if kit != null else null
	_check("elite DPS test has the real player attack kit", kit != null and attack != null)
	if kit == null or attack == null:
		return {
			"elite_kills": 0,
			"first_elite_ttk": INF,
			"swings": 0,
		}

	var elite_elapsed_by_spawn_id: Dictionary = {}
	var first_elite_ttk := -1.0
	var elite_kills := 0
	var swings := 0
	var safety := 0
	while is_instance_valid(run) and run.current_director != null and not run.current_director.is_room_cleared() and safety < 260:
		var target := _preferred_live_enemy(run)
		if target == null:
			await process_frame
			safety += 1
			continue

		_ready_enemy_for_player_attack(run, target, _player_forward(run) * 1.1)
		var was_elite := target.archetype == RoomDirectorScript.ARCHETYPE_ELITE
		var target_spawn_id := target.spawn_id
		if was_elite and not elite_elapsed_by_spawn_id.has(target_spawn_id):
			elite_elapsed_by_spawn_id[target_spawn_id] = 0.0

		if not kit.try_activate(&"attack"):
			kit.tick(0.05)
			await process_frame
			safety += 1
			continue

		swings += 1
		var step := kit.combo_step()
		var recovery := maxf(attack.recovery_for_step(step), 0.01)
		var target_died := target.is_dead()
		if was_elite:
			if target_died:
				elite_kills += 1
				if first_elite_ttk < 0.0:
					first_elite_ttk = float(elite_elapsed_by_spawn_id[target_spawn_id])
			else:
				elite_elapsed_by_spawn_id[target_spawn_id] = float(elite_elapsed_by_spawn_id[target_spawn_id]) + recovery
		kit.tick(recovery)
		await process_frame
		safety += 1

	return {
		"elite_kills": elite_kills,
		"first_elite_ttk": first_elite_ttk if first_elite_ttk >= 0.0 else INF,
		"swings": swings,
	}

func _preferred_live_enemy(run) -> GreyboxEnemy:
	var fallback: GreyboxEnemy = null
	for enemy in _live_spawned_enemies(run):
		if enemy.is_dead():
			continue
		if enemy.archetype == RoomDirectorScript.ARCHETYPE_ELITE:
			return enemy
		if fallback == null:
			fallback = enemy
	return fallback

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

func _assert_spawned_enemies_inside_current_room_bounds(run, prefix: String) -> void:
	if run.current_director == null:
		return
	var anchor := run.current_room_root.find_child("CameraAnchor", true, false) as Marker3D if run.current_room_root != null else null
	_check("%s has a room CameraAnchor" % prefix, anchor != null)
	if anchor == null:
		return
	var half_x := float(anchor.get_meta("camera_half_extent_x", 0.0))
	var half_z := float(anchor.get_meta("camera_half_extent_z", 0.0))
	_check("%s has positive camera spawn extents" % prefix, half_x > 0.0 and half_z > 0.0)
	var enemies := _live_spawned_enemies(run)
	_check("%s has live spawned enemies" % prefix, not enemies.is_empty())
	for enemy in enemies:
		var position := enemy.global_position
		var inside_bounds := (
			absf(position.x - anchor.global_position.x) <= half_x + 0.001
			and absf(position.z - anchor.global_position.z) <= half_z + 0.001
			and position.y > 0.0
		)
		_check(
			"%s keeps %s inside camera extents and above floor at %s"
			% [prefix, enemy.spawn_id, position],
			inside_bounds
		)
	_assert_spawned_enemies_pairwise_separated(run, prefix, anchor, half_x, half_z, enemies)

func _assert_spawned_enemies_pairwise_separated(
	run,
	prefix: String,
	_anchor: Marker3D,
	half_x: float,
	half_z: float,
	enemies: Array[GreyboxEnemy]
) -> void:
	if not _room_can_satisfy_spawn_separation(half_x, half_z, enemies.size(), SPAWN_SEPARATION_DISTANCE):
		return
	for a in range(enemies.size()):
		for b in range(a + 1, enemies.size()):
			var distance := _xz_distance(enemies[a].global_position, enemies[b].global_position)
			_check(
				"%s keeps %s and %s at least %.1fm apart"
				% [prefix, enemies[a].spawn_id, enemies[b].spawn_id, SPAWN_SEPARATION_DISTANCE],
				distance + 0.001 >= SPAWN_SEPARATION_DISTANCE
			)

func _room_can_satisfy_spawn_separation(half_x: float, half_z: float, enemy_count: int, separation_distance: float) -> bool:
	if enemy_count <= 1:
		return false
	if separation_distance <= 0.0:
		return false
	var width := half_x * 2.0
	var depth := half_z * 2.0
	if width < separation_distance or depth < separation_distance:
		return false
	return width * depth >= float(enemy_count) * separation_distance * separation_distance

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _melee_ttk_for_hp(hp: float, attack: AttackAbility) -> Dictionary:
	var remaining := hp
	var elapsed := 0.0
	var step := 1
	for hit in range(1, 200):
		remaining -= attack.damage_for_step(step)
		if remaining <= 0.0:
			return {
				"seconds": elapsed,
				"hits": hit,
			}
		elapsed += attack.recovery_for_step(step)
		step = (step % maxi(attack.combo_steps, 1)) + 1
	return {
		"seconds": INF,
		"hits": 200,
	}

func _new_save_path(test_name: String) -> String:
	_ensure_test_save_root()
	return _test_save_root().path_join("run_integration_gate_%s.cfg" % test_name)

func _ensure_test_save_root() -> void:
	var absolute_root := _test_save_root()
	var error := DirAccess.make_dir_recursive_absolute(absolute_root)
	if error != OK and error != ERR_ALREADY_EXISTS:
		_check("integration test save root is creatable", false)

func _test_save_root() -> String:
	return _requested_user_data_dir().path_join(TEST_SAVE_SUBDIR)

func _requested_user_data_dir() -> String:
	var args := OS.get_cmdline_args()
	for index in range(args.size()):
		var arg := String(args[index])
		if arg.begins_with("--user-data-dir="):
			return arg.substr("--user-data-dir=".length()).simplify_path()
		if arg == "--user-data-dir" and index + 1 < args.size():
			return String(args[index + 1]).simplify_path()
	var env_dir := OS.get_environment("GODOT_USER_DATA_DIR")
	if env_dir != "":
		return env_dir.simplify_path()
	return OS.get_user_data_dir().simplify_path()

func _remove_save(path: String) -> void:
	var absolute := path if path.is_absolute_path() else ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)

func _cleanup_app(app: Node, save_path: String) -> void:
	if app != null and is_instance_valid(app):
		app.queue_free()
	await _flush_frames(2)
	_remove_save(save_path)

func _flush_frames(count: int = 1) -> void:
	for _i in range(count):
		await process_frame
