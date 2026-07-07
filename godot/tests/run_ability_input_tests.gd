extends SceneTree

# Headless tests for the action-to-ability input bridge.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_ability_input_tests.gd

const AbilityComponentScript := preload("res://scripts/abilities/ability_component.gd")
const AbilityInputRouterScript := preload("res://scripts/abilities/ability_input_router.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")
const ACTION_DASH: StringName = &"gizmo_dash"
const ACTION_ATTACK: StringName = &"gizmo_attack"
const ACTION_SPECIAL: StringName = &"gizmo_special"
const ACTION_CAST: StringName = &"gizmo_cast"
const ACTION_SURGE: StringName = &"gizmo_surge"

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running ability input tests...")
	await _test_input_map_entries_exist_with_expected_bindings()
	await _test_actions_route_to_matching_abilities()
	await _test_attack_router_press_uses_component_buffer()
	await _test_dash_router_press_clears_component_attack_buffer()
	await _test_router_leaves_non_attack_failures_unbuffered()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL - %d passed, %d failed%s" % [_passed, _failed, " (0 checks => ability input tests failed to load/compile)" if _passed == 0 else ""])
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

func _new_harness() -> Dictionary:
	var body := CharacterBody3D.new()
	body.name = "AbilityInputHarnessBody"
	root.add_child(body)

	var kit: AbilityComponent = AbilityComponentScript.new()
	body.add_child(kit)
	await process_frame

	var router := AbilityInputRouterScript.new()
	router.bind_component(kit)
	body.add_child(router)
	return {"body": body, "kit": kit, "router": router}

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_input_map_entries_exist_with_expected_bindings() -> void:
	_check("gizmo_dash action exists", InputMap.has_action(&"gizmo_dash"))
	_check("gizmo_dash is bound to Space", _has_key_binding(&"gizmo_dash", KEY_SPACE))
	_check("gizmo_attack action exists", InputMap.has_action(&"gizmo_attack"))
	_check("gizmo_attack is bound to left mouse", _has_mouse_button_binding(&"gizmo_attack", MOUSE_BUTTON_LEFT))
	_check("gizmo_special action exists", InputMap.has_action(&"gizmo_special"))
	_check("gizmo_special is bound to right mouse", _has_mouse_button_binding(&"gizmo_special", MOUSE_BUTTON_RIGHT))
	_check("gizmo_cast action exists", InputMap.has_action(&"gizmo_cast"))
	_check("gizmo_cast is bound to Q", _has_key_binding(&"gizmo_cast", KEY_Q))
	_check("gizmo_surge action exists", InputMap.has_action(&"gizmo_surge"))
	_check("gizmo_surge is bound to F", _has_key_binding(&"gizmo_surge", KEY_F))
	_check("gizmo_move_up action exists", InputMap.has_action(&"gizmo_move_up"))
	_check("gizmo_move_up is bound to W", _has_key_binding(&"gizmo_move_up", KEY_W))
	_check("gizmo_move_down action exists", InputMap.has_action(&"gizmo_move_down"))
	_check("gizmo_move_down is bound to S", _has_key_binding(&"gizmo_move_down", KEY_S))
	_check("gizmo_move_left action exists", InputMap.has_action(&"gizmo_move_left"))
	_check("gizmo_move_left is bound to A", _has_key_binding(&"gizmo_move_left", KEY_A))
	_check("gizmo_move_right action exists", InputMap.has_action(&"gizmo_move_right"))
	_check("gizmo_move_right is bound to D", _has_key_binding(&"gizmo_move_right", KEY_D))
	_check("gizmo_mouse_aim reserved action exists", InputMap.has_action(&"gizmo_mouse_aim"))

