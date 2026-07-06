extends SceneTree

# Headless tests for the Hades-pivot player ability kit scaffolding.
# Run with:
#   godot --headless --user-data-dir /tmp/godot-user --path godot --script res://tests/run_ability_kit_tests.gd

const AbilityComponentScript := preload("res://scripts/abilities/ability_component.gd")
const AttackAbilityScript := preload("res://scripts/abilities/attack_ability.gd")
const DashAbilityScript := preload("res://scripts/abilities/dash_ability.gd")
const SpecialAbilityScript := preload("res://scripts/abilities/special_ability.gd")
const CastAbilityScript := preload("res://scripts/abilities/cast_ability.gd")
const PlayerActionStateMachineScript := preload("res://scripts/abilities/player_action_state_machine.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running ability-kit tests...")
	await _test_dash_grants_iframes_for_its_duration()
	await _test_attack_combo_chains_within_window_and_resets_after()
	await _test_special_respects_resource_cost_and_cooldown()
	await _test_cast_ammo_consumes_reclaims_and_empty_fails()
	await _test_dash_cancel_from_attack_without_opening_other_interrupts()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL — %d passed, %d failed%s" % [_passed, _failed, " (0 checks ⇒ ability kit failed to load/compile)" if _passed == 0 else ""])
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

func _new_kit() -> Dictionary:
	var body := CharacterBody3D.new()
	body.name = "AbilityKitHarnessBody"
	root.add_child(body)
	var kit: AbilityComponent = AbilityComponentScript.new()
	body.add_child(kit)
	await process_frame
	return {"body": body, "kit": kit}

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_dash_grants_iframes_for_its_duration() -> void:
	var harness := await _new_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var activated := kit.try_activate(&"dash", Vector3.RIGHT)
	_check("dash activates from idle", activated)
	_check("dash immediately grants i-frames", kit.is_invulnerable())
	kit.tick(0.09)
	_check("dash i-frames remain active before dash duration ends", kit.is_invulnerable())
	kit.tick(0.10)
	_check("dash i-frames end after the dash duration", not kit.is_invulnerable())
	await _cleanup(body)

func _test_attack_combo_chains_within_window_and_resets_after() -> void:
	var harness := await _new_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	attack.combo_window = 0.45
	attack.step_recovery = [0.05, 0.05, 0.05]

	_check("first attack activates", kit.try_activate(&"attack"))
	_check_eq("first attack starts combo step 1", kit.combo_step(), 1)
	kit.tick(0.06)
	_check("second attack chains inside combo window", kit.try_activate(&"attack"))
	_check_eq("second attack advances combo step", kit.combo_step(), 2)
	kit.tick(0.50)
	_check_eq("combo resets after the chain window expires", kit.combo_step(), 0)
	_check("next attack after reset activates", kit.try_activate(&"attack"))
	_check_eq("next attack restarts at combo step 1", kit.combo_step(), 1)
	await _cleanup(body)

func _test_special_respects_resource_cost_and_cooldown() -> void:
	var harness := await _new_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var special := kit.get_ability(&"special") as SpecialAbility
	special.cost = 30.0
	special.cooldown = 0.40
	special.cast_time = 0.0
	special.recovery_time = 0.05
	kit.set_resource(&"spark_charge", 40.0)

	_check("special activates with enough resource", kit.try_activate(&"special"))
	_check_eq("special spends its resource cost", kit.get_resource(&"spark_charge"), 10.0)
	kit.tick(0.06)
	_check("special cannot activate while on cooldown", not kit.try_activate(&"special"))
	kit.tick(0.40)
	_check("special cannot activate without enough resource after cooldown", not kit.try_activate(&"special"))
	kit.set_resource(&"spark_charge", 30.0)
	_check("special activates again after resource and cooldown recover", kit.try_activate(&"special"))
	await _cleanup(body)

