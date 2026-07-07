extends SceneTree

# Headless tests for HZ-017 greybox enemy entity + chase AI.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_enemy_tests.gd

const EnemyArchetypesScript := preload("res://scripts/enemies/enemy_archetypes.gd")
const EnemyBrainScript := preload("res://scripts/enemies/enemy_brain.gd")
const AttackAbilityScript := preload("res://scripts/abilities/attack_ability.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")
const GreyboxEnemyScene := preload("res://scenes/enemies/greybox_enemy.tscn")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running enemy tests...")
	await _test_archetype_stats_match_balance_bands()
	await _test_archetype_ttk_bands_use_real_melee_kit()
	_test_chaff_strafe_orbits_with_jitter_then_lunges()
	_test_bruiser_shoulders_forward_with_pauses()
	_test_elite_circles_at_range_then_cuts_in()
	_test_aggro_movement_never_stands_still()
	_test_movement_personality_is_deterministic_per_seed()
	await _test_contact_cadence_does_not_melt_guard()
	await _test_multi_chaff_contact_respects_guard_pacing()
	await _test_unknown_archetype_falls_back_to_chaff()
	await _test_steering_direction_and_contact_stop()
	await _test_windup_timing_is_deterministic()
	await _test_windup_survives_contact_jitter_but_resets_on_escape()
	await _test_stagger_suppresses_movement_and_attack_until_window()
	await _test_take_damage_emits_died_once()
	await _test_take_damage_spawns_floating_damage_number()
	await _test_contact_damage_spawns_red_player_number()
	await _test_scene_instantiates_headless()
	await _test_scene_visual_models_follow_configured_archetype()
	await _test_visual_motion_identity_per_archetype()
	await _test_visual_hit_recoil_kicks_and_decays()
	await _test_rigged_archetypes_carry_animation_controller()
	await _test_animation_controller_tracks_windup_death_and_locomotion()
	await _test_chaff_windup_wobble_and_death_tumble()
	await _test_spawn_windup_blocks_movement_and_contact_until_elapsed()
	await _test_scene_stagger_ticks_down_during_spawn_windup()
	await _test_scene_chase_emits_damage_event_data_without_player_wiring()
	await _test_physics_process_is_inert_after_exit()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => enemy tests failed to load/compile)" if _passed == 0 else ""]
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

func _check_between(desc: String, value: float, low: float, high: float) -> void:
	_check("%s (%.2f in [%.2f, %.2f])" % [desc, value, low, high], value >= low and value <= high)

func _check_vec3_almost(desc: String, actual: Vector3, expected: Vector3, margin: float = 0.001) -> void:
	_check(
		"%s (got %s, expected %s +/- %.4f)" % [desc, actual, expected, margin],
		actual.distance_to(expected) <= margin
	)

func _new_enemy():
	var enemy = GreyboxEnemyScene.instantiate()
	root.add_child(enemy)
	await process_frame
	return enemy

func _new_configured_enemy(archetype: String, spawn_id: String):
	var enemy = GreyboxEnemyScene.instantiate()
	var collision := enemy.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var collision_shape := collision.shape as CapsuleShape3D if collision != null else null
	var collision_radius := collision_shape.radius if collision_shape != null else -1.0
	var collision_height := collision_shape.height if collision_shape != null else -1.0
	var collision_transform := collision.transform if collision != null else Transform3D.IDENTITY
	root.add_child(enemy)
	enemy.configure(archetype, spawn_id)
	await process_frame
	return {
		"enemy": enemy,
		"collision_radius": collision_radius,
		"collision_height": collision_height,
		"collision_transform": collision_transform,
	}

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_archetype_stats_match_balance_bands() -> void:
	var chaff := EnemyArchetypesScript.stats_for("chaff")
	var bruiser := EnemyArchetypesScript.stats_for("bruiser")
	var elite := EnemyArchetypesScript.stats_for("elite")

	_check("chaff archetype exists", EnemyArchetypesScript.has_archetype("chaff"))
	_check("bruiser archetype exists", EnemyArchetypesScript.has_archetype("bruiser"))
	_check("elite archetype exists", EnemyArchetypesScript.has_archetype("elite"))
	_check_eq("chaff hp is rebased to a two-hit trash value", float(chaff["max_hp"]), 30.0)
	_check_eq("chaff damage is a fifth of the shield bar", int(chaff["damage"]), 20)
	_check_almost("chaff speed salvages nibbler chase band", float(chaff["move_speed"]), 2.1)
	_check_almost("chaff contact radius is tight trash pressure", float(chaff["contact_radius"]), 0.9)
	_check_almost("chaff contact cadence is slower than one pip per second", float(chaff["attack_windup"]) + float(chaff["attack_recovery"]), 2.1)
	_check_almost("chaff budget cost matches director chaff cost", float(chaff["budget_cost"]), 1.0)
	_check_eq("bruiser hp is rebased to a seven-hit priority target", float(bruiser["max_hp"]), 140.0)
	_check_eq("bruiser damage takes a real shield bite, not burst", int(bruiser["damage"]), 30)
	_check_almost("bruiser speed salvages slower priority-target band", float(bruiser["move_speed"]), 1.65)
	_check_almost("bruiser budget cost matches director bruiser cost", float(bruiser["budget_cost"]), 2.4)
	_check_eq("elite hp sits in the 3-10s punctuation band", float(elite["max_hp"]), 640.0)
	_check_eq("elite contact damage is nearly half the shield bar", int(elite["damage"]), 45)
	_check_almost("elite is slower than bruiser", float(elite["move_speed"]), 1.25)
	_check_almost("elite has a larger contact radius", float(elite["contact_radius"]), 1.75)
	_check_almost("elite budget cost matches director elite cost", float(elite["budget_cost"]), 9.0)
	_check("bruiser has more hp than chaff", float(bruiser["max_hp"]) > float(chaff["max_hp"]))
	_check("elite has more hp than bruiser", float(elite["max_hp"]) > float(bruiser["max_hp"]))
	_check("chaff is faster than bruiser", float(chaff["move_speed"]) > float(bruiser["move_speed"]))
	_check("bruiser is faster than elite", float(bruiser["move_speed"]) > float(elite["move_speed"]))

