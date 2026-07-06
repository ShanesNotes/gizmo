extends SceneTree

# Headless tests for the action-to-ability input bridge.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_ability_input_tests.gd

const AbilityComponentScript := preload("res://scripts/abilities/ability_component.gd")
const AbilityInputRouterScript := preload("res://scripts/abilities/ability_input_router.gd")
const ACTION_DASH: StringName = &"gizmo_dash"
const ACTION_ATTACK: StringName = &"gizmo_attack"
const ACTION_SPECIAL: StringName = &"gizmo_special"
const ACTION_CAST: StringName = &"gizmo_cast"

class RetryFailingAbilityComponent:
	extends AbilityComponent

	var reported_state: PlayerActionStateMachine.ActionState = PlayerActionStateMachine.ActionState.ATTACK
	var activation_attempts: Array[StringName] = []

	func try_activate(ability_id: StringName, _direction: Vector3 = Vector3.ZERO) -> bool:
		activation_attempts.append(ability_id)
		if activation_attempts.size() > 1:
			reported_state = PlayerActionStateMachine.ActionState.ATTACK
		return false

	func current_action_state() -> PlayerActionStateMachine.ActionState:
		return reported_state

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running ability input tests...")
	await _test_input_map_entries_exist_with_expected_bindings()
	await _test_actions_route_to_matching_abilities()
	await _test_dash_cancels_immediately_and_attack_buffers_until_allowed()
	await _test_latest_buffered_press_wins_without_firing_replaced_action()
	await _test_tick_retry_preserves_original_buffer_expiry()
	await _test_buffer_expires_before_state_allows()
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
	]

	for test_case in cases:
		var harness := await _new_harness()
		var body: Node = harness["body"]
		var kit: AbilityComponent = harness["kit"]
		var router = harness["router"]
		var activated_ids: Array[StringName] = []
		kit.ability_activated.connect(func(ability: Ability) -> void:
			activated_ids.append(ability.ability_id)
		)

		var action: StringName = test_case[0]
		var expected_ability_id: StringName = test_case[1]
		_check("%s routes through router" % action, router.handle_action_pressed(action, Vector3.RIGHT))
		_check_eq("%s activates matching ability" % action, activated_ids, [expected_ability_id])
		await _cleanup(body)

func _test_dash_cancels_immediately_and_attack_buffers_until_allowed() -> void:
	var harness := await _new_harness()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var router = harness["router"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	var dash := kit.get_ability(&"dash") as DashAbility
	attack.step_recovery = [0.20, 0.20, 0.20]
	dash.cooldown = 0.0
	dash.dash_duration = 0.05
	var activated_ids: Array[StringName] = []
	kit.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	_check("initial attack starts through router", router.handle_action_pressed(ACTION_ATTACK))
	_check_eq("attack puts the component in ATTACK", kit.current_action_state(), PlayerActionStateMachine.ActionState.ATTACK)
	_check("second attack press during recovery does not fire immediately", not router.handle_action_pressed(ACTION_ATTACK))
	_check("second attack press is buffered", router.has_buffered_action())
	_check_eq("buffer records attack action", router.buffered_action(), ACTION_ATTACK)
	_check("dash press during attack recovery fires immediately", router.handle_action_pressed(ACTION_DASH, Vector3.RIGHT))
	_check_eq("dash cancel takes over the action state", kit.current_action_state(), PlayerActionStateMachine.ActionState.DASH)
	_check_eq("only attack and dash have fired before dash ends", activated_ids, [&"attack", &"dash"])

	kit.tick(0.04)
	router.tick(0.04)
	_check_eq("buffer waits while dash is still active", activated_ids, [&"attack", &"dash"])
	kit.tick(0.02)
	router.tick(0.02)
	_check_eq("buffered attack fires once the state allows it", activated_ids, [&"attack", &"dash", &"attack"])
	_check("buffer clears after firing", not router.has_buffered_action())
	await _cleanup(body)

func _test_latest_buffered_press_wins_without_firing_replaced_action() -> void:
	var harness := await _new_harness()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var router = harness["router"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	attack.step_recovery = [0.10, 0.10, 0.10]
	router.buffer_seconds = 0.20
	var activated_ids: Array[StringName] = []
	kit.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	_check("first attack starts before overwrite test", router.handle_action_pressed(ACTION_ATTACK))
	_check("attack press during recovery buffers first candidate", not router.handle_action_pressed(ACTION_ATTACK))
	_check_eq("first candidate is attack", router.buffered_action(), ACTION_ATTACK)
	_check("cast press during same recovery replaces buffered action", not router.handle_action_pressed(ACTION_CAST))
	_check_eq("latest buffered candidate is cast", router.buffered_action(), ACTION_CAST)

	kit.tick(0.11)
	router.tick(0.11)

	_check_eq("window open fires latest buffered cast only", activated_ids, [&"attack", &"cast"])
	_check("buffer clears after latest buffered cast fires", not router.has_buffered_action())
	await _cleanup(body)

func _test_tick_retry_preserves_original_buffer_expiry() -> void:
	var body := Node.new()
	body.name = "RetryFailingInputHarness"
	root.add_child(body)
	var kit := RetryFailingAbilityComponent.new()
	body.add_child(kit)
	var router = AbilityInputRouterScript.new()
	router.buffer_seconds = 0.15
	router.bind_component(kit)
	body.add_child(router)
	await process_frame

	_check("busy fake component buffers the initial attack press", not router.handle_action_pressed(ACTION_ATTACK))
	_check_eq("retry test starts with one activation attempt", kit.activation_attempts.size(), 1)
	_check("retry test has a live buffer", router.has_buffered_action())

	kit.reported_state = PlayerActionStateMachine.ActionState.IDLE
	router.tick(0.05)
	_check_eq("tick retry attempted the buffered attack once", kit.activation_attempts.size(), 2)
	_check("failed retry keeps the original buffer live", router.has_buffered_action())
	_check("failed retry does not refresh the buffer window", router.buffer_time_remaining() <= 0.101)

	kit.reported_state = PlayerActionStateMachine.ActionState.IDLE
	router.tick(0.11)
	_check("original buffer expires after its first input window", not router.has_buffered_action())
	_check_eq("expired retry does not attempt again", kit.activation_attempts.size(), 2)
	await _cleanup(body)

func _test_buffer_expires_before_state_allows() -> void:
	var harness := await _new_harness()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var router = harness["router"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	attack.step_recovery = [0.35, 0.35, 0.35]
	router.buffer_seconds = 0.15
	var activated_ids: Array[StringName] = []
	kit.ability_activated.connect(func(ability: Ability) -> void:
		activated_ids.append(ability.ability_id)
	)

	_check("long attack starts through router", router.handle_action_pressed(ACTION_ATTACK))
	_check("attack press during long recovery is buffered", not router.handle_action_pressed(ACTION_ATTACK))
	_check("buffer is active before expiry", router.has_buffered_action())
	kit.tick(0.16)
	router.tick(0.16)
	_check("buffer expires while attack is still locked", not router.has_buffered_action())
	kit.tick(0.25)
	router.tick(0.25)
	_check_eq("expired buffered attack never fires", activated_ids, [&"attack"])
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
