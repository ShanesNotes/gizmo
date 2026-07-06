extends SceneTree

# Headless tests for HZ-016 Gizmo player entity scene.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_player_tests.gd

const PlayerMotorScript := preload("res://scripts/player/player_motor.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")
const GizmoPlayerScene := preload("res://scenes/gizmo_player.tscn")
const ACTION_DASH: StringName = &"gizmo_dash"

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running player tests...")
	await _test_motor_velocity_math()
	await _test_dash_burst_overrides_then_decays()
	await _test_dash_burst_arguments_do_not_stick_to_defaults()
	await _test_player_scene_instantiates_with_stable_nodes()
	_test_player_vitals_guard_recharges_after_damage_delay()
	_test_player_vitals_damage_lockout_limits_burst_contact()
	_test_player_vitals_spark_charge_bands_and_clamps()
	_test_player_vitals_spark_charge_empties_on_death()
	await _test_scene_router_press_reaches_ability_component()
	await _test_scene_dash_uses_held_movement_direction()
	await _test_scene_dash_press_during_dash_is_blocked_by_current_kit()
	await _test_scene_dash_cancels_attack_recovery_end_to_end()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => player tests failed to load/compile)" if _passed == 0 else ""]
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

func _check_almost(desc: String, actual: float, expected: float, margin: float = 0.001) -> void:
	_check("%s (got %.4f, expected %.4f +/- %.4f)" % [desc, actual, expected, margin], absf(actual - expected) <= margin)

func _check_vec3_almost(desc: String, actual: Vector3, expected: Vector3, margin: float = 0.001) -> void:
	_check(
		"%s (got %s, expected %s +/- %.4f)" % [desc, actual, expected, margin],
		actual.distance_to(expected) <= margin
	)

func _new_motor():
	var motor = PlayerMotorScript.new()
	motor.move_speed = 4.0
	motor.acceleration = 1000.0
	motor.friction = 1000.0
	motor.dash_speed = 14.0
	motor.dash_duration = 0.25
	return motor

func _new_player():
	var player = GizmoPlayerScene.instantiate()
	root.add_child(player)
	await process_frame
	return player

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_motor_velocity_math() -> void:
	var motor = _new_motor()

	var idle_velocity := motor.step(Vector3(3.0, 0.0, -2.0), Vector3.ZERO, 1.0)
	_check_vec3_almost("idle input brakes horizontal velocity to zero", idle_velocity, Vector3.ZERO)

	var north_direction: Vector3 = PlayerMotorScript.input_vector_to_world_direction(Vector2(0.0, -1.0))
	var north_velocity := motor.step(Vector3.ZERO, north_direction, 1.0)
	_check_vec3_almost("W maps to fixed-camera north on -Z", north_direction, Vector3(0.0, 0.0, -1.0))
	_check_vec3_almost("cardinal movement reaches move speed", north_velocity, Vector3(0.0, 0.0, -4.0))
	_check_almost("cardinal speed length is move_speed", north_velocity.length(), 4.0)

	var diagonal_direction: Vector3 = PlayerMotorScript.input_vector_to_world_direction(Vector2(1.0, -1.0))
	var diagonal_velocity := motor.step(Vector3.ZERO, diagonal_direction, 1.0)
	_check_almost("diagonal input is normalized", diagonal_direction.length(), 1.0)
	_check_almost("diagonal velocity length stays at move_speed", diagonal_velocity.length(), 4.0)
	_check("diagonal velocity moves east and north", diagonal_velocity.x > 0.0 and diagonal_velocity.z < 0.0)

func _test_dash_burst_overrides_then_decays() -> void:
	var motor = _new_motor()
	motor.acceleration = 40.0
	motor.friction = 50.0

	motor.begin_dash(Vector3.RIGHT)
	var velocity := motor.step(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), 0.10)
	_check("dash is active during the first 0.10s", motor.is_dashing())
	_check_vec3_almost("dash overrides movement input with dash direction", velocity, Vector3(14.0, 0.0, 0.0))

	velocity = motor.step(velocity, Vector3(0.0, 0.0, -1.0), 0.14)
	_check("dash remains active just before 0.25s", motor.is_dashing())
	_check_vec3_almost("dash still owns velocity before duration ends", velocity, Vector3(14.0, 0.0, 0.0))

	velocity = motor.step(velocity, Vector3(0.0, 0.0, -1.0), 0.02)
	_check("dash ends after roughly 0.25s", not motor.is_dashing())
	_check("post-dash velocity starts decaying below burst speed", velocity.length() < 14.0)

	for i in range(20):
		velocity = motor.step(velocity, Vector3(0.0, 0.0, -1.0), 0.05)

	_check_almost("post-dash decay returns to base move speed", velocity.length(), 4.0, 0.01)
	_check("post-dash velocity follows held movement input", absf(velocity.x) < 0.01 and velocity.z < 0.0)

