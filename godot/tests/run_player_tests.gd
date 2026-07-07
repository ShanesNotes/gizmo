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
	await _test_player_collision_shape_contract_is_byte_identical()
	await _test_player_visual_faces_motor_direction_smoothly()
	await _test_player_visual_idle_bob_and_movement_lean()
	_test_animation_controller_state_to_clip_mapping()
	await _test_animation_controller_builds_clip_library_on_rig()
	await _test_animation_controller_follows_action_states()
	await _test_weapon_mount_attaches_to_right_hand()
	_test_player_vitals_halo_ce_defaults()
	_test_player_vitals_guard_recharges_after_damage_delay()
	_test_player_vitals_shield_break_grace_and_hp_blocks()
	_test_player_vitals_hp_never_regens_while_shield_does()
	_test_player_vitals_death_after_hull_blocks_deplete()
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
	_check("placeholder Capsule mesh has been removed from player visual", player.get_node_or_null("VisualPivot/Capsule") == null)
	_check("gizmo.glb Model node is wired under VisualPivot", player.get_node_or_null("VisualPivot/Model") is Node3D)
	var visual := player.get_node_or_null("VisualPivot") as Node3D
	_check("VisualPivot owns the procedural visual script", visual != null and visual.has_method("update_visual"))
	_check("VisualPivot can report its motor-facing forward direction", visual != null and visual.has_method("visual_forward_direction"))
	var model := player.get_node_or_null("VisualPivot/Model") as Node3D
	if model != null:
		_check_vec3_almost("gizmo.glb is scaled to the old 1.75m placeholder height", model.scale, Vector3(0.875, 0.875, 0.875))
		_check_almost("gizmo.glb authored +Z is flipped to the motor -Z forward convention", absf(model.rotation.y), PI, 0.001)
		_check("gizmo.glb skeleton imports under the Model node", model.get_node_or_null("UniRigArmature/Skeleton3D") is Skeleton3D)
	_check("AbilityComponent node exists", player.get_node_or_null("AbilityComponent") is AbilityComponent)
	_check("AbilityInputRouter node exists", player.get_node_or_null("AbilityInputRouter") is AbilityInputRouter)
	_check("router is bound to the scene AbilityComponent", player.ability_input_router.ability_component == player.ability_component)
	_check_almost("scene dash duration is Hades-spec ~0.25s", player.motor.dash_duration, 0.25)
	_check("legacy root turn_speed export is fully removed (GizmoVisual owns facing)", not ("turn_speed" in player))
	_check("scene root is tagged for player-only trigger filters", player.is_in_group(&"player"))

	await _cleanup(player)

func _test_player_collision_shape_contract_is_byte_identical() -> void:
	var scene_text := FileAccess.get_file_as_string("res://scenes/gizmo_player.tscn")
	_check(
		"collision CapsuleShape3D text block is byte-identical",
		scene_text.contains("[sub_resource type=\"CapsuleShape3D\" id=\"CapsuleShape3D_player\"]\nradius = 0.38\nheight = 1.1\n")
	)
	_check(
		"CollisionShape3D node text block is byte-identical",
		scene_text.contains("[node name=\"CollisionShape3D\" type=\"CollisionShape3D\" parent=\".\"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.875, 0)\nshape = SubResource(\"CapsuleShape3D_player\")\n")
	)

	var player = await _new_player()
	var collision_shape := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_check("collision node is still live after visual swap", collision_shape != null)
	if collision_shape != null:
		_check_vec3_almost("collision node position remains unchanged", collision_shape.position, Vector3(0.0, 0.875, 0.0))
		var capsule_shape := collision_shape.shape as CapsuleShape3D
		_check("collision shape remains a CapsuleShape3D", capsule_shape != null)
		if capsule_shape != null:
			_check_almost("collision capsule radius remains unchanged", capsule_shape.radius, 0.38)
			_check_almost("collision capsule height remains unchanged", capsule_shape.height, 1.1)
	await _cleanup(player)

