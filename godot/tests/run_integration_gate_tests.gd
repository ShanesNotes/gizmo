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
const RoomDoorScript := preload("res://scripts/room_graph/room_door.gd")
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
	await _test_real_cast_kill_cycles_ammo_and_hud_count()
	await _test_real_elite_room_clears_through_live_attack_dps()
	await _test_boss_room_ttk_and_victory_ceremony()
	await _test_boss_add_death_never_clears_nil_director_room()
	await _test_boss_fight_death_tears_down_to_loss_summary()
	await _test_rest_reward_runtime_fixture_traversal()
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

func _check_almost(desc: String, actual: float, expected: float, margin: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, margin], absf(actual - expected) <= margin)

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

func _test_real_cast_kill_cycles_ammo_and_hud_count() -> void:
	var save_path := _new_save_path("real_cast_kill")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var kit: AbilityComponent = run._player_ability_kit()
	var cast := kit.get_ability(&"cast") as CastAbility if kit != null else null
	var enemy := _first_spawned_enemy(run)
	_check("real cast kill test has the player cast kit", kit != null and cast != null)
	_check("real cast kill test has a spawned enemy", enemy != null)
	if kit == null or cast == null or enemy == null:
		await _cleanup_app(app, save_path)
		return

	cast.max_ammo = 1
	cast.potency = maxf(enemy.hp, enemy.max_hp)
	cast.cast_time = 0.0
	cast.recovery_time = 0.01
	run._render_hud_payloads()
	_check_eq("HUD starts CAST count at available ammo", _ability_count_text(run.hud, "CAST"), "1")

	run.player_vitals.set("spark_surge_charge_max", 300.0)
	run.player_vitals.set("spark_damage_dealt_charge_rate", 1.0)
	run.player_vitals.call("set_spark_surge_charge", 0.0)
	_ready_enemy_for_player_attack(run, enemy, _player_forward(run) * 4.0)

	_check("real cast activates through the live kit", kit.try_activate(&"cast"))
	await _flush_frames(2)

	_check("real cast kill removes or kills its target", not is_instance_valid(enemy) or enemy.is_dead())
	_check_eq("real cast kill reclaims ammo through victim death", kit.cast_ammo(), 1)
	_check_eq("real cast kill leaves no lodged ammo", kit.cast_lodged_ammo(), 0)
	_check_eq("HUD CAST count follows reclaimed ammo", _ability_count_text(run.hud, "CAST"), "1")
	_check("real cast damage charges Spark Surge", float(run.player_vitals.get("spark_surge_charge")) > 0.0)
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

func _test_boss_room_ttk_and_victory_ceremony() -> void:
	var save_path := _new_save_path("boss_victory")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var graph: RoomGraph = run.run_controller.graph
	var boss_room_id := _first_room_id_by_type(graph, RoomTemplate.RoomType.BOSS)
	_check("boss integration graph includes a BOSS room", boss_room_id != "")
	if boss_room_id == "":
		await _cleanup_app(app, save_path)
		return

	var gate := _new_gate_state(run)
	var reached_boss := await _drive_to_room(run, boss_room_id, gate)
	_check("boss integration drive reaches the BOSS room", reached_boss)
	if not reached_boss:
		await _cleanup_app(app, save_path)
		return

	var boss := run.get("current_boss") as GreyboxEnemy
	_check("boss integration room registers current_boss", boss != null and boss.spawn_id == "boss:custodian")
	if boss == null:
		await _cleanup_app(app, save_path)
		return

	var ttk := await _kill_boss_with_dps_model(run, boss)
	_check_between("Custodian 2400 HP TTK under 110 DPS model", ttk, 10.0, 60.0)
	await _flush_frames(3)

	var returned_hub := _current_hub(app)
	var screen := _summary_screen(app)
	_check("boss victory returns content to hub", returned_hub != null)
	_check("boss victory shows summary overlay", _summary_visible(screen))
	_check_eq("boss victory summary is victory", app.last_run_summary.get("victory", false), true)
	_check("boss victory clears at least the boss room", int(app.last_run_summary.get("rooms_cleared", 0)) >= 1)
	_assert_summary_labels(screen, app.last_run_summary, "boss victory")
	await _cleanup_app(app, save_path)