func _test_dash_burst_arguments_do_not_stick_to_defaults() -> void:
	var motor = _new_motor()

	motor.begin_dash(Vector3.RIGHT, 28.0, 0.10)
	_check_almost("explicit dash speed does not overwrite motor default speed", motor.dash_speed, 14.0)
	_check_almost("explicit dash duration does not overwrite motor default duration", motor.dash_duration, 0.25)
	var velocity := motor.step(Vector3.ZERO, Vector3.ZERO, 0.01)
	_check_vec3_almost("explicit dash uses call-scoped burst speed", velocity, Vector3(28.0, 0.0, 0.0))

	motor.clear_dash()
	motor.begin_dash(Vector3.LEFT)
	_check_almost("argless dash restores default duration", motor.dash_time_remaining(), 0.25)
	velocity = motor.step(Vector3.ZERO, Vector3.ZERO, 0.01)
	_check_vec3_almost("argless dash restores default speed", velocity, Vector3(-14.0, 0.0, 0.0))

func _test_player_scene_instantiates_with_stable_nodes() -> void:
	var player = await _new_player()

	_check("scene root is CharacterBody3D", player is CharacterBody3D)
	_check_eq("scene root node name is stable", player.name, "GizmoPlayer")
	_check("CollisionShape3D node exists", player.get_node_or_null("CollisionShape3D") is CollisionShape3D)
	_check("VisualPivot node exists", player.get_node_or_null("VisualPivot") is Node3D)
	_check("placeholder Capsule mesh exists", player.get_node_or_null("VisualPivot/Capsule") is MeshInstance3D)
	_check("gizmo.glb Model node is not wired yet", player.get_node_or_null("VisualPivot/Model") == null)
	_check("AbilityComponent node exists", player.get_node_or_null("AbilityComponent") is AbilityComponent)
	_check("AbilityInputRouter node exists", player.get_node_or_null("AbilityInputRouter") is AbilityInputRouter)
	_check("router is bound to the scene AbilityComponent", player.ability_input_router.ability_component == player.ability_component)
	_check_almost("scene dash duration is Hades-spec ~0.25s", player.motor.dash_duration, 0.25)
	_check("scene root is tagged for player-only trigger filters", player.is_in_group(&"player"))

	await _cleanup(player)

func _test_player_vitals_guard_recharges_after_damage_delay() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	vitals.max_hp = 3
	vitals.max_guard = 4
	var has_recharge_delay := _object_has_property(vitals, "guard_recharge_delay")
	var has_recharge_rate := _object_has_property(vitals, "guard_recharge_rate")
	var has_recharge_tick := vitals.has_method("tick_guard_recharge")
	_check("PlayerVitals exposes guard_recharge_delay", has_recharge_delay)
	_check("PlayerVitals exposes guard_recharge_rate", has_recharge_rate)
	_check("PlayerVitals exposes tick_guard_recharge", has_recharge_tick)
	if not has_recharge_delay or not has_recharge_rate or not has_recharge_tick:
		vitals.free()
		return
	vitals.set("guard_recharge_delay", 1.0)
	vitals.set("guard_recharge_rate", 2.0)
	vitals.reset()

	vitals.apply_damage(2)
	_check_eq("guard damage reduces guard before recharge", vitals.guard, 2)
	vitals.call("tick_guard_recharge", 0.99)
	_check_eq("guard does not recharge before delay", vitals.guard, 2)
	vitals.call("tick_guard_recharge", 0.51)
	_check_eq("guard begins recharging once delay elapses", vitals.guard, 3)
	vitals.call("tick_guard_recharge", 0.50)
	_check_eq("guard continues recharging up to max", vitals.guard, 4)
	vitals.apply_damage(1)
	_check_eq("new damage resets guard recharge timer", vitals.guard, 3)
	vitals.call("tick_guard_recharge", 0.99)
	_check_eq("guard still waits full delay after reset damage", vitals.guard, 3)
	vitals.free()