func _test_archetype_ttk_bands_use_real_melee_kit() -> void:
	var attack := AttackAbilityScript.new()
	_check_eq("HZ-071 uses real melee damage [18,20,26]", attack.step_damage, [18.0, 20.0, 26.0])
	_check_eq("HZ-071 uses real melee recoveries [0.16,0.18,0.24]", attack.step_recovery, [0.16, 0.18, 0.24])
	_check_almost("HZ-071 uses real combo window from AttackAbility", attack.combo_window, 0.45)

	var chaff_ttk := _melee_ttk_for_hp(float(EnemyArchetypesScript.stats_for("chaff")["max_hp"]), attack)
	var bruiser_ttk := _melee_ttk_for_hp(float(EnemyArchetypesScript.stats_for("bruiser")["max_hp"]), attack)
	var elite_ttk := _melee_ttk_for_hp(float(EnemyArchetypesScript.stats_for("elite")["max_hp"]), attack)

	_check_between("chaff TTK is in trash band <=0.5s", float(chaff_ttk["seconds"]), 0.0, 0.5)
	_check_between("chaff takes one to two real melee hits", float(chaff_ttk["hits"]), 1.0, 2.0)
	_check_between("bruiser TTK is in 1-3s band", float(bruiser_ttk["seconds"]), 1.0, 3.0)
	_check_between("bruiser takes the ticket's 4-7 real melee hits", float(bruiser_ttk["hits"]), 4.0, 7.0)
	_check_between("elite TTK is in 3-10s band", float(elite_ttk["seconds"]), 3.0, 10.0)
	_check("elite requires meaningfully more hits than bruiser", int(elite_ttk["hits"]) > int(bruiser_ttk["hits"]))

func _test_contact_cadence_does_not_melt_guard() -> void:
	var chaff_events := _contact_damage_events_in_seconds(EnemyArchetypesScript.stats_for("chaff"), 5.0)
	var bruiser_events := _contact_damage_events_in_seconds(EnemyArchetypesScript.stats_for("bruiser"), 5.0)
	var elite_events := _contact_damage_events_in_seconds(EnemyArchetypesScript.stats_for("elite"), 5.0)

	_check("one chaff in contact lands at most three guard pips in five seconds", chaff_events <= 3)
	_check("one bruiser in contact lands at most two guard pips in five seconds", bruiser_events <= 2)
	_check("one elite in contact lands at most two heavier hits in five seconds", elite_events <= 2)

func _test_multi_chaff_contact_respects_guard_pacing() -> void:
	var result := _multi_contact_survival(EnemyArchetypesScript.stats_for("chaff"), [0.0, 0.35, 0.70, 1.05], 30.0)

	_check("four desynced chaff create sustained contact attempts", int(result["damage_attempts"]) >= 12)
	# Halo-CE fragile-but-recharging: standing inside four chaff strips the
	# shield in a fight-or-disengage window and kills only if you stay in it.
	_check_between("four desynced chaff strip the shield in the disengage window", float(result["guard_empty_seconds"]), 3.5, 8.0)
	_check_between("four desynced chaff are lethal only to a player who keeps standing in them", float(result["death_seconds"]), 6.0, 12.0)


# --- movement personality (playtest 2: dynamic AI, never static) --------------

## Advance a brain-driven body from `start` for `seconds`, integrating position
## by the returned velocity. Returns per-frame samples for profile assertions.
func _simulate_brain(stats: Dictionary, seed_value: int, start: Vector3, seconds: float, dt: float = 0.05) -> Array[Dictionary]:
	var brain = EnemyBrainScript.new()
	brain.configure(stats)
	brain.set_behavior_seed(seed_value)
	var pos := start
	var samples: Array[Dictionary] = []
	var elapsed := 0.0
	while elapsed < seconds:
		var result: Dictionary = brain.step(pos, Vector3.ZERO, dt)
		var velocity := Vector3(result["velocity"])
		pos += velocity * dt
		samples.append({
			"pos": pos,
			"velocity": velocity,
			"distance": float(result["distance"]),
			"in_contact": bool(result["in_contact"]),
			"attack_state": String(result["attack_state"]),
			"staggered": brain.is_staggered(),
			"damage_event": result["damage_event"],
		})
		elapsed += dt
	return samples

func _tangential_fraction(sample: Dictionary) -> float:
	var velocity := Vector3(sample["velocity"])
	if velocity.length() <= 0.001:
		return 0.0
	var to_player := -Vector3(sample["pos"])
	to_player.y = 0.0
	if to_player.length() <= 0.001:
		return 0.0
	var cross_y := absf(to_player.normalized().cross(velocity.normalized()).y)
	return cross_y

func _test_chaff_strafe_orbits_with_jitter_then_lunges() -> void:
	var stats := EnemyArchetypesScript.stats_for("chaff")
	var samples := _simulate_brain(stats, 7, Vector3(3.0, 0.0, 0.0), 6.0)

	var early_tangential := 0
	var early_frames := 0
	for i in range(mini(16, samples.size())):
		early_frames += 1
		if _tangential_fraction(samples[i]) > 0.5:
			early_tangential += 1
	_check("chaff opens by strafe-orbiting (mostly tangential velocity)", early_tangential >= early_frames / 2)

	var reached_contact := false
	var lunge_speed := 0.0
	var move_speed := float(stats["move_speed"])
	for sample in samples:
		lunge_speed = maxf(lunge_speed, Vector3(sample["velocity"]).length())
		if bool(sample["in_contact"]):
			reached_contact = true
			break
	_check("chaff commits into contact within six seconds", reached_contact)
	_check("chaff commit is a darting lunge faster than base speed", lunge_speed > move_speed * 1.4)

func _test_bruiser_shoulders_forward_with_pauses() -> void:
	var stats := EnemyArchetypesScript.stats_for("bruiser")
	var samples := _simulate_brain(stats, 11, Vector3(7.0, 0.0, 0.0), 3.5)
	var move_speed := float(stats["move_speed"])
	var full := 0
	var slow := 0
	var statue := 0
	var counted := 0
	for sample in samples:
		if bool(sample["in_contact"]) or String(sample["attack_state"]) != EnemyBrainScript.ATTACK_READY:
			continue
		counted += 1
		var speed := Vector3(sample["velocity"]).length()
		if speed >= move_speed * 0.9:
			full += 1
		elif speed <= move_speed * 0.6:
			slow += 1
		if speed < move_speed * 0.1:
			statue += 1
	_check("bruiser has real shouldering-forward phases", full >= counted / 4)
	_check("bruiser has real hesitation pauses", slow >= counted / 10)
	_check("bruiser pauses drift, never statue-still", statue == 0)