func _test_boss_add_death_never_clears_nil_director_room() -> void:
	var save_path := _new_save_path("boss_add_death")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var boss_room_id := _first_room_id_by_type(run.run_controller.graph, RoomTemplate.RoomType.BOSS)
	var gate := _new_gate_state(run)
	var reached_boss := await _drive_to_room(run, boss_room_id, gate)
	_check("boss add-death drive reaches the BOSS room", reached_boss)
	if not reached_boss:
		await _cleanup_app(app, save_path)
		return

	var boss := run.get("current_boss") as GreyboxEnemy
	var boss_room: RoomNode = run.run_controller.graph.get_room(run.run_controller.current_room_id)
	_check("boss add-death test has the Custodian", boss != null)
	_check_eq("boss add-death test has no RoomDirector", run.current_director, null)
	if boss == null:
		await _cleanup_app(app, save_path)
		return

	boss.take_damage(650.0)
	await _flush_frames(2)
	var adds := _boss_room_adds(run, boss.spawn_id)
	_check("boss threshold damage spawns real adds", not adds.is_empty())
	if adds.is_empty():
		await _cleanup_app(app, save_path)
		return

	var add := adds[0]
	var add_spawn_id := add.spawn_id
	add.take_damage(maxf(add.hp, add.max_hp))
	await _flush_frames(2)

	_check("boss add death removes only that add from bookkeeping", not run.spawned_enemies.has(add_spawn_id))
	_check("boss add death leaves the run active", is_instance_valid(run) and run._run_active)
	_check_eq("boss add death does not create a RoomDirector", run.current_director, null)
	_check("boss add death does not clear the boss room", boss_room != null and boss_room.state != RoomNode.State.CLEARED)
	_check("boss add death leaves the boss fight alive", is_instance_valid(boss) and not boss.is_dead() and run.get("current_boss") == boss)
	await _cleanup_app(app, save_path)

func _test_boss_fight_death_tears_down_to_loss_summary() -> void:
	var save_path := _new_save_path("boss_death")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var boss_room_id := _first_room_id_by_type(run.run_controller.graph, RoomTemplate.RoomType.BOSS)
	var gate := _new_gate_state(run)
	var reached_boss := await _drive_to_room(run, boss_room_id, gate)
	_check("boss death drive reaches the BOSS room", reached_boss)
	if not reached_boss:
		await _cleanup_app(app, save_path)
		return

	var boss := run.get("current_boss") as GreyboxEnemy
	_check("boss death test has the Custodian", boss != null)
	if boss == null:
		await _cleanup_app(app, save_path)
		return

	var lethal_damage := int(run.player_vitals.guard) + int(run.player_vitals.hp)
	boss.damage_event.emit({
		"damage": lethal_damage,
		"spawn_id": boss.spawn_id,
		"archetype": boss.archetype,
		"attack_id": "boss_death_probe",
		"source_position": boss.global_position,
	})
	await _flush_frames(3)

	_check("boss-fight death returns content to hub", _current_hub(app) != null)
	_check("boss-fight death removes the run surface", _current_run(app) == null)
	_check("boss-fight death shows summary overlay", _summary_visible(_summary_screen(app)))
	_check_eq("boss-fight death records a loss", app.last_run_summary.get("victory", true), false)
	_assert_summary_labels(_summary_screen(app), app.last_run_summary, "boss death")
	await _cleanup_app(app, save_path)