func _test_player_vitals_damage_lockout_limits_burst_contact() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	vitals.max_hp = 3
	vitals.max_guard = 4
	vitals.guard_recharge_delay = 99.0
	vitals.damage_lockout = 0.5
	vitals.reset()

	vitals.apply_damage(1)
	_check_eq("first burst hit removes one guard", vitals.guard, 3)
	vitals.apply_damage(1)
	_check_eq("same-burst hit is blocked by damage lockout", vitals.guard, 3)
	vitals.tick_guard_recharge(0.49)
	vitals.apply_damage(1)
	_check_eq("damage lockout holds until its full duration", vitals.guard, 3)
	vitals.tick_guard_recharge(0.02)
	vitals.apply_damage(1)
	_check_eq("damage can land again after lockout elapses", vitals.guard, 2)
	vitals.free()

func _test_player_vitals_spark_charge_bands_and_clamps() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	var has_charge := _object_has_property(vitals, "spark_surge_charge")
	var has_max := _object_has_property(vitals, "spark_surge_charge_max")
	var has_dealt_rate := _object_has_property(vitals, "spark_damage_dealt_charge_rate")
	var has_guard_rate := _object_has_property(vitals, "spark_guard_damage_taken_charge_rate")
	var has_record_dealt := vitals.has_method("record_damage_dealt")
	var has_set_charge := vitals.has_method("set_spark_surge_charge")
	_check("PlayerVitals exposes Spark Surge charge", has_charge)
	_check("PlayerVitals exposes Spark Surge max", has_max)
	_check("PlayerVitals exposes dealt-damage charge rate", has_dealt_rate)
	_check("PlayerVitals exposes guard-damage charge rate", has_guard_rate)
	_check("PlayerVitals exposes record_damage_dealt", has_record_dealt)
	_check("PlayerVitals exposes set_spark_surge_charge", has_set_charge)
	if not (has_charge and has_max and has_dealt_rate and has_guard_rate and has_record_dealt and has_set_charge):
		vitals.free()
		return

	vitals.max_hp = 3
	vitals.max_guard = 4
	vitals.set("spark_surge_charge_max", 100.0)
	vitals.set("spark_damage_dealt_charge_rate", 5.0)
	vitals.set("spark_guard_damage_taken_charge_rate", 20.0)
	vitals.reset()

	_check_almost("Spark Surge starts empty on run reset", float(vitals.get("spark_surge_charge")), 0.0)
	vitals.call("record_damage_dealt", 3.0)
	_check_almost("damage dealt adds small Spark Surge charge", float(vitals.get("spark_surge_charge")), 15.0)
	vitals.apply_damage(2)
	_check_almost("guard damage taken adds large Spark Surge charge", float(vitals.get("spark_surge_charge")), 55.0)
	vitals.call("record_damage_dealt", 99.0)
	_check_almost("Spark Surge charge clamps at max", float(vitals.get("spark_surge_charge")), 100.0)
	vitals.call("set_spark_surge_charge", -10.0)
	_check_almost("Spark Surge charge clamps at zero", float(vitals.get("spark_surge_charge")), 0.0)
	vitals.free()

func _test_player_vitals_spark_charge_empties_on_death() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	if not vitals.has_method("set_spark_surge_charge") or not _object_has_property(vitals, "spark_surge_charge"):
		_check("PlayerVitals can set Spark Surge charge for death reset", false)
		vitals.free()
		return

	vitals.max_hp = 3
	vitals.max_guard = 2
	vitals.reset()
	vitals.call("set_spark_surge_charge", 80.0)
	vitals.apply_damage(vitals.max_hp + vitals.max_guard)
	_check_eq("lethal damage marks player dead", vitals.is_dead(), true)
	_check_almost("Spark Surge charge empties on death", float(vitals.get("spark_surge_charge")), 0.0)
	vitals.free()

