extends SceneTree

# Headless tests for the GameController integration affordances added after 0012:
# - the playable scene gets HUD/end-screen UI even when main.tscn is in art flux
# - debug playtest methods can force win/loss without waiting for balance/lethality
#   godot --headless --path godot --script res://tests/run_game_controller_tests.gd

var _passed := 0
var _failed := 0

const GameController := preload("res://scripts/game_controller.gd")

func _initialize() -> void:
	print("Running game-controller tests…")
	await _test_auto_instances_default_ui()
	await _test_force_gameover_for_playtest()
	await _test_force_complete_for_playtest()
	await _test_obstacle_registration_duck_types_solid_pieces()
	await _test_beacon_registration_reads_the_dais_marker()
	await _test_beacon_inert_without_a_dais_marker()
	print("")
	# A run with zero checks is a FAILURE, not a pass: it means the controller script
	# failed to load/compile (e.g. GameController.new() returned null), so the asserts
	# never ran. Require real coverage so a compile break can't exit 0 with "PASS — 0".
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL — %d passed, %d failed%s" % [_passed, _failed, " (0 checks ⇒ controller failed to load/compile)" if _passed == 0 else ""])
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

func _new_controller():
	var controller = GameController.new()
	root.add_child(controller)
	return controller

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_auto_instances_default_ui() -> void:
	var controller = _new_controller()
	await process_frame
	_check("HUD auto-instanced when no Inspector slot is assigned", controller.hud != null and controller.hud is Hud)
	_check("End screen auto-instanced when no Inspector slot is assigned", controller.end_screen != null and controller.end_screen is EndScreen)
	await _cleanup(controller)

func _test_force_gameover_for_playtest() -> void:
	var controller = _new_controller()
	await process_frame
	controller.sim.elapsed = 17.6
	controller.force_gameover_for_playtest()
	await process_frame
	_check_eq("force gameover sets phase", controller.sim.phase, Simulation.PHASE_GAMEOVER)
	_check_eq("force gameover drops HP to zero", controller.sim.hp, 0)
	_check("loss overlay is visible", controller.end_screen.get_node("Root").visible)
	_check_eq("loss title renders", controller.end_screen.get_node("Root/Center/Panel/Margin/VBox/TitleLabel").text, "GIZMO OFFLINE")
	await _cleanup(controller)

func _test_force_complete_for_playtest() -> void:
	var controller = _new_controller()
	await process_frame
	controller.force_complete_for_playtest()
	await process_frame
	_check_eq("force complete sets phase", controller.sim.phase, Simulation.PHASE_COMPLETE)
	_check_eq("force complete rekindles the Beacon", controller.sim.beacon_state, Simulation.BEACON_REKINDLED)
	_check("win overlay is visible", controller.end_screen.get_node("Root").visible)
	_check_eq("win title renders", controller.end_screen.get_node("Root/Center/Panel/Margin/VBox/TitleLabel").text, "BEACON REKINDLED")
	await _cleanup(controller)

# A minimal stand-in for the art-stream WorldKitPiece: just the duck-typed shape the
# controller matches on. Lets the COMMITTED gate cover obstacle registration without
# depending on the (untracked) art assets. (review LOW)
class FakeArenaPiece extends Node3D:
	var footprint_meters: Vector2 = Vector2.ONE
	var placement_role: StringName = &""
	var shape_count: int = 1
	func collision_shape_count() -> int:
		return shape_count

func _fake_piece(pos: Vector3, footprint: Vector2, role: StringName, shapes: int) -> Node3D:
	var p := FakeArenaPiece.new()
	p.position = pos
	p.footprint_meters = footprint
	p.placement_role = role
	p.shape_count = shapes
	return p

func _test_obstacle_registration_duck_types_solid_pieces() -> void:
	var controller = _new_controller()
	await process_frame
	var arena := Node3D.new()
	root.add_child(arena)
	arena.add_child(_fake_piece(Vector3(5, 0, 0), Vector2(2.6, 2.6), &"major_landmark", 1))  # solid -> ADD (r 1.3)
	arena.add_child(_fake_piece(Vector3(0, 0, 0), Vector2(2, 2), &"walkable_tile", 1))         # floor role -> skip
	arena.add_child(_fake_piece(Vector3(8, 0, 0), Vector2(18, 18), &"foundation", 1))          # foundation role -> skip
	arena.add_child(_fake_piece(Vector3(-5, 0, 0), Vector2(2, 2), &"edge_detail", 0))          # no collider -> skip
	arena.add_child(Node3D.new())                                                              # not a piece -> skip
	controller.sim.obstacles.clear()
	controller._register_obstacles_under(arena)
	_check_eq("duck-typed registration adds only the one solid piece", controller.sim.obstacles.size(), 1)
	if controller.sim.obstacles.size() == 1:
		_check("footprint 2.6 -> radius 1.3", absf(controller.sim.obstacles[0].radius - 1.3) < 0.001)
		_check("obstacle mirrors the piece position", controller.sim.obstacles[0].position.distance_to(Vector3(5, 0, 0)) < 0.001)
	arena.queue_free()
	await _cleanup(controller)

# The controller authors the Beacon into the sim by reading the NorthBeaconDaisZone
# marker's position (ADR 0005/0006), with the radius coming from a controller-side
# export — the marker is a bare Marker3D with no radius metadata to duck-type. (0019)
func _test_beacon_registration_reads_the_dais_marker() -> void:
	var controller = _new_controller()
	await process_frame
	var arena := Node3D.new()
	root.add_child(arena)
	var dais := Marker3D.new()
	dais.name = "NorthBeaconDaisZone"
	dais.position = Vector3(0, 0, -13)
	arena.add_child(dais)
	controller.beacon_radius = 3.0
	controller._register_beacon_under(arena)
	_check_eq("beacon radius comes from the controller export", controller.sim.beacon_radius, 3.0)
	_check("beacon position mirrors the dais marker", controller.sim.beacon_position.distance_to(Vector3(0, 0, -13)) < 0.001)
	arena.queue_free()
	await _cleanup(controller)

func _test_beacon_inert_without_a_dais_marker() -> void:
	var controller = _new_controller()
	await process_frame
	var arena := Node3D.new()      # no NorthBeaconDaisZone present
	root.add_child(arena)
	controller.sim.beacon_radius = 0.0
	controller._register_beacon_under(arena)
	_check_eq("no dais marker ⇒ beacon stays inert", controller.sim.beacon_radius, 0.0)
	arena.queue_free()
	await _cleanup(controller)