func _test_cast_ammo_consumes_reclaims_and_empty_fails() -> void:
	var harness := await _new_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var cast := kit.get_ability(&"cast") as CastAbility
	cast.max_ammo = 2
	cast.cooldown = 99.0
	cast.cast_time = 0.0
	cast.recovery_time = 0.05
	var reclaim_events: Array[int] = []
	kit.cast_ammo_reclaimed.connect(func(amount: int, _current_ammo: int, _lodged_ammo: int) -> void:
		reclaim_events.append(amount)
	)

	_check_eq("cast starts with max ammo stones", kit.cast_ammo(), 2)
	_check_eq("cast reports configured max ammo", kit.cast_max_ammo(), 2)
	_check("first cast activates with ammo", kit.try_activate(&"cast"))
	_check_eq("first cast consumes one available stone", kit.cast_ammo(), 1)
	_check_eq("first cast lodges one stone", kit.cast_lodged_ammo(), 1)
	kit.tick(0.06)
	_check("cast does not start a time cooldown", not kit.is_on_cooldown(&"cast"))
	_check("second cast activates with remaining ammo", kit.try_activate(&"cast"))
	_check_eq("second cast consumes the last stone", kit.cast_ammo(), 0)
	_check_eq("second cast lodges both stones", kit.cast_lodged_ammo(), 2)
	kit.tick(0.06)
	_check("cast with zero stones fails", not kit.try_activate(&"cast"))
	_check_eq("failed empty cast does not change lodged stones", kit.cast_lodged_ammo(), 2)
	_check_eq("reclaim returns one lodged stone", kit.reclaim_cast_ammo(1), 1)
	_check_eq("reclaimed stone is available", kit.cast_ammo(), 1)
	_check_eq("reclaim leaves one lodged stone behind", kit.cast_lodged_ammo(), 1)
	_check_eq("reclaim signal reports the reclaimed count", reclaim_events, [1])
	_check("cast can fire again after reclaim", kit.try_activate(&"cast"))
	_check_eq("re-fired reclaimed stone lodges again", kit.cast_lodged_ammo(), 2)
	await _cleanup(body)

func _test_dash_cancel_from_attack_without_opening_other_interrupts() -> void:
	var harness := await _new_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var attack := kit.get_ability(&"attack") as AttackAbility
	var dash := kit.get_ability(&"dash") as DashAbility
	attack.step_recovery = [0.50, 0.50, 0.50]
	dash.cooldown = 0.0
	dash.dash_duration = 0.10
	var transitions: Array[Array] = []
	kit.state_machine.state_changed.connect(func(previous_state: int, new_state: int) -> void:
		transitions.append([previous_state, new_state])
	)

	_check("attack activates from idle", kit.try_activate(&"attack"))
	_check_eq("attack puts the FSM in ATTACK", kit.current_action_state(), PlayerActionStateMachine.ActionState.ATTACK)
	_check("dash cancels attack recovery immediately", kit.try_activate(&"dash", Vector3.RIGHT))
	_check_eq("dash interrupt moves the FSM to DASH", kit.current_action_state(), PlayerActionStateMachine.ActionState.DASH)
	_check(
		"dash interrupt emits ATTACK -> DASH state_changed",
		transitions.has([PlayerActionStateMachine.ActionState.ATTACK, PlayerActionStateMachine.ActionState.DASH])
	)
	kit.tick(0.11)
	_check_eq("dash finishes back to IDLE", kit.current_action_state(), PlayerActionStateMachine.ActionState.IDLE)

	_check("attack can start again after dash finishes", kit.try_activate(&"attack"))
	_check("attack cannot cancel attack", not kit.try_activate(&"attack"))
	_check_eq("blocked attack interrupt leaves FSM in ATTACK", kit.current_action_state(), PlayerActionStateMachine.ActionState.ATTACK)
	kit.enter_hitstun(0.30)
	_check_eq("hitstun takes over the FSM", kit.current_action_state(), PlayerActionStateMachine.ActionState.HITSTUN)
	_check("dash cannot cancel hitstun", not kit.try_activate(&"dash", Vector3.RIGHT))
	_check("attack cannot cancel hitstun", not kit.try_activate(&"attack"))
	_check_eq("blocked hitstun interrupts leave FSM in HITSTUN", kit.current_action_state(), PlayerActionStateMachine.ActionState.HITSTUN)
	await _cleanup(body)
