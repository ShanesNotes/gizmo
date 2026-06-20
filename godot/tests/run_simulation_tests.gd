extends SceneTree

# Tiny dependency-free test runner for the ported game logic. Run with:
#   godot --headless --path godot --script res://tests/run_simulation_tests.gd
# Exits 0 if all pass, 1 if any fail (so CI / the terminal can tell).

var _passed := 0
var _failed := 0

# Load by path so this runner works headless without an editor import step
# (a raw --script run doesn't refresh the global class_name cache).
const Sim := preload("res://scripts/simulation.gd")

func _initialize() -> void:
	print("Running simulation tests…")
	_test_next_xp_vectors()
	_test_xp_below_threshold()
	_test_level_up_carries_remainder()
	_test_xp_progress()
	_test_negative_ignored()
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
		printerr("  FAIL - ", desc)

func _check_eq(desc: String, actual, expected) -> void:
	if actual == expected:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s (got %s, expected %s)" % [desc, actual, expected])

# Exact vectors pin the formula faithfully (simulation.ts:1721-1725).
func _test_next_xp_vectors() -> void:
	_check_eq("next_xp lvl 1", Sim.next_xp_for_level(1), 92)
	_check_eq("next_xp lvl 2", Sim.next_xp_for_level(2), 188)
	_check_eq("next_xp lvl 3", Sim.next_xp_for_level(3), 291)
	_check_eq("next_xp lvl 5", Sim.next_xp_for_level(5), 595)
	_check_eq("next_xp lvl 10", Sim.next_xp_for_level(10), 1811)

func _test_xp_below_threshold() -> void:
	var sim := Sim.new()
	var leveled := sim.add_xp(10)
	_check("a few Sparks do not level you", not leveled)
	_check_eq("still level 1", sim.level, 1)
	_check_eq("Sparks banked", sim.xp, 10)

func _test_level_up_carries_remainder() -> void:
	var sim := Sim.new()
	var leveled := sim.add_xp(100)  # level-1 threshold is 92
	_check("crossing the threshold levels up", leveled)
	_check_eq("now level 2", sim.level, 2)
	_check_eq("remainder carries (100 - 92)", sim.xp, 8)
	_check_eq("next threshold is level 2's", sim.next_xp, Sim.next_xp_for_level(2))

func _test_xp_progress() -> void:
	var sim := Sim.new()
	sim.add_xp(46)  # ~half of 92
	_check("Sparks bar reads ~half full", absf(sim.xp_progress() - 0.5) < 0.05)

func _test_negative_ignored() -> void:
	var sim := Sim.new()
	sim.add_xp(-5)  # pickups are never negative; guard against it
	_check_eq("negative Sparks are ignored", sim.xp, 0)
