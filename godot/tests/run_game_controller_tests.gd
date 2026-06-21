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
	print("")
	if _failed == 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL — %d passed, %d failed" % [_passed, _failed])
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
	_check_eq("force complete clamps elapsed to the run duration", controller.sim.elapsed, controller.sim.run_duration)
	_check("win overlay is visible", controller.end_screen.get_node("Root").visible)
	_check_eq("win title renders", controller.end_screen.get_node("Root/Center/Panel/Margin/VBox/TitleLabel").text, "RUN COMPLETE")
	await _cleanup(controller)