func _test_player_visual_faces_motor_direction_smoothly() -> void:
	var player = await _new_player()
	var visual := player.get_node_or_null("VisualPivot") as Node3D
	_check("visual script is present for facing test", visual != null and visual.has_method("update_visual"))
	if visual == null or not visual.has_method("update_visual"):
		await _cleanup(player)
		return

	visual.set("turn_speed", 10.0)
	player.motor.facing_direction = Vector3(0.0, 0.0, -1.0)
	visual.call("update_visual", 1.0)
	var initial_forward := Vector3(visual.call("visual_forward_direction"))
	_check_vec3_almost("visual starts on the motor default -Z facing", initial_forward, Vector3(0.0, 0.0, -1.0), 0.01)

	player.motor.facing_direction = Vector3.RIGHT
	visual.call("update_visual", 0.016)
	var first_turn_forward := Vector3(visual.call("visual_forward_direction"))
	_check("visual begins turning toward motor facing direction", first_turn_forward.x > 0.05)
	_check("visual turn is smoothed rather than snapped", first_turn_forward.dot(Vector3.RIGHT) < 0.98)

	visual.call("update_visual", 0.5)
	var settled_forward := Vector3(visual.call("visual_forward_direction"))
	_check("visual settles facing the motor direction", settled_forward.dot(Vector3.RIGHT) > 0.98)

	await _cleanup(player)

func _test_player_visual_idle_bob_and_movement_lean() -> void:
	var player = await _new_player()
	var visual := player.get_node_or_null("VisualPivot") as Node3D
	var model := player.get_node_or_null("VisualPivot/Model") as Node3D
	_check("visual script is present for bob test", visual != null and visual.has_method("update_visual"))
	_check("model node is present for bob test", model != null)
	if visual == null or model == null or not visual.has_method("update_visual"):
		await _cleanup(player)
		return

	visual.set("idle_bob_amplitude", 0.05)
	visual.set("idle_bob_frequency_hz", 1.0)
	visual.set("movement_bob_amplitude", 0.0)
	visual.set("lean_response", 100.0)
	_check("visual can reset procedural motion for deterministic bob phase", visual.has_method("reset_procedural_motion"))
	visual.call("reset_procedural_motion")
	var base_y := model.position.y
	visual.call("update_visual", 0.25)
	_check("idle bob raises the model on a sine crest", model.position.y > base_y + 0.045)
	visual.call("update_visual", 0.25)
	_check_almost("idle bob returns near the base height halfway through the cycle", model.position.y, base_y, 0.01)

	player.velocity = Vector3.RIGHT * player.move_speed
	visual.call("update_visual", 0.1)
	_check("movement lean tilts the model into horizontal velocity", absf(model.rotation.z) > 0.05)
	_check("movement lean remains subtle", absf(model.rotation.z) <= 0.35)

	await _cleanup(player)

func _test_animation_controller_state_to_clip_mapping() -> void:
	var Controller := load("res://scripts/player/gizmo_animation_controller.gd")
	_check("GizmoAnimationController script exists", Controller != null)
	if Controller == null:
		return
	_check_eq(
		"IDLE while still maps to idle clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.IDLE, false), &"idle"
	)
	_check_eq(
		"IDLE while moving maps to run clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.IDLE, true), &"run"
	)
	_check_eq(
		"DASH maps to dash clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.DASH, true), &"dash"
	)
	_check_eq(
		"ATTACK maps to the step-1 swing clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.ATTACK, false), &"attack_1"
	)
	_check_eq(
		"SPECIAL maps to its own timed clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.SPECIAL, false), &"special"
	)
	_check_eq(
		"CAST maps to the step-1 swing clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.CAST, false), &"attack_1"
	)
	_check_eq(
		"HITSTUN maps to hit_react clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.HITSTUN, true), &"hit_react"
	)
	_check_eq(
		"SURGE maps to surge clip",
		Controller.clip_for_state(PlayerActionStateMachine.ActionState.SURGE, false), &"surge"
	)