func _test_elite_circles_at_range_then_cuts_in() -> void:
	var stats := EnemyArchetypesScript.stats_for("elite")
	var samples := _simulate_brain(stats, 3, Vector3(5.0, 0.0, 0.0), 12.0)

	var early_tangential := 0
	var early_close := 0
	for i in range(mini(24, samples.size())):
		if _tangential_fraction(samples[i]) > 0.5:
			early_tangential += 1
		if float(samples[i]["distance"]) < 3.0:
			early_close += 1
	_check("elite opens by circling at range", early_tangential >= 12)
	_check("elite holds its ring before the cut-in", early_close == 0)

	var reached_contact := false
	for sample in samples:
		if bool(sample["in_contact"]):
			reached_contact = true
			break
	_check("elite cuts in to contact within twelve seconds", reached_contact)

func _test_aggro_movement_never_stands_still() -> void:
	for archetype in ["chaff", "bruiser", "elite"]:
		var stats := EnemyArchetypesScript.stats_for(archetype)
		var samples := _simulate_brain(stats, 5, Vector3(4.5, 0.0, 0.0), 5.0)
		var move_speed := float(stats["move_speed"])
		var contact_radius := float(stats["contact_radius"])
		var still := 0
		var counted := 0
		for sample in samples:
			if bool(sample["in_contact"]) or bool(sample["staggered"]):
				continue
			if String(sample["attack_state"]) != EnemyBrainScript.ATTACK_READY:
				continue
			# The arrival frame legitimately clamps speed to stop exactly at
			# the contact radius — that is closing in, not standing around.
			if float(sample["distance"]) <= contact_radius + move_speed * 0.05:
				continue
			counted += 1
			if Vector3(sample["velocity"]).length() < move_speed * 0.1:
				still += 1
		_check("%s never stands still in aggro" % archetype, counted > 0 and still == 0)

func _test_movement_personality_is_deterministic_per_seed() -> void:
	var stats := EnemyArchetypesScript.stats_for("chaff")
	var a := _simulate_brain(stats, 9, Vector3(3.0, 0.0, 0.0), 2.0)
	var b := _simulate_brain(stats, 9, Vector3(3.0, 0.0, 0.0), 2.0)
	var c := _simulate_brain(stats, 10, Vector3(3.0, 0.0, 0.0), 2.0)
	var same := true
	for i in range(a.size()):
		if not Vector3(a[i]["pos"]).is_equal_approx(Vector3(b[i]["pos"])):
			same = false
			break
	_check("same behavior seed replays the same movement", same)
	var diverged := false
	for i in range(c.size()):
		if not Vector3(a[i]["pos"]).is_equal_approx(Vector3(c[i]["pos"])):
			diverged = true
			break
	_check("different behavior seeds diverge", diverged)
func _test_unknown_archetype_falls_back_to_chaff() -> void:
	var fallback := EnemyArchetypesScript.stats_for("unknown")

	_check_eq("unknown archetype stats fall back to chaff", String(fallback["archetype"]), "chaff")
	_check_eq("unknown archetype fallback keeps chaff hp", float(fallback["max_hp"]), 30.0)

	var enemy = await _new_enemy()
	enemy.configure("unknown", "spawn-unknown")
	_check_eq("scene configure unknown stores chaff fallback archetype", enemy.archetype, "chaff")
	_check_eq("scene configure unknown keeps spawn id", enemy.spawn_id, "spawn-unknown")
	_check_almost("scene configure unknown applies chaff hp", enemy.hp, 30.0)

	await _cleanup(enemy)

func _test_steering_direction_and_contact_stop() -> void:
	var far := EnemyBrainScript.chase_steering(Vector3.ZERO, Vector3(3.0, 9.0, 4.0), 2.1, 1.0, 0.1)
	_check_vec3_almost("seek direction is flat XZ normalized", Vector3(far["direction"]), Vector3(0.6, 0.0, 0.8))
	_check_vec3_almost("seek velocity follows direction at move speed", Vector3(far["velocity"]), Vector3(1.26, 0.0, 1.68))
	_check_eq("far target is not contact", bool(far["in_contact"]), false)

	var near := EnemyBrainScript.chase_steering(Vector3.ZERO, Vector3(0.5, 3.0, 0.0), 2.1, 1.0, 0.1)
	_check_eq("inside contact radius is contact", bool(near["in_contact"]), true)
	_check_vec3_almost("inside contact radius stops movement", Vector3(near["velocity"]), Vector3.ZERO)

	var clamped := EnemyBrainScript.chase_steering(Vector3.ZERO, Vector3(1.1, 0.0, 0.0), 2.1, 1.0, 0.2)
	_check_eq("just outside contact is still seeking", bool(clamped["in_contact"]), false)
	_check_almost("velocity clamps so one physics tick stops at contact radius", Vector3(clamped["velocity"]).length(), 0.5)

func _test_windup_timing_is_deterministic() -> void:
	var brain = EnemyBrainScript.new()
	brain.configure({
		"move_speed": 2.0,
		"contact_radius": 1.0,
		"damage": 3,
		"attack_windup": 0.30,
		"attack_recovery": 0.50,
	})

	var first: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.10)
	_check_eq("first contact starts windup", String(first["attack_state"]), EnemyBrainScript.ATTACK_WINDUP)
	_check_eq("no damage before windup expires", Dictionary(first["damage_event"]).is_empty(), true)
	_check_almost("windup timer counts down deterministically", brain.attack_timer_remaining(), 0.20)

	var second: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.19)
	_check_eq("still winding up before full duration", String(second["attack_state"]), EnemyBrainScript.ATTACK_WINDUP)
	_check_eq("still no damage at 0.29s", Dictionary(second["damage_event"]).is_empty(), true)

	var third: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.01)
	var event: Dictionary = third["damage_event"]
	_check_eq("damage emits exactly when cumulative windup reaches duration", int(event.get("damage", 0)), 3)
	_check_eq("windup transitions into recovery after poke", String(third["attack_state"]), EnemyBrainScript.ATTACK_RECOVERY)

	var fourth: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.20)
	_check_eq("recovery suppresses immediate repeat damage", Dictionary(fourth["damage_event"]).is_empty(), true)

