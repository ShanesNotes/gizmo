extends SceneTree

# Headless tests for HZ-017 greybox enemy entity + chase AI.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_enemy_tests.gd

const EnemyArchetypesScript := preload("res://scripts/enemies/enemy_archetypes.gd")
const EnemyBrainScript := preload("res://scripts/enemies/enemy_brain.gd")
const GreyboxEnemyScene := preload("res://scenes/enemies/greybox_enemy.tscn")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running enemy tests...")
	await _test_archetype_stats_match_balance_bands()
	await _test_unknown_archetype_falls_back_to_chaff()
	await _test_steering_direction_and_contact_stop()
	await _test_windup_timing_is_deterministic()
	await _test_windup_survives_contact_jitter_but_resets_on_escape()
	await _test_stagger_suppresses_movement_and_attack_until_window()
	await _test_take_damage_emits_died_once()
	await _test_scene_instantiates_headless()
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

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_archetype_stats_match_balance_bands() -> void:
	var chaff := EnemyArchetypesScript.stats_for("chaff")
	var bruiser := EnemyArchetypesScript.stats_for("bruiser")

	_check("chaff archetype exists", EnemyArchetypesScript.has_archetype("chaff"))
	_check("bruiser archetype exists", EnemyArchetypesScript.has_archetype("bruiser"))
	_check_eq("chaff hp salvages nibbler/trash one-hit value", float(chaff["max_hp"]), 1.0)
	_check_eq("chaff damage is chip contact pressure", int(chaff["damage"]), 1)
	_check_almost("chaff speed salvages nibbler chase band", float(chaff["move_speed"]), 2.1)
	_check_almost("chaff budget cost matches director chaff cost", float(chaff["budget_cost"]), 1.1)
	_check_eq("bruiser hp salvages brute 1-3s TTK value", float(bruiser["max_hp"]), 4.0)
	_check_eq("bruiser damage stays chip, not burst", int(bruiser["damage"]), 1)
	_check_almost("bruiser speed salvages slower priority-target band", float(bruiser["move_speed"]), 1.65)
	_check_almost("bruiser budget cost matches director bruiser cost", float(bruiser["budget_cost"]), 3.4)
	_check("bruiser has more hp than chaff", float(bruiser["max_hp"]) > float(chaff["max_hp"]))
	_check("chaff is faster than bruiser", float(chaff["move_speed"]) > float(bruiser["move_speed"]))

func _test_unknown_archetype_falls_back_to_chaff() -> void:
	var fallback := EnemyArchetypesScript.stats_for("unknown")

	_check_eq("unknown archetype stats fall back to chaff", String(fallback["archetype"]), "chaff")
	_check_eq("unknown archetype fallback keeps chaff hp", float(fallback["max_hp"]), 1.0)

	var enemy = await _new_enemy()
	enemy.configure("unknown", "spawn-unknown")
	_check_eq("scene configure unknown stores chaff fallback archetype", enemy.archetype, "chaff")
	_check_eq("scene configure unknown keeps spawn id", enemy.spawn_id, "spawn-unknown")
	_check_almost("scene configure unknown applies chaff hp", enemy.hp, 1.0)

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

	_check_almost("configured bruiser starts at bruiser hp", enemy.hp, 4.0)
	_check_almost("partial damage returns remaining hp", enemy.take_damage(1.5), 2.5)
	_check_eq("partial damage does not emit died", death_ids.size(), 0)
	_check_almost("lethal damage floors hp at zero", enemy.take_damage(99.0), 0.0)
	_check_eq("lethal damage emits died once", death_ids, ["w0:bruiser:7"])
	_check_eq("enemy reports dead after lethal damage", enemy.is_dead(), true)
	_check_almost("repeated damage after death keeps hp zero", enemy.take_damage(99.0), 0.0)
	_check_eq("repeated damage after death does not re-emit died", death_ids, ["w0:bruiser:7"])

	await _cleanup(enemy)

func _test_scene_instantiates_headless() -> void:
	var enemy = await _new_enemy()

	_check("scene root is CharacterBody3D", enemy is CharacterBody3D)
	_check_eq("scene root node name is stable", enemy.name, "GreyboxEnemy")
	_check("CollisionShape3D node exists", enemy.get_node_or_null("CollisionShape3D") is CollisionShape3D)
	_check("VisualPivot node exists", enemy.get_node_or_null("VisualPivot") is Node3D)
	_check("placeholder Capsule mesh exists", enemy.get_node_or_null("VisualPivot/Capsule") is MeshInstance3D)
	_check_eq("default scene config is chaff", enemy.archetype, "chaff")
	_check_almost("default scene hp is chaff hp", enemy.hp, 1.0)
	if _object_has_property(enemy, "spawn_windup"):
		_check_almost("default scene spawn windup is near Hades emergence timing", float(enemy.get("spawn_windup")), 0.8, 0.05)

	enemy.configure("bruiser", "spawn-42")
	_check_eq("configure stores spawn id", enemy.spawn_id, "spawn-42")
	_check_eq("configure stores archetype", enemy.archetype, "bruiser")
	_check_almost("configure applies bruiser hp", enemy.hp, 4.0)
	_check_almost("configure applies bruiser speed", enemy.move_speed, 1.65)

	await _cleanup(enemy)

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

	enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.34)
	_check_eq("enemy still respects attack windup after spawn windup", events.size(), 0)
	var contact_after_ready: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.01)
	_check_eq("enemy can deal contact damage after spawn and attack windups", int(Dictionary(contact_after_ready["damage_event"]).get("damage", 0)), 1)
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
	var contact_after_spawn: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.35)
	_check_eq(
		"stagger does not bank through spawn windup into the first live contact",
		int(Dictionary(contact_after_spawn["damage_event"]).get("damage", 0)),
		1
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

	enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.34)
	_check_eq("contact before windup emits no damage event", events.size(), 0)
	var contact: Dictionary = enemy.tick_chase(Vector3(0.5, 0.0, 0.0), 0.01)
	_check_eq("scene emits one telegraphed damage event", events.size(), 1)
	if events.size() == 1:
		_check_eq("damage event carries spawn id", String(events[0]["spawn_id"]), "w0:chaff:3")
		_check_eq("damage event carries archetype", String(events[0]["archetype"]), "chaff")
		_check_eq("damage event carries amount", int(events[0]["damage"]), 1)
		_check_eq("returned event matches emitted event", Dictionary(contact["damage_event"]), events[0])

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

func _object_has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