func _test_actions_route_to_matching_abilities() -> void:
	var cases: Array[Array] = [
		[ACTION_DASH, &"dash"],
		[ACTION_ATTACK, &"attack"],
		[ACTION_SPECIAL, &"special"],
		[ACTION_CAST, &"cast"],
		[ACTION_SURGE, &"surge"],
	]

	for test_case in cases:
		var harness := await _new_harness()
		var body: Node = harness["body"]
		var kit: AbilityComponent = harness["kit"]
		var router = harness["router"]
		var activated_ids: Array[StringName] = []
		if test_case[1] == &"surge":
			var vitals: PlayerVitals = PlayerVitalsScript.new()
			vitals.name = "PlayerVitals"
			body.add_child(vitals)
			await process_frame
			if vitals.has_method("set_spark_surge_charge"):
				vitals.set("spark_surge_charge_max", 100.0)
				vitals.call("set_spark_surge_charge", 100.0)
		kit.ability_activated.connect(func(ability: Ability) -> void:
			activated_ids.append(ability.ability_id)
		)

		var action: StringName = test_case[0]
		var expected_ability_id: StringName = test_case[1]
		_check("%s routes through router" % action, router.handle_action_pressed(action, Vector3.RIGHT))
		_check_eq("%s activates matching ability" % action, activated_ids, [expected_ability_id])
		await _cleanup(body)

func _test_attack_router_press_uses_component_buffer() -> void:
	var harness := await _new_harness()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var router = harness["router"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	attack.step_recovery = [0.10, 0.10, 0.10]
	var activated_ids: Array[StringName] = []
	kit.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	_check("initial attack starts through router", router.handle_action_pressed(ACTION_ATTACK))
	_check_eq("attack puts the component in ATTACK", kit.current_action_state(), PlayerActionStateMachine.ActionState.ATTACK)
	_check("second attack press during recovery does not fire immediately", not router.handle_action_pressed(ACTION_ATTACK))
	_check("second attack press is buffered by the component", kit.has_buffered_attack())
	kit.tick(0.11)
	_check_eq("component buffer auto-fires attack through kit tick", activated_ids, [&"attack", &"attack"])
	_check("component buffer clears after firing", not kit.has_buffered_attack())
	await _cleanup(body)

func _test_dash_router_press_clears_component_attack_buffer() -> void:
	var harness := await _new_harness()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var router = harness["router"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	var dash := kit.get_ability(&"dash") as DashAbility
	attack.step_recovery = [0.10, 0.10, 0.10]
	dash.cooldown = 0.0
	dash.dash_duration = 0.05
	var activated_ids: Array[StringName] = []
	kit.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	_check("dash-clear router test starts attack", router.handle_action_pressed(ACTION_ATTACK))
	_check("dash-clear router test buffers second attack", not router.handle_action_pressed(ACTION_ATTACK))
	_check("dash-clear router test has component attack buffer", kit.has_buffered_attack())
	_check("dash press during attack recovery fires immediately", router.handle_action_pressed(ACTION_DASH, Vector3.RIGHT))
	_check_eq("dash cancel takes over the action state", kit.current_action_state(), PlayerActionStateMachine.ActionState.DASH)
	_check_eq("only attack and dash have fired before dash ends", activated_ids, [&"attack", &"dash"])
	_check("dash activation clears the component attack buffer", not kit.has_buffered_attack())
	kit.tick(0.20)
	_check_eq("cleared component buffer never auto-fires after dash", activated_ids, [&"attack", &"dash"])
	await _cleanup(body)

func _test_router_leaves_non_attack_failures_unbuffered() -> void:
	var harness := await _new_harness()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var router = harness["router"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	attack.step_recovery = [0.10, 0.10, 0.10]
	var activated_ids: Array[StringName] = []
	kit.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	_check("non-attack router test starts attack", router.handle_action_pressed(ACTION_ATTACK))
	_check("special press during attack recovery fails", not router.handle_action_pressed(ACTION_SPECIAL))
	_check("special press through router does not create attack buffer", not kit.has_buffered_attack())
	_check("cast press during attack recovery fails", not router.handle_action_pressed(ACTION_CAST))
	_check("cast press through router does not create attack buffer", not kit.has_buffered_attack())
	_check_eq("non-attack failed presses do not activate", activated_ids, [&"attack"])
	await _cleanup(body)

func _has_key_binding(action: StringName, physical_keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.physical_keycode == physical_keycode:
				return true
	return false

func _has_mouse_button_binding(action: StringName, button_index: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			var mouse_event := event as InputEventMouseButton
			if mouse_event.button_index == button_index:
				return true
	return false