func _test_windup_survives_contact_jitter_but_resets_on_escape() -> void:
	var brain = EnemyBrainScript.new()
	brain.configure({
		"move_speed": 2.0,
		"contact_radius": 1.0,
		"damage": 3,
		"attack_windup": 0.30,
		"attack_recovery": 0.50,
	})

	brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.10)
	var jitter: Dictionary = brain.step(Vector3.ZERO, Vector3(1.05, 0.0, 0.0), 0.10)
	_check_eq("one-tick nudge outside contact radius does not cancel windup", String(jitter["attack_state"]), EnemyBrainScript.ATTACK_WINDUP)
	_check_eq("jitter frame itself does not deal damage early", Dictionary(jitter["damage_event"]).is_empty(), true)

	var landed: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.10)
	_check_eq("windup still lands after contact jitter", int(Dictionary(landed["damage_event"]).get("damage", 0)), 3)
	_check_eq("landed attack transitions to recovery after jitter", String(landed["attack_state"]), EnemyBrainScript.ATTACK_RECOVERY)

	brain.reset_attack()
	brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.10)
	var escaped: Dictionary = brain.step(Vector3.ZERO, Vector3(1.30, 0.0, 0.0), 0.01)
	_check_eq("escape past release radius resets windup", String(escaped["attack_state"]), EnemyBrainScript.ATTACK_READY)
	_check_almost("escape past release radius clears windup timer", brain.attack_timer_remaining(), 0.0)

func _test_stagger_suppresses_movement_and_attack_until_window() -> void:
	var brain = EnemyBrainScript.new()
	brain.configure({
		"move_speed": 2.0,
		"contact_radius": 1.0,
		"damage": 3,
		"attack_windup": 0.30,
		"attack_recovery": 0.50,
	})
	var has_stagger := brain.has_method("stagger")
	var has_query := brain.has_method("is_staggered")
	_check("EnemyBrain exposes stagger hook", has_stagger)
	_check("EnemyBrain exposes stagger query", has_query)
	if not has_stagger or not has_query:
		return

	brain.call("stagger", 0.25)
	var during: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.24)
	_check_eq("stagger suppresses contact damage", Dictionary(during["damage_event"]).is_empty(), true)
	_check_vec3_almost("stagger suppresses motion", Vector3(during["velocity"]), Vector3.ZERO)
	_check_eq("stagger keeps attack state ready", String(during["attack_state"]), EnemyBrainScript.ATTACK_READY)
	_check_eq("stagger remains active inside window", bool(brain.call("is_staggered")), true)

	var release_frame: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.02)
	_check_eq("stagger release frame still emits no damage", Dictionary(release_frame["damage_event"]).is_empty(), true)
	_check_eq("stagger ends after window", bool(brain.call("is_staggered")), false)
	var after: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), 0.30)
	_check_eq("contact attack resumes after stagger window", int(Dictionary(after["damage_event"]).get("damage", 0)), 3)

func _test_take_damage_emits_died_once() -> void:
	var enemy = await _new_enemy()
	enemy.configure("bruiser", "w0:bruiser:7")
	var death_ids: Array[String] = []
	enemy.died.connect(func(dead_spawn_id: String) -> void:
		death_ids.append(dead_spawn_id)
	)

	_check_almost("configured bruiser starts at bruiser hp", enemy.hp, 140.0)
	_check_almost("partial damage returns remaining hp", enemy.take_damage(40.0), 100.0)
	_check_eq("partial damage does not emit died", death_ids.size(), 0)
	var enemy_death_before := _audio_event_count(&"enemy_death")
	_check_almost("lethal damage floors hp at zero", enemy.take_damage(999.0), 0.0)
	_check_eq("lethal damage emits died once", death_ids, ["w0:bruiser:7"])
	_check_eq("lethal damage notifies enemy_death once", _audio_event_count(&"enemy_death"), enemy_death_before + 1)
	_check_eq("enemy reports dead after lethal damage", enemy.is_dead(), true)
	_check_almost("repeated damage after death keeps hp zero", enemy.take_damage(99.0), 0.0)
	_check_eq("repeated damage after death does not re-emit died", death_ids, ["w0:bruiser:7"])

	await _cleanup(enemy)

func _test_take_damage_spawns_floating_damage_number() -> void:
	var enemy = await _new_enemy()
	enemy.configure("bruiser", "w0:bruiser:9")
	var before := _label3d_nodes(root)
	enemy.take_damage(12.4)
	var spawned := _new_label3d_since(before)
	_check_eq("landed hit spawns one floating damage number", spawned.size(), 1)
	if spawned.size() == 1:
		_check_eq("damage number shows the rounded amount", spawned[0].text, "12")
		_check("damage number is not parented to the corpse-to-be", not enemy.is_ancestor_of(spawned[0]))
	before = _label3d_nodes(root)
	enemy.take_damage(999.0)
	_check_eq("killing blow still spawns a damage number", _new_label3d_since(before).size(), 1)
	before = _label3d_nodes(root)
	enemy.take_damage(50.0)
	_check_eq("damage on a dead enemy spawns no number", _new_label3d_since(before).size(), 0)
	for label in _label3d_nodes(root):
		label.queue_free()
	await _cleanup(enemy)

