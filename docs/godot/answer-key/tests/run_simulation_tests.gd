extends SceneTree

const SimulationScript := preload("res://scripts/simulation.gd")

var _failures: int = 0

func _init() -> void:
	var simulation: Simulation = SimulationScript.new()
	_test_initial_state_schema(simulation)
	_test_safe_tick(simulation)
	_test_negative_dt_does_not_rewind(simulation)
	_test_phase_guard(simulation)
	_test_completion_event(simulation)
	_test_player_moves_from_input(simulation)
	_test_sprint_upgrades_increase_move_speed(simulation)
	_test_diagonal_input_is_normalized(simulation)
	_test_player_clamps_to_world_bounds(simulation)
	_test_facing_updates_from_horizontal_velocity(simulation)
	_test_zero_input_stays_still(simulation)
	_test_simulation_state_has_no_presentation_fields(simulation)

	if _failures == 0:
		print("Simulation tests passed")
	else:
		printerr("Simulation tests failed: %d" % _failures)
	quit(_failures)

func _test_initial_state_schema(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()

	_assert_schema_keys(state, simulation.get_state_schema_keys(), "top-level state")
	_assert_schema_keys(state["player"], simulation.get_player_schema_keys(), "player state")
	_assert_schema_keys(state["upgrades"], simulation.get_upgrade_ids(), "upgrade ranks")

	_assert_equal(state["phase"], "playing", "initial phase is playing")
	_assert_equal(state["world"]["width"], 2600, "world width matches simulation.ts")
	_assert_equal(state["world"]["height"], 1700, "world height matches simulation.ts")
	_assert_approx(state["run_duration"], 240.0, "run duration matches simulation.ts")
	_assert_approx(state["player"]["x"], 1300.0, "player starts centered on x")
	_assert_approx(state["player"]["y"], 850.0, "player starts centered on y")
	_assert_approx(state["player"]["vx"], 0.0, "player starts with no x velocity")
	_assert_approx(state["player"]["vy"], 0.0, "player starts with no y velocity")
	_assert_approx(state["player"]["facing_x"], 1.0, "player starts facing right")
	_assert_equal(state["player"]["hp"], 7, "player starts with Phaser seed HP")
	_assert_equal(state["player"]["max_hp"], 7, "player starts with Phaser seed max HP")
	_assert_equal(state["player"]["level"], 1, "player starts at level 1")
	_assert_equal(state["player"]["xp"], 0, "player starts with no xp")
	_assert_equal(state["player"]["next_xp"], 92, "level 1 XP target matches nextXpForLevel")
	_assert_equal(state["upgrades"]["spark"], 1, "spark starts at rank 1")
	_assert_equal(state["rerolls"], 1, "one reroll starts charged")
	_assert_approx(state["bounty_cooldown"], 6.2, "first bounty delay matches simulation.ts")
	_assert_equal(state["combo"]["next_burst_at"], 144, "flow burst step matches simulation.ts")
	_assert_equal(state["enemies"].size(), 0, "no enemies at start")
	_assert_equal(state["pickups"].size(), 0, "no pickups at start")

func _test_safe_tick(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	var events: Array[Dictionary] = simulation.update_state(state, {}, 0.25)

	_assert_approx(state["elapsed"], 0.05, "update_state clamps dt to 0.05")
	_assert_approx(state["message_timer"], 4.45, "message timer advances by safe dt")
	_assert_equal(state["phase"], "playing", "one tiny tick keeps the run playing")
	_assert_equal(events.size(), 0, "one tiny opening tick emits no events")

func _test_negative_dt_does_not_rewind(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	var events: Array[Dictionary] = simulation.update_state(state, {}, -1.0)

	_assert_approx(state["elapsed"], 0.0, "negative dt is clamped to zero")
	_assert_approx(state["message_timer"], 4.5, "negative dt does not increase timers")
	_assert_equal(events.size(), 0, "negative dt emits no events")

func _test_phase_guard(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	state["phase"] = "levelup"
	var events: Array[Dictionary] = simulation.update_state(state, {}, 1.0)

	_assert_approx(state["elapsed"], 0.0, "non-playing phase does not advance elapsed")
	_assert_equal(events.size(), 0, "non-playing phase emits no events")

func _test_completion_event(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	state["elapsed"] = 239.99
	var events: Array[Dictionary] = simulation.update_state(state, {}, 0.05)

	_assert_equal(state["phase"], "complete", "run completes at run_duration")
	_assert_equal(events.size(), 1, "completion emits one event")
	_assert_equal(events[0]["type"], "complete", "completion event type")
	_assert_equal(state["message"], "Four minutes survived. The playground is yours.", "completion message matches seed")
	_assert_approx(state["message_timer"], 99.0, "completion message is held")

func _test_player_moves_from_input(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	simulation.update_state(state, {"x": 1.0, "y": 0.0}, 0.05)
	var expected_blend: float = 1.0 - exp(-23.0 * 0.05)
	var expected_vx: float = 266.0 * expected_blend
	_assert_approx(state["player"]["vx"], expected_vx, "right input eases toward Phaser seed move speed")
	_assert_approx(state["player"]["x"], 1300.0 + expected_vx * 0.05, "right input moves the player")
	_assert_approx(state["player"]["y"], 850.0, "right input does not move y")

func _test_sprint_upgrades_increase_move_speed(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	state["upgrades"]["sprint"] = 2
	state["evolved"]["sprint"] = true
	simulation.update_state(state, {"x": 1.0, "y": 0.0}, 0.05)
	var expected_blend: float = 1.0 - exp(-23.0 * 0.05)
	var expected_speed: float = 266.0 + 2.0 * 24.0 + 34.0
	_assert_approx(state["player"]["vx"], expected_speed * expected_blend, "sprint rank and evolution increase move speed")

func _test_diagonal_input_is_normalized(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	simulation.update_state(state, {"x": 1.0, "y": 1.0}, 0.05)
	var velocity := Vector2(float(state["player"]["vx"]), float(state["player"]["vy"]))
	var expected_blend: float = 1.0 - exp(-23.0 * 0.05)
	_assert_approx(velocity.length(), 266.0 * expected_blend, "diagonal input keeps normalized speed")
	_assert_approx(state["player"]["vx"], state["player"]["vy"], "diagonal input splits velocity evenly")

func _test_player_clamps_to_world_bounds(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	state["player"]["x"] = 2529.0
	simulation.update_state(state, {"x": 1.0, "y": 0.0}, 0.05)
	_assert_approx(state["player"]["x"], 2530.0, "player clamps to right world margin")
	_assert_approx(state["player"]["vx"], 0.0, "x velocity clears when clamped")

func _test_facing_updates_from_horizontal_velocity(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	simulation.update_state(state, {"x": -1.0, "y": 0.0}, 0.05)
	_assert_approx(state["player"]["facing_x"], -1.0, "left input updates facing")

func _test_zero_input_stays_still(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	simulation.update_state(state, {"x": 0.0, "y": 0.0}, 0.05)
	_assert_approx(state["player"]["x"], 1300.0, "zero input keeps x")
	_assert_approx(state["player"]["y"], 850.0, "zero input keeps y")
	_assert_approx(state["player"]["vx"], 0.0, "zero input keeps vx")
	_assert_approx(state["player"]["vy"], 0.0, "zero input keeps vy")


func _test_simulation_state_has_no_presentation_fields(simulation: Simulation) -> void:
	var state: Dictionary = simulation.create_game_state()
	_assert_flat_state_snapshot(state, "initial")
	simulation.update_state(state, {"x": 1.0, "y": 0.5}, 0.05)
	_assert_flat_state_snapshot(state, "post-tick")
	_assert_equal(state["world"]["height"], 1700, "world height remains a valid flat 2D bound")

func _assert_flat_state_snapshot(state: Dictionary, label: String) -> void:
	_assert_no_presentation_fields(state, "%s top-level state" % label, false)
	_assert_no_presentation_fields(state["player"], "%s player state" % label, true)
	for enemy: Dictionary in state["enemies"]:
		_assert_no_presentation_fields(enemy, "%s enemy state" % label, true)
	for pickup: Dictionary in state["pickups"]:
		_assert_no_presentation_fields(pickup, "%s pickup state" % label, true)

func _assert_no_presentation_fields(source: Dictionary, label: String, include_visual_height: bool) -> void:
	var forbidden_keys: Array[String] = ["z", "position_3d", "global_position", "transform"]
	if include_visual_height:
		forbidden_keys.append("height")
		forbidden_keys.append("visual_height")
	for key: String in forbidden_keys:
		if source.has(key):
			_failures += 1
			printerr("FAIL %s: Simulation state must not contain presentation field %s" % [label, key])

func _assert_schema_keys(source: Dictionary, expected_keys: Array[String], label: String) -> void:
	_assert_equal(source.size(), expected_keys.size(), "%s key count" % label)
	for key: String in expected_keys:
		if not source.has(key):
			_failures += 1
			printerr("FAIL %s: missing key %s" % [label, key])

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures += 1
		printerr("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_approx(actual: Variant, expected: float, label: String, epsilon: float = 0.0001) -> void:
	if abs(float(actual) - expected) > epsilon:
		_failures += 1
		printerr("FAIL %s: expected %.4f, got %.4f" % [label, expected, float(actual)])