func _test_rest_reward_runtime_fixture_traversal() -> void:
	var save_path := _new_save_path("rest_reward_runtime")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return

	var run: Variant = await _start_real_run_from_hub(app)
	if run == null:
		await _cleanup_app(app, save_path)
		return

	var gate := _new_gate_state(run)
	var fixture_path := _force_reward_then_rest_path(run)
	_check("integration forced graph contains REWARD then REST rooms", not fixture_path.is_empty())
	if fixture_path.is_empty():
		await _cleanup_app(app, save_path)
		return

	var entry_to_reward: RoomConnection = fixture_path["entry_to_reward"]
	var reward_to_rest: RoomConnection = fixture_path["reward_to_rest"]
	var rest_exit: RoomConnection = fixture_path["rest_exit"]
	var reward_room_id := String(fixture_path["reward_room_id"])
	var rest_room_id := String(fixture_path["rest_room_id"])

	var entry_door := _bound_door_for(run, entry_to_reward)
	_check("entry door toward Scrap Cache is bound before clear", entry_door != null)
	if entry_door != null:
		_move_player_to_area_xz(run, entry_door)
	await _clear_current_room_by_enemy_deaths(run, gate)
	await _flush_physics_frames(2)
	await _flush_frames(2)

	_check_eq("already-overlapping REWARD door advances to Scrap Cache", run.run_controller.current_room_id, reward_room_id)
	if run.run_controller.current_room_id != reward_room_id:
		await _cleanup_app(app, save_path)
		return

	_assert_noncombat_room_ready(run, reward_room_id, RoomTemplate.RoomType.REWARD, reward_to_rest, "REWARD")
	_check_eq("REWARD entry does not grant Scrap before pickup", run.scrap_earned, int(gate["scrap_earned"]))

	var reward_fixture := _room_fixture_area(run, "RewardFixture")
	_check("Scrap Cache fixture is a physical Area3D pickup", reward_fixture != null)
	if reward_fixture != null:
		var scrap_before: int = run.scrap_earned
		await _walk_player_into_area(run, reward_fixture)
		_check_eq("Scrap Cache grants promised Scrap exactly once", run.scrap_earned, scrap_before + SCRAP_REWARD_VALUE)
		if run.scrap_earned == scrap_before + SCRAP_REWARD_VALUE:
			gate["scrap_earned"] = run.scrap_earned
		await _walk_player_out_of_fixture(run)
		await _walk_player_into_area(run, reward_fixture)
		_check_eq("Scrap Cache re-entry does not re-grant", run.scrap_earned, scrap_before + SCRAP_REWARD_VALUE)

	await _walk_through_open_door(run, reward_to_rest, "Scrap Cache exit")
	if run.run_controller.current_room_id != rest_room_id:
		await _cleanup_app(app, save_path)
		return

	_assert_noncombat_room_ready(run, rest_room_id, RoomTemplate.RoomType.REST, rest_exit, "REST")
	var rest_fixture := _room_fixture_area(run, "RestFixture")
	_check("Ember Alcove fixture is a physical Area3D pickup", rest_fixture != null)
	if rest_fixture != null:
		run.player_vitals.hp = 2
		run.player_vitals.guard = 3
		run.player_vitals.set("spark_surge_charge_max", 100.0)
		run.player_vitals.call("set_spark_surge_charge", 37.0)
		var hp_before: int = run.player_vitals.hp
		var spark_before := float(run.player_vitals.get("spark_surge_charge"))

		await _walk_player_into_area(run, rest_fixture)
		_check_eq("Ember Alcove refills guard to max once", run.player_vitals.guard, run.player_vitals.max_guard)
		_check_eq("Ember Alcove does not heal HP", run.player_vitals.hp, hp_before)
		_check_almost("Ember Alcove never refills Spark Surge", float(run.player_vitals.get("spark_surge_charge")), spark_before)

		run.player_vitals.guard = 1
		await _walk_player_out_of_fixture(run)
		await _walk_player_into_area(run, rest_fixture)
		_check_eq("Ember Alcove re-entry does not refill guard again", run.player_vitals.guard, 1)
		_check_almost("Ember Alcove re-entry still leaves Spark Surge unchanged", float(run.player_vitals.get("spark_surge_charge")), spark_before)

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
	var boss := run.get("current_boss") as GreyboxEnemy
	if boss != null and is_instance_valid(boss):
		boss.take_damage(maxf(boss.hp, boss.max_hp))
		await process_frame
		var boss_room: RoomNode = graph.get_room(room_id)
		_check("boss room clears through boss death path", boss_room != null and boss_room.state == RoomNode.State.CLEARED)
		if boss_room != null and boss_room.state == RoomNode.State.CLEARED and not (gate["cleared_room_ids"] as Array).has(room_id):
			(gate["cleared_room_ids"] as Array).append(room_id)
		if is_instance_valid(run):
			_check_eq("orchestrator rooms_cleared counter tracks boss clear", run.rooms_cleared, (gate["cleared_room_ids"] as Array).size())
		return

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

func _kill_boss_with_dps_model(run, boss: GreyboxEnemy) -> float:
	if boss == null:
		return INF
	var elapsed := 0.0
	var dt := 0.25
	while is_instance_valid(run) and is_instance_valid(boss) and not boss.is_dead() and elapsed < 90.0:
		boss.take_damage(110.0 * dt)
		elapsed += dt
		await process_frame
	return elapsed

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

func _force_reward_then_rest_path(run) -> Dictionary:
	var graph: RoomGraph = run.run_controller.graph
	if graph == null:
		return {}

	var reward_template := _load_template_resource("res://resources/room_templates/reward_cache.tres")
	var rest_template := _load_template_resource("res://resources/room_templates/rest_alcove.tres")
	if reward_template == null or rest_template == null:
		return {}

	var entry_room_id := String(run.run_controller.current_room_id)
	for entry_to_reward in graph.get_connections_from(entry_room_id):
		var reward_room := graph.get_room(entry_to_reward.to_room_id)
		if reward_room == null:
			continue
		for reward_to_rest in graph.get_connections_from(reward_room.room_id):
			var rest_room := graph.get_room(reward_to_rest.to_room_id)
			if rest_room == null:
				continue
			var rest_exits := graph.get_connections_from(rest_room.room_id)
			if rest_exits.is_empty():
				continue

			reward_room.template = reward_template
			reward_room.reward_type = RoomNode.RewardType.REWARD
			rest_room.template = rest_template
			rest_room.reward_type = RoomNode.RewardType.REST
			return {
				"entry_to_reward": entry_to_reward,
				"reward_to_rest": reward_to_rest,
				"rest_exit": rest_exits[0],
				"reward_room_id": reward_room.room_id,
				"rest_room_id": rest_room.room_id,
			}

	return {}