func _test_contact_damage_spawns_red_player_number() -> void:
	var enemy = await _new_enemy()
	if _object_has_property(enemy, "spawn_windup"):
		enemy.set("spawn_windup", 0.0)
	enemy.configure("chaff", "w0:chaff:9")
	var target_position := Vector3(0.5, 0.0, 0.0)
	enemy.tick_chase(target_position, 0.63)
	var before := _label3d_nodes(root)
	enemy.tick_chase(target_position, 0.03)
	var spawned := _new_label3d_since(before)
	_check_eq("released contact hit spawns one player damage number", spawned.size(), 1)
	if spawned.size() == 1:
		_check_eq("player damage number shows the contact damage", spawned[0].text, "20")
		_check("player damage number reads red", spawned[0].modulate.r > 0.7 and spawned[0].modulate.g < 0.5)
		_check(
			"player damage number floats above the player, not the enemy",
			Vector2(spawned[0].global_position.x, spawned[0].global_position.z).distance_to(Vector2(target_position.x, target_position.z)) < 1.0
		)
	for label in _label3d_nodes(root):
		label.queue_free()
	await _cleanup(enemy)

func _label3d_nodes(node: Node) -> Array[Label3D]:
	var found: Array[Label3D] = []
	if node is Label3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_label3d_nodes(child))
	return found

func _new_label3d_since(before: Array[Label3D]) -> Array[Label3D]:
	var fresh: Array[Label3D] = []
	for label in _label3d_nodes(root):
		if not before.has(label):
			fresh.append(label)
	return fresh

func _test_scene_instantiates_headless() -> void:
	var enemy = await _new_enemy()

	_check("scene root is CharacterBody3D", enemy is CharacterBody3D)
	_check_eq("scene root node name is stable", enemy.name, "GreyboxEnemy")
	_check("CollisionShape3D node exists", enemy.get_node_or_null("CollisionShape3D") is CollisionShape3D)
	_check("VisualPivot node exists", enemy.get_node_or_null("VisualPivot") is Node3D)
	_check("placeholder Capsule mesh exists", enemy.get_node_or_null("VisualPivot/Capsule") is MeshInstance3D)
	_check_eq("default scene config is chaff", enemy.archetype, "chaff")
	_check_almost("default scene hp is chaff hp", enemy.hp, 30.0)
	if _object_has_property(enemy, "spawn_windup"):
		_check_almost("default scene spawn windup is near Hades emergence timing", float(enemy.get("spawn_windup")), 0.8, 0.05)

	enemy.configure("bruiser", "spawn-42")
	_check_eq("configure stores spawn id", enemy.spawn_id, "spawn-42")
	_check_eq("configure stores archetype", enemy.archetype, "bruiser")
	_check_almost("configure applies bruiser hp", enemy.hp, 140.0)
	_check_almost("configure applies bruiser speed", enemy.move_speed, 1.65)

	await _cleanup(enemy)

func _test_scene_visual_models_follow_configured_archetype() -> void:
	# Bruiser/elite scales rebased from the HZ-091 table when the rigged GLBs
	# landed (feet-at-origin, 2.4m/3.2m native): silhouette heights unchanged.
	var cases := [
		{"archetype": "chaff", "node": "ChaffDroneModel", "scale": 0.9},
		{"archetype": "bruiser", "node": "BruiserUnitModel", "scale": 1.125},
		{"archetype": "elite", "node": "EliteEnforcerModel", "scale": 1.09},
	]
	for visual_case in cases:
		var fixture: Dictionary = await _new_configured_enemy(
			String(visual_case["archetype"]),
			"visual:%s" % String(visual_case["archetype"])
		)
		var enemy = fixture["enemy"]
		var pivot := enemy.get_node_or_null("VisualPivot") as Node3D
		var capsule := pivot.get_node_or_null("Capsule") as MeshInstance3D if pivot != null else null
		var model := pivot.get_node_or_null(String(visual_case["node"])) as Node3D if pivot != null else null
		var collision := enemy.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var collision_shape := collision.shape as CapsuleShape3D if collision != null else null

		_check("%s GLB visual node is instanced under VisualPivot" % String(visual_case["archetype"]), model != null)
		_check("%s keeps Capsule node hidden as the fallback" % String(visual_case["archetype"]), capsule != null and not capsule.visible)
		if model != null:
			var expected_scale := float(visual_case["scale"])
			_check_vec3_almost(
				"%s model local scale matches HZ-091 scale table" % String(visual_case["archetype"]),
				model.scale,
				Vector3.ONE * expected_scale,
				0.001
			)
			_check("%s GLB exposes a MeshInstance3D for combat effects" % String(visual_case["archetype"]), _first_mesh_under(model) != null)
		if String(visual_case["archetype"]) == "chaff" and pivot != null and model != null:
			var mesh := _first_mesh_under(pivot)
			_check("CombatEffects finds the GLB mesh before the hidden capsule", mesh != null and mesh != capsule)
			if mesh != null:
				_check_eq("GLB mesh starts without a hit-flash override", mesh.material_override, null)
				enemy.take_damage(1.0)
				_check("hit flash applies material_override to the GLB mesh", mesh.material_override != null)
		if collision_shape != null:
			_check_almost(
				"%s visual swap leaves collision radius untouched" % String(visual_case["archetype"]),
				collision_shape.radius,
				float(fixture["collision_radius"])
			)
			_check_almost(
				"%s visual swap leaves collision height untouched" % String(visual_case["archetype"]),
				collision_shape.height,
				float(fixture["collision_height"])
			)
		if collision != null:
			_check_eq(
				"%s visual swap leaves collision transform untouched" % String(visual_case["archetype"]),
				collision.transform,
				fixture["collision_transform"]
			)

		await _cleanup(enemy)

	var fallback_fixture: Dictionary = await _new_configured_enemy("chaff", "visual:unknown")
	var fallback_enemy = fallback_fixture["enemy"]
	fallback_enemy.archetype = "unknown"
	var fallback_pivot := fallback_enemy.get_node_or_null("VisualPivot") as Node3D
	if fallback_pivot != null and fallback_pivot.has_method("refresh_visual"):
		fallback_pivot.call("refresh_visual")
	await process_frame
	var fallback_capsule := fallback_pivot.get_node_or_null("Capsule") as MeshInstance3D if fallback_pivot != null else null
	_check("unknown visual archetype keeps the Capsule fallback visible", fallback_capsule != null and fallback_capsule.visible)
	_check("unknown visual archetype does not keep a chaff GLB model", fallback_pivot != null and fallback_pivot.get_node_or_null("ChaffDroneModel") == null)
	_check("unknown visual archetype does not keep a bruiser GLB model", fallback_pivot != null and fallback_pivot.get_node_or_null("BruiserUnitModel") == null)
	_check("unknown visual archetype does not keep an elite GLB model", fallback_pivot != null and fallback_pivot.get_node_or_null("EliteEnforcerModel") == null)
	await _cleanup(fallback_enemy)