func _object_has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _test_scene_router_press_reaches_ability_component() -> void:
	var player = await _new_player()
	var activated_ids: Array[StringName] = []
	player.ability_component.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	var event := InputEventAction.new()
	event.action = ACTION_DASH
	event.pressed = true
	player.ability_input_router._unhandled_input(event)

	_check_eq("simulated dash action reaches AbilityComponent", activated_ids, [&"dash"])
	_check_eq("dash press puts ability component in DASH", player.ability_component.current_action_state(), PlayerActionStateMachine.ActionState.DASH)
	_check("dash signal starts player motor burst", player.motor.is_dashing())
	_check_almost("scene dash burst duration came from DashAbility", player.motor.dash_time_remaining(), 0.25)
	_check_vec3_almost("zero-direction action falls back to facing direction", player.motor.dash_direction(), PlayerMotorScript.DEFAULT_FACING_DIRECTION)

	await _cleanup(player)

func _test_scene_dash_uses_held_movement_direction() -> void:
	var player = await _new_player()
	var activated_ids: Array[StringName] = []
	var dash_signal_directions: Array[Vector3] = []
	player.ability_component.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)
	player.ability_component.dash_started.connect(func(direction: Vector3, _speed: float, _duration: float) -> void:
		dash_signal_directions.append(direction)
	)

	Input.action_press(&"gizmo_move_right")
	Input.action_press(&"gizmo_move_up")
	var event := InputEventAction.new()
	event.action = ACTION_DASH
	event.pressed = true
	player.ability_input_router._unhandled_input(event)
	Input.action_release(&"gizmo_move_right")
	Input.action_release(&"gizmo_move_up")

	var expected_direction := Vector3(1.0, 0.0, -1.0).normalized()
	_check_eq("held diagonal dash action reaches AbilityComponent", activated_ids, [&"dash"])
	_check_eq("held diagonal dash emits one dash_started payload", dash_signal_directions.size(), 1)
	if dash_signal_directions.size() == 1:
		_check_vec3_almost("held diagonal reaches try_activate as normalized direction", dash_signal_directions[0], expected_direction)
	_check_vec3_almost("held diagonal dash uses normalized movement direction", player.motor.dash_direction(), expected_direction)

	await _cleanup(player)

func _test_scene_dash_press_during_dash_is_blocked_by_current_kit() -> void:
	var player = await _new_player()
	var activated_ids: Array[StringName] = []
	player.ability_component.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	var first_event := InputEventAction.new()
	first_event.action = ACTION_DASH
	first_event.pressed = true
	player.ability_input_router._unhandled_input(first_event)
	var first_remaining: float = player.motor.dash_time_remaining()

	Input.action_press(&"gizmo_move_left")
	var second_event := InputEventAction.new()
	second_event.action = ACTION_DASH
	second_event.pressed = true
	player.ability_input_router._unhandled_input(second_event)
	Input.action_release(&"gizmo_move_left")

	_check_eq("current kit blocks dash press during DASH", activated_ids, [&"dash"])
	_check_eq("dash press during DASH leaves action state in DASH", player.ability_component.current_action_state(), PlayerActionStateMachine.ActionState.DASH)
	_check_almost("blocked dash during DASH does not restart burst timer", player.motor.dash_time_remaining(), first_remaining)
	_check_vec3_almost("blocked dash during DASH keeps original direction", player.motor.dash_direction(), PlayerMotorScript.DEFAULT_FACING_DIRECTION)

	await _cleanup(player)

func _test_scene_dash_cancels_attack_recovery_end_to_end() -> void:
	var player = await _new_player()
	var activated_ids: Array[StringName] = []
	player.ability_component.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	var attack_event := InputEventAction.new()
	attack_event.action = &"gizmo_attack"
	attack_event.pressed = true
	player.ability_input_router._unhandled_input(attack_event)
	_check_eq("attack press puts scene AbilityComponent in ATTACK", player.ability_component.current_action_state(), PlayerActionStateMachine.ActionState.ATTACK)

	Input.action_press(&"gizmo_move_right")
	var dash_event := InputEventAction.new()
	dash_event.action = ACTION_DASH
	dash_event.pressed = true
	player.ability_input_router._unhandled_input(dash_event)
	Input.action_release(&"gizmo_move_right")

	_check_eq("dash-cancel scene path activates attack then dash", activated_ids, [&"attack", &"dash"])
	_check_eq("dash-cancel scene path moves state to DASH", player.ability_component.current_action_state(), PlayerActionStateMachine.ActionState.DASH)
	_check("dash-cancel scene path starts motor burst", player.motor.is_dashing())
	_check_vec3_almost("dash-cancel scene path uses held movement direction", player.motor.dash_direction(), Vector3.RIGHT)

	await _cleanup(player)