func _load_template_resource(path: String) -> RoomTemplate:
	var resource := load(path)
	if resource is RoomTemplate:
		return resource as RoomTemplate
	return null

func _assert_noncombat_room_ready(
	run,
	room_id: String,
	room_type: RoomTemplate.RoomType,
	exit_connection: RoomConnection,
	label: String
) -> void:
	var room: RoomNode = run.run_controller.graph.get_room(room_id)
	_check("%s room is current" % label, run.run_controller.current_room_id == room_id)
	_check("%s room uses expected authored template" % label, room != null and room.template != null and room.template.room_type == room_type)
	_check_eq("%s room auto-clears at entry" % label, room.state if room != null else RoomNode.State.LOCKED, RoomNode.State.CLEARED)
	_check("%s room has no director" % label, run.current_director == null)
	_check_eq("%s room requests CLEARED audio zone" % label, _audio_requested_zone_state(), "CLEARED")
	var door := _bound_door_for(run, exit_connection)
	_check("%s room opens its exit door at entry" % label, door != null and door.state == RoomDoorScript.State.OPEN)

func _bound_door_for(run, connection: RoomConnection) -> RoomDoor:
	if run == null or connection == null:
		return null
	var door := run.bound_doors.get(connection.door_name) as RoomDoor
	if door == null:
		door = run.bound_doors.get("RoomExit") as RoomDoor
	return door

func _room_fixture_area(run, fixture_name: String) -> Area3D:
	if run == null or run.current_room_root == null:
		return null
	var fixture: Node = run.current_room_root.find_child(fixture_name, true, false)
	if fixture is Area3D:
		return fixture as Area3D
	return null

func _walk_through_open_door(run, connection: RoomConnection, label: String) -> void:
	var door := _bound_door_for(run, connection)
	_check("%s has an open bound door" % label, door != null and door.state == RoomDoorScript.State.OPEN)
	if door == null:
		return

	_move_player_to_area_xz(run, door)
	await _flush_physics_frames(2)
	await _flush_frames(2)
	if run.run_controller.current_room_id != connection.to_room_id:
		door.emit_signal(&"body_entered", run.player)
		await _flush_frames(2)
	_check_eq("%s advances to destination" % label, run.run_controller.current_room_id, connection.to_room_id)

func _walk_player_into_area(run, area: Area3D) -> void:
	_move_player_to_area_xz(run, area)
	for _i in range(10):
		await _flush_physics_frames(1)
		await _flush_frames(1)
		if area != null and area.has_method("is_claimed") and bool(area.call("is_claimed")):
			return

func _walk_player_out_of_fixture(run) -> void:
	if run == null or run.current_room_root == null or run.player == null:
		return
	var spawn := run.current_room_root.find_child("SpawnMarker", true, false) as Marker3D
	if spawn != null:
		run.player.global_position = spawn.global_position
		run.player.velocity = Vector3.ZERO
	await _flush_physics_frames(2)
	await _flush_frames(1)

func _move_player_to_area_xz(run, area: Area3D) -> void:
	if run == null or area == null or run.player == null:
		return
	var current_y: float = run.player.global_position.y
	run.player.global_position = Vector3(area.global_position.x, current_y, area.global_position.z)
	run.player.velocity = Vector3.ZERO

func _audio_requested_zone_state() -> String:
	var director := root.get_node_or_null("AudioDirector")
	if director == null or not director.has_method(&"describe"):
		return ""
	var description: Dictionary = director.call(&"describe")
	return String(description.get("requested_music_state", ""))

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

func _ability_count_text(hud: Hud, kind_label: String) -> String:
	var ability_bar := hud.get_node_or_null("Root/AbilityBar") as HBoxContainer
	if ability_bar == null or not ability_bar.visible:
		return ""
	for slot in ability_bar.get_children():
		var labels := _labels_under(slot)
		if labels.size() >= 2 and labels[0].text == kind_label:
			return labels[1].text
	return ""

func _labels_under(node: Node) -> Array[Label]:
	var labels: Array[Label] = []
	if node is Label:
		labels.append(node as Label)
	for child in node.get_children():
		labels.append_array(_labels_under(child))
	return labels

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

func _boss_room_adds(run, boss_spawn_id: String) -> Array[GreyboxEnemy]:
	var adds: Array[GreyboxEnemy] = []
	for enemy in _live_spawned_enemies(run):
		if enemy.spawn_id != boss_spawn_id:
			adds.append(enemy)
	return adds

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

func _flush_physics_frames(count: int = 1) -> void:
	for _i in range(count):
		await physics_frame