func _test_visual_motion_identity_per_archetype() -> void:
	# Chaff hovers and spins; bruiser stomp-lumbers without spinning; elite
	# glides dead-level with banking only. Cosmetic layer — collision untouched.
	var chaff_fixture: Dictionary = await _new_configured_enemy("chaff", "motion:chaff")
	var chaff = chaff_fixture["enemy"]
	var chaff_model := chaff.get_node_or_null("VisualPivot/ChaffDroneModel") as Node3D
	var chaff_visual := chaff.get_node_or_null("VisualPivot") as Node3D
	_check("chaff model + motion API present", chaff_model != null and chaff_visual.has_method("update_motion"))
	if chaff_model != null and chaff_visual.has_method("update_motion"):
		var yaw_before: float = chaff_model.rotation.y
		var base_y: float = chaff_model.position.y
		var min_y := base_y
		var max_y := base_y
		for i in range(12):
			chaff_visual.call("update_motion", 0.05)
			min_y = minf(min_y, chaff_model.position.y)
			max_y = maxf(max_y, chaff_model.position.y)
		_check("chaff spins continuously while alive", absf(chaff_model.rotation.y - yaw_before) > 0.1)
		_check("chaff hover-bobs even when stationary", max_y - min_y > 0.02)
	await _cleanup_enemy(chaff)

	var bruiser_fixture: Dictionary = await _new_configured_enemy("bruiser", "motion:bruiser")
	var bruiser = bruiser_fixture["enemy"]
	var bruiser_model := bruiser.get_node_or_null("VisualPivot/BruiserUnitModel") as Node3D
	var bruiser_visual := bruiser.get_node_or_null("VisualPivot") as Node3D
	_check("bruiser model + motion API present", bruiser_model != null and bruiser_visual.has_method("update_motion"))
	if bruiser_model != null and bruiser_visual.has_method("update_motion"):
		var base_y: float = bruiser_visual.get("_model_base_position").y
		var still_max := base_y
		for i in range(8):
			bruiser_visual.call("update_motion", 0.05)
			still_max = maxf(still_max, bruiser_model.position.y)
		_check_almost("bruiser does not bob while standing still", still_max, base_y, 0.001)
		bruiser.velocity = Vector3(0.0, 0.0, bruiser.move_speed)
		var moving_max := base_y
		for i in range(12):
			bruiser_visual.call("update_motion", 0.05)
			moving_max = maxf(moving_max, bruiser_model.position.y)
		_check("bruiser stomp-lumbers while moving", moving_max > base_y + 0.03)
		_check_almost("bruiser never spins", bruiser_model.rotation.y, 0.0, 0.001)
	await _cleanup_enemy(bruiser)

	var elite_fixture: Dictionary = await _new_configured_enemy("elite", "motion:elite")
	var elite = elite_fixture["enemy"]
	var elite_model := elite.get_node_or_null("VisualPivot/EliteEnforcerModel") as Node3D
	var elite_visual := elite.get_node_or_null("VisualPivot") as Node3D
	_check("elite model + motion API present", elite_model != null and elite_visual.has_method("update_motion"))
	if elite_model != null and elite_visual.has_method("update_motion"):
		var base_y: float = elite_visual.get("_model_base_position").y
		elite.velocity = Vector3(elite.move_speed, 0.0, 0.0)
		var glide_min := base_y
		var glide_max := base_y
		for i in range(10):
			elite_visual.call("update_motion", 0.05)
			glide_min = minf(glide_min, elite_model.position.y)
			glide_max = maxf(glide_max, elite_model.position.y)
		_check_almost("elite glides dead-level (no bob at any speed)", glide_max - glide_min, 0.0, 0.001)
		_check("elite banks into lateral velocity", absf(elite_model.rotation.z) > 0.05)
		_check_almost("elite never spins", elite_model.rotation.y, 0.0, 0.001)
	await _cleanup_enemy(elite)

func _test_visual_hit_recoil_kicks_and_decays() -> void:
	var fixture: Dictionary = await _new_configured_enemy("chaff", "recoil:chaff")
	var enemy = fixture["enemy"]
	var model := enemy.get_node_or_null("VisualPivot/ChaffDroneModel") as Node3D
	var visual := enemy.get_node_or_null("VisualPivot") as Node3D
	_check("recoil fixture has model + motion API", model != null and visual.has_method("update_motion"))
	if model == null or not visual.has_method("update_motion"):
		await _cleanup_enemy(enemy)
		return

	enemy.take_damage(1.0)
	visual.call("update_motion", 0.01)
	_check("hit recoil kicks the model backward", model.position.z < -0.05)

	for i in range(12):
		visual.call("update_motion", 0.05)
	_check_almost("hit recoil decays back to rest", model.position.z, 0.0, 0.005)
	await _cleanup_enemy(enemy)

func _cleanup_enemy(enemy: Node) -> void:
	enemy.queue_free()
	await process_frame

func _test_spawn_windup_blocks_movement_and_contact_until_elapsed() -> void:
	var enemy = await _new_enemy()
	var has_spawn_windup := _object_has_property(enemy, "spawn_windup")
	_check("scene exposes exported spawn_windup", has_spawn_windup)
	if has_spawn_windup:
		enemy.set("spawn_windup", 0.8)
	enemy.configure("chaff", "spawn-windup")
	var events: Array[Dictionary] = []
	enemy.damage_event.connect(func(event: Dictionary) -> void:
		events.append(event)
	)

	var first: Dictionary = enemy.tick_chase(Vector3(8.0, 0.0, 0.0), 0.40)
	_check_vec3_almost("fresh enemy does not move during spawn windup", Vector3(first["velocity"]), Vector3.ZERO)
	_check_eq("fresh enemy emits no damage while spawning", Dictionary(first["damage_event"]).is_empty(), true)

	var contact_before_ready: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.39)
	_check_vec3_almost("contact does not move during remaining spawn windup", Vector3(contact_before_ready["velocity"]), Vector3.ZERO)
	_check_eq("contact does not deal damage during remaining spawn windup", events.size(), 0)

	enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.01)
	var after_ready: Dictionary = enemy.tick_chase(Vector3(8.0, 0.0, 0.0), 0.10)
	_check("enemy starts moving after spawn windup elapses", Vector3(after_ready["velocity"]).length() > 0.0)

	enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.63)
	_check_eq("enemy still respects attack windup after spawn windup", events.size(), 0)
	var contact_after_ready: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.03)
	_check_eq("enemy can deal contact damage after spawn and attack windups", int(Dictionary(contact_after_ready["damage_event"]).get("damage", 0)), 20)
	_check_eq("post-windup damage event is emitted once", events.size(), 1)

	await _cleanup(enemy)

