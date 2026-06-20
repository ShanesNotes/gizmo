extends SceneTree

# Tiny dependency-free test runner for the ported game logic.
# Run with:
#   godot --headless --path godot --script res://tests/run_simulation_tests.gd
# Exits 0 if all pass, 1 if any fail (so CI / the terminal can tell).

var _passed := 0
var _failed := 0

# Load by path so this runner works headless without an editor import step
# (the global class_name cache isn't refreshed by a raw --script run).
const Sim := preload("res://scripts/simulation.gd")

func _initialize() -> void:
	print("Running simulation tests…")
	_test_next_xp_curve()
	_test_xp_below_threshold()
	_test_level_up_carries_remainder()
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
		print("  ok  - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - ", desc)

func _test_next_xp_curve() -> void:
	_check("level 1 needs 92 xp", Sim.next_xp_for_level(1) == 92)
	_check("threshold grows with level", Sim.next_xp_for_level(2) > Sim.next_xp_for_level(1))

func _test_xp_below_threshold() -> void:
	var sim := Sim.new()
	var leveled := sim.add_xp(10)
	_check("a little xp does not level you", not leveled and sim.level == 1 and sim.xp == 10)

func _test_level_up_carries_remainder() -> void:
	var sim := Sim.new()
	var leveled := sim.add_xp(100)  # level-1 threshold is 92
	_check("crossing the threshold levels up", leveled and sim.level == 2)
	_check("remainder carries over (100 - 92 = 8)", sim.xp == 8)
	_check("next threshold becomes level 2's", sim.next_xp == Sim.next_xp_for_level(2))