func _test_animation_controller_builds_clip_library_on_rig() -> void:
	var player = await _new_player()
	var controller: Node = player.get_node_or_null("AnimationController")
	_check("AnimationController node exists in gizmo_player.tscn", controller != null)
	if controller == null:
		await _cleanup(player)
		return

	var anim_player := controller.get("animation_player") as AnimationPlayer
	_check("controller builds an AnimationPlayer on ready", anim_player != null)
	if anim_player == null:
		await _cleanup(player)
		return

	for clip_name in [&"idle", &"run", &"dash", &"attack_1", &"attack_2", &"attack_3", &"special", &"hit_react", &"surge"]:
		_check("clip library contains %s" % clip_name, anim_player.has_animation("gizmo/%s" % clip_name))
	var idle_clip := anim_player.get_animation("gizmo/idle")
	var run_clip := anim_player.get_animation("gizmo/run")
	var attack_clip := anim_player.get_animation("gizmo/attack_1")
	var dash_clip := anim_player.get_animation("gizmo/dash")
	if idle_clip != null and run_clip != null and attack_clip != null and dash_clip != null:
		_check("idle clip loops", idle_clip.loop_mode == Animation.LOOP_LINEAR)
		_check("run clip loops", run_clip.loop_mode == Animation.LOOP_LINEAR)
		_check("attack clip is one-shot", attack_clip.loop_mode == Animation.LOOP_NONE)
		_check("dash clip is one-shot", dash_clip.loop_mode == Animation.LOOP_NONE)
		# Effective cadence = clip length / RUN_EAGERNESS playback multiplier: the
		# authored 0.72s walk cycle still plays as Gizmo's eager patter.
		var eagerness := float(controller.get("RUN_EAGERNESS"))
		_check("run cadence plays as a quick patter (<= 0.6s effective cycle)", run_clip.length / maxf(eagerness, 0.001) <= 0.6)
		_check("clips carry bone rotation tracks", idle_clip.get_track_count() > 0)
	# Arbitration contract (two concurrent animation lanes, one skeleton):
	# when the authored-clip GizmoAnimator is present and not deferring, it owns
	# playback and the fallback controller must be inert; otherwise the fallback
	# controller starts on idle. Exactly one authority, never both.
	var animator: Node = player.get_node_or_null("GizmoAnimator")
	var animator_owns := animator != null and not bool(animator.get("defer_to_fallback_controller"))
	if animator_owns:
		_check_eq("superseded fallback player is stopped by arbitration", anim_player.current_animation, "")
		var tree := animator.get("animation_tree") as AnimationTree
		_check("authored-clip AnimationTree is the single live authority", tree != null and tree.active)
		_check("arbitration disables fallback controller processing", controller.process_mode == Node.PROCESS_MODE_DISABLED)
	else:
		_check_eq("controller starts on the idle clip", anim_player.current_animation, "gizmo/idle")
	await _cleanup(player)

func _test_animation_controller_follows_action_states() -> void:
	var player = await _new_player()
	var controller: Node = player.get_node_or_null("AnimationController")
	var anim_player: AnimationPlayer = null
	if controller != null:
		anim_player = controller.get("animation_player") as AnimationPlayer
	_check("controller + AnimationPlayer present for state-follow test", anim_player != null)
	if anim_player == null:
		await _cleanup(player)
		return

	player.velocity = Vector3.RIGHT * player.move_speed
	controller.call("update_animation", 0.016)
	_check_eq("full-speed movement plays the run clip", anim_player.current_animation, "gizmo/run")
	_check("run clip speed scales with velocity", anim_player.speed_scale > 0.9)

	player.velocity = Vector3.ZERO
	controller.call("update_animation", 0.016)
	_check_eq("standing still returns to the idle clip", anim_player.current_animation, "gizmo/idle")

	var event := InputEventAction.new()
	event.action = ACTION_DASH
	event.pressed = true
	player.ability_input_router._unhandled_input(event)
	controller.call("update_animation", 0.016)
	_check_eq("dash press plays the dash clip", anim_player.current_animation, "gizmo/dash")

	await _cleanup(player)

func _test_weapon_mount_attaches_to_right_hand() -> void:
	var player = await _new_player()
	var skeleton := player.get_node_or_null("VisualPivot/Model/UniRigArmature/Skeleton3D") as Skeleton3D
	_check("skeleton present for weapon mount test", skeleton != null)
	if skeleton == null:
		await _cleanup(player)
		return
	var mount := skeleton.get_node_or_null("WeaponMount") as BoneAttachment3D
	_check("WeaponMount BoneAttachment3D exists under the skeleton", mount != null)
	if mount != null:
		# Swing clips are code-owned since the SwingTiming sync (playtest 2), so
		# the mount always rides the code-built swing arm's hand bone.
		_check_eq("WeaponMount rides the swing-arm hand bone", mount.bone_name, "Bone_024")
		_check("WeaponMount carries a weapon model", mount.get_child_count() > 0)
	# Never two visible wrenches: the arbitration winner's mount is the only
	# visible one (GizmoAnimator hides the fallback WeaponMount when it owns).
	var animator_mount := skeleton.get_node_or_null("GizmoWeaponMount") as BoneAttachment3D
	if animator_mount != null and mount != null:
		_check("exactly one weapon mount is visible", not mount.visible)
	await _cleanup(player)