func _test_scene_stagger_ticks_down_during_spawn_windup() -> void:
	var enemy = await _new_enemy()
	enemy.spawn_windup = 1.0
	enemy.configure("chaff", "spawn-stagger")
	enemy.stagger(0.25)

	var during: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.30)
	_check_eq("spawn-windup stagger emits no damage", Dictionary(during["damage_event"]).is_empty(), true)
	_check("stagger timer ticks down while enemy is still spawning", not enemy.is_staggered())
	_check("enemy remains in spawn windup after stagger expires", enemy.is_spawning())

	enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.70)
	var contact_after_spawn: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.65)
	_check_eq(
		"stagger does not bank through spawn windup into the first live contact",
		int(Dictionary(contact_after_spawn["damage_event"]).get("damage", 0)),
		20
	)

	await _cleanup(enemy)

func _test_scene_chase_emits_damage_event_data_without_player_wiring() -> void:
	var enemy = await _new_enemy()
	if _object_has_property(enemy, "spawn_windup"):
		enemy.set("spawn_windup", 0.0)
	enemy.configure("chaff", "w0:chaff:3")
	var events: Array[Dictionary] = []
	enemy.damage_event.connect(func(event: Dictionary) -> void:
		events.append(event)
	)

	var first: Dictionary = enemy.tick_chase(Vector3(4.0, 0.0, 0.0), 0.10)
	_check_vec3_almost("scene tick_chase writes seek velocity", enemy.velocity, Vector3(2.1, 0.0, 0.0))
	_check_eq("far chase does not emit damage", Dictionary(first["damage_event"]).is_empty(), true)

	enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.63)
	_check_eq("contact before windup emits no damage event", events.size(), 0)
	var contact: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.03)
	_check_eq("scene emits one telegraphed damage event", events.size(), 1)
	if events.size() == 1:
		_check_eq("damage event carries spawn id", String(events[0]["spawn_id"]), "w0:chaff:3")
		_check_eq("damage event carries archetype", String(events[0]["archetype"]), "chaff")
		_check_eq("damage event carries amount", int(events[0]["damage"]), 20)
		_check_eq("returned event matches emitted event", Dictionary(contact["damage_event"]), events[0])

	await _cleanup(enemy)

func _test_rigged_archetypes_carry_animation_controller() -> void:
	# Bruiser/elite load rigged GLBs; EnemyVisual attaches the two-tier
	# EnemyAnimationController, which starts them in idle with the clip
	# contract (idle/walk/attack/hit/death) resolvable.
	for archetype in ["bruiser", "elite"]:
		var fixture: Dictionary = await _new_configured_enemy(archetype, "anim:%s" % archetype)
		var enemy = fixture["enemy"]
		var controller = enemy.get_node_or_null("VisualPivot/EnemyAnimationController")
		_check("%s gets an EnemyAnimationController" % archetype, controller != null)
		if controller != null:
			var player := controller.get("animation_player") as AnimationPlayer
			_check("%s controller found the GLB AnimationPlayer" % archetype, player != null)
			if player != null:
				for clip_name in ["idle", "walk", "attack", "hit", "death"]:
					_check(
						"%s clip contract resolves '%s'" % [archetype, clip_name],
						String(controller.call("_library_key", StringName(clip_name))) != ""
					)
				# Night pass 2026-07-07: rigged GLBs carry an authored spawn
				# materialize — it is the entry clip when present, else idle.
				_check(
					"%s starts in spawn materialize (or idle)" % archetype,
					player.assigned_animation.ends_with("spawn") or player.assigned_animation.ends_with("idle")
				)
		await _cleanup(enemy)

	# Chaff stays unrigged and procedural: no controller.
	var chaff_fixture: Dictionary = await _new_configured_enemy("chaff", "anim:chaff")
	var chaff = chaff_fixture["enemy"]
	_check(
		"chaff stays procedural (no animation controller)",
		chaff.get_node_or_null("VisualPivot/EnemyAnimationController") == null
	)
	await _cleanup(chaff)

func _test_animation_controller_tracks_windup_death_and_locomotion() -> void:
	# Clip choice mirrors gameplay state (read-only): brain windup -> attack,
	# death -> death (held), movement -> walk for bruiser but the poised idle
	# glide stance for elite (its locomotion identity stays procedural).
	var fixture: Dictionary = await _new_configured_enemy("bruiser", "anim:windup")
	var enemy = fixture["enemy"]
	var controller = enemy.get_node_or_null("VisualPivot/EnemyAnimationController")
	_check("windup fixture has controller", controller != null)
	if controller == null:
		await _cleanup(enemy)
		return
	var player := controller.get("animation_player") as AnimationPlayer

	enemy.velocity = Vector3(0.0, 0.0, enemy.move_speed)
	controller.call("update_animation", 0.05)
	_check("bruiser walks while moving", player.assigned_animation.ends_with("walk"))
	_check("bruiser walk speed-scales to velocity", player.speed_scale > 0.5)
	enemy.velocity = Vector3.ZERO

	# Real windup: a contact-range brain step arms the attack.
	enemy.brain.step(Vector3.ZERO, Vector3.ZERO, 0.016)
	_check_eq("brain is winding up", enemy.brain.attack_state(), "windup")
	controller.call("update_animation", 0.05)
	_check("windup drives the attack clip", player.assigned_animation.ends_with("attack"))

	enemy.take_damage(999999.0)
	controller.call("update_animation", 0.05)
	_check("death drives the death clip", player.assigned_animation.ends_with("death"))
	await _cleanup(enemy)

	var elite_fixture: Dictionary = await _new_configured_enemy("elite", "anim:glide")
	var elite = elite_fixture["enemy"]
	var elite_controller = elite.get_node_or_null("VisualPivot/EnemyAnimationController")
	_check("elite fixture has controller", elite_controller != null)
	if elite_controller != null:
		var elite_player := elite_controller.get("animation_player") as AnimationPlayer
		elite.velocity = Vector3(0.0, 0.0, elite.move_speed)
		elite_controller.call("update_animation", 0.05)
		_check(
			"elite keeps the poised idle stance while gliding",
			elite_player.assigned_animation.ends_with("idle")
		)
	await _cleanup(elite)

