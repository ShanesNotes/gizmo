extends SceneTree

# Full real-scene HZ-061 ship gate.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_integration_gate_tests.gd

const AppScene := preload("res://scenes/app.tscn")
const AppShellScript := preload("res://scripts/app_shell.gd")
const HubControllerScript := preload("res://scripts/hub_controller.gd")
const RunOrchestratorScript := preload("res://scripts/room_graph/run_orchestrator.gd")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")

const EXPECTED_MAIN_SCENE := "res://scenes/app.tscn"
const EXPECTED_RUN_SCENE := "res://scenes/run.tscn"
const SCRAP_REWARD_VALUE := 10

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running full-run integration gate tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
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
		_check("BOON exit opens a real boon draft", run.flow_bridge.is_draft_open() and run.boon_draft_ui.visible)
		var picked: bool = run.boon_draft_ui.choose_offer(0)
		_check("BOON draft choice succeeds through real UI", picked)
		await process_frame
		if picked:
			gate["picked_boon"] = true
			gate["boons_taken"] = int(gate["boons_taken"]) + 1
			_check_eq("orchestrator boons_taken counter tracks draft picks", run.boons_taken, int(gate["boons_taken"]))
			_check("HUD renders picked boons", _boon_loadout_count(run.hud) == int(gate["boons_taken"]))
	elif reward_type == RoomNode.RewardType.SCRAP:
		gate["picked_scrap"] = true
		gate["scrap_earned"] = int(gate["scrap_earned"]) + SCRAP_REWARD_VALUE
		_check_eq("orchestrator tracks accepted SCRAP reward", run.scrap_earned, int(gate["scrap_earned"]))
	else:
		await process_frame

	_check("HUD survives room transitions", run.hud == hud_reference)
	_check("current room remains loaded after accepted exit", run.current_room_root != null)

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

func _live_spawned_enemies(run) -> Array[GreyboxEnemy]:
	var enemies: Array[GreyboxEnemy] = []
	for enemy in run.spawned_enemies.values():
		if enemy is GreyboxEnemy and is_instance_valid(enemy):
			enemies.append(enemy as GreyboxEnemy)
	return enemies

func _new_save_path(test_name: String) -> String:
	return "user://saves/run_integration_gate_%s.cfg" % test_name

func _remove_save(path: String) -> void:
	var absolute := ProjectSettings.globalize_path(path)
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