## Halo-CE vitals model (playtest 2 verdict): guard is a flat recharging
## shield BAR in shield points; hp is a small stack of hull BLOCKS that tick
## exactly one per shield-broken hit and never regenerate in-run.
func _test_player_vitals_halo_ce_defaults() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	_check_eq("default hull is 3 blocks", vitals.max_hp, 3)
	_check_eq("default shield bar is 100 points", vitals.max_guard, 100)
	_check_almost("default shield recharge delay is 2.5s", vitals.guard_recharge_delay, 2.5)
	_check_almost("default shield recharge rate refills in 2.5s", vitals.guard_recharge_rate, 40.0)
	_check_almost("default damage lockout is a short mercy window", vitals.damage_lockout, 0.6)
	vitals.free()

func _test_player_vitals_shield_break_grace_and_hp_blocks() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	vitals.max_hp = 3
	vitals.max_guard = 4
	vitals.guard_recharge_delay = 99.0
	vitals.damage_lockout = 0.5
	vitals.reset()

	var result := vitals.apply_damage(9)
	_check_eq("overkill hit breaks the shield to zero", vitals.guard, 0)
	_check_eq("shield-break overflow never reaches the hull (grace)", vitals.hp, 3)
	_check_eq("break hit reports only absorbed shield", int(result["absorbed"]), 4)
	_check_eq("break hit reports zero hull damage", int(result["hp_damage"]), 0)

	vitals.tick_guard_recharge(0.51)
	result = vitals.apply_damage(9)
	_check_eq("shield-down heavy hit ticks exactly one hull block", vitals.hp, 2)
	_check_eq("shield-down hit reports one block", int(result["hp_damage"]), 1)

	vitals.tick_guard_recharge(0.51)
	vitals.apply_damage(1)
	_check_eq("shield-down light hit also ticks exactly one block", vitals.hp, 1)
	vitals.free()

func _test_player_vitals_hp_never_regens_while_shield_does() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	vitals.max_hp = 3
	vitals.max_guard = 4
	vitals.guard_recharge_delay = 1.0
	vitals.guard_recharge_rate = 4.0
	vitals.damage_lockout = 0.25
	vitals.reset()

	vitals.apply_damage(4)
	vitals.tick_guard_recharge(0.26)
	vitals.apply_damage(1)
	_check_eq("setup: shield broken and one block lost", vitals.hp, 2)

	vitals.tick_guard_recharge(3.0)
	_check_eq("shield bar recharges back to full", vitals.guard, 4)
	_check_eq("hull blocks never regenerate in-run", vitals.hp, 2)

	vitals.refill_guard()
	_check_eq("sanctuary refill restores shield only", vitals.guard, 4)
	_check_eq("sanctuary refill leaves hull blocks untouched", vitals.hp, 2)
	vitals.free()

func _test_player_vitals_death_after_hull_blocks_deplete() -> void:
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	vitals.max_hp = 3
	vitals.max_guard = 4
	vitals.guard_recharge_delay = 99.0
	vitals.damage_lockout = 0.25
	vitals.reset()

	vitals.apply_damage(99)
	for i in range(3):
		vitals.tick_guard_recharge(0.26)
		vitals.apply_damage(99)
	_check_eq("three shield-down hits empty the hull", vitals.hp, 0)
	_check_eq("hull depletion marks the player dead", vitals.is_dead(), true)
	vitals.free()

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
	vitals.guard_recharge_delay = 99.0
	vitals.damage_lockout = 0.25
	vitals.reset()
	vitals.call("set_spark_surge_charge", 80.0)
	vitals.apply_damage(vitals.max_guard)
	for i in range(vitals.max_hp):
		vitals.tick_guard_recharge(0.26)
		vitals.apply_damage(1)
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