func _test_chaff_windup_wobble_and_death_tumble() -> void:
	# Chaff telegraph: an aggression shiver (roll wobble) while the brain
	# winds up. Chaff death: the hover fails — it tumbles and sinks.
	var fixture: Dictionary = await _new_configured_enemy("chaff", "anim:wobble")
	var enemy = fixture["enemy"]
	var visual := enemy.get_node_or_null("VisualPivot") as Node3D
	var model := enemy.get_node_or_null("VisualPivot/ChaffDroneModel") as Node3D
	_check("wobble fixture has model + motion API", model != null and visual.has_method("update_motion"))
	if model == null or not visual.has_method("update_motion"):
		await _cleanup(enemy)
		return

	var calm_roll := 0.0
	for i in range(12):
		visual.call("update_motion", 0.05)
		calm_roll = maxf(calm_roll, absf(model.rotation.z))
	_check_almost("chaff carries no roll wobble while calm", calm_roll, 0.0, 0.01)

	enemy.brain.step(Vector3.ZERO, Vector3.ZERO, 0.016)
	_check_eq("chaff brain is winding up", enemy.brain.attack_state(), "windup")
	var windup_roll := 0.0
	for i in range(24):
		visual.call("update_motion", 0.05)
		windup_roll = maxf(windup_roll, absf(model.rotation.z))
	_check("chaff shivers with aggression during windup", windup_roll > 0.03)

	var base_y: float = visual.get("_model_base_position").y
	enemy.take_damage(999999.0)
	var pitch_before: float = model.rotation.x
	for i in range(10):
		visual.call("update_motion", 0.05)
	_check("dead chaff tumbles", model.rotation.x - pitch_before > 0.5)
	_check("dead chaff sinks out of its hover", model.position.y < base_y - 0.2)
	await _cleanup(enemy)

func _test_physics_process_is_inert_after_exit() -> void:
	var enemy = await _new_enemy()
	var target := Node3D.new()
	target.name = "EnemyExitTarget"
	target.position = Vector3(5.0, 0.0, 0.0)
	root.add_child(target)
	enemy.set_chase_target(target)
	enemy.velocity = Vector3(3.0, 0.0, 0.0)

	root.remove_child(enemy)
	await process_frame
	enemy._physics_process(0.2)

	_check_eq("enemy is outside tree after teardown", enemy.is_inside_tree(), false)
	_check_eq("enemy disables physics processing on exit", enemy.is_physics_processing(), false)
	_check_vec3_almost("post-exit physics guard keeps velocity inert", enemy.velocity, Vector3.ZERO)

	enemy.free()
	target.queue_free()
	await process_frame

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

func _contact_damage_events_in_seconds(stats: Dictionary, seconds: float) -> int:
	var brain = EnemyBrainScript.new()
	brain.configure(stats)
	var elapsed := 0.0
	var events := 0
	var dt := 0.05
	while elapsed < seconds:
		var step_delta := minf(dt, seconds - elapsed)
		var result: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), step_delta)
		if not Dictionary(result["damage_event"]).is_empty():
			events += 1
		elapsed += step_delta
	return events

func _multi_contact_survival(stats: Dictionary, desync_offsets: Array[float], seconds: float) -> Dictionary:
	var vitals := PlayerVitalsScript.new() as PlayerVitals
	vitals.reset()
	var brains: Array[EnemyBrain] = []
	for offset in desync_offsets:
		var brain := EnemyBrainScript.new()
		brain.configure(stats)
		brain.stagger(float(offset))
		brains.append(brain)

	var elapsed := 0.0
	var damage_attempts := 0
	var applied_hits := 0
	var guard_empty_seconds := -1.0
	var death_seconds := -1.0
	var dt := 0.05
	while elapsed < seconds and not vitals.is_dead():
		var step_delta := minf(dt, seconds - elapsed)
		vitals.tick_guard_recharge(step_delta)
		for brain in brains:
			var before_total := vitals.guard + vitals.hp
			var result: Dictionary = brain.step(Vector3.ZERO, Vector3(0.5, 0.0, 0.0), step_delta)
			var event: Dictionary = result["damage_event"]
			if event.is_empty():
				continue
			damage_attempts += 1
			vitals.apply_damage(int(event.get("damage", 0)))
			var after_total := vitals.guard + vitals.hp
			if after_total < before_total:
				applied_hits += 1
				if vitals.guard <= 0 and guard_empty_seconds < 0.0:
					guard_empty_seconds = elapsed + step_delta
				if vitals.is_dead() and death_seconds < 0.0:
					death_seconds = elapsed + step_delta
		elapsed += step_delta

	if guard_empty_seconds < 0.0:
		guard_empty_seconds = INF
	if death_seconds < 0.0:
		death_seconds = INF
	vitals.free()
	return {
		"damage_attempts": damage_attempts,
		"applied_hits": applied_hits,
		"guard_empty_seconds": guard_empty_seconds,
		"death_seconds": death_seconds,
	}

func _object_has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _first_mesh_under(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _first_mesh_under(child)
		if found != null:
			return found
	return null

func _audio_event_count(event: StringName) -> int:
	var director := root.get_node_or_null("AudioDirector")
	if director == null or not director.has_method(&"describe"):
		return 0
	var desc: Dictionary = director.describe()
	var counts: Dictionary = desc.get("sfx_event_counts", {})
	return int(counts.get(String(event), 0))
