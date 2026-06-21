extends SceneTree

# Headless tests for the HUD's pure logic. The HUD's visual layout is verified by eye
# (run res://scenes/hud.tscn); only the pure formatter (format_clock) is unit-tested.
#   godot --headless --path godot --script res://tests/run_hud_tests.gd
# Exits 0 if all pass, 1 if any fail.

var _passed := 0
var _failed := 0

const Hud := preload("res://scripts/hud.gd")

func _initialize() -> void:
	print("Running HUD tests…")
	_test_format_clock()
	print("")
	if _failed == 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL — %d passed, %d failed" % [_passed, _failed])
		quit(1)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	if actual == expected:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s (got %s, expected %s)" % [desc, actual, expected])

# format_clock is M:SS, whole seconds, clamped at zero (the run-timer readout).
func _test_format_clock() -> void:
	_check_eq("zero -> 0:00", Hud.format_clock(0.0), "0:00")
	_check_eq("5s -> 0:05 (zero-padded)", Hud.format_clock(5.0), "0:05")
	_check_eq("65s -> 1:05", Hud.format_clock(65.0), "1:05")
	_check_eq("125s -> 2:05", Hud.format_clock(125.0), "2:05")
	_check_eq("full run 240s -> 4:00", Hud.format_clock(240.0), "4:00")
	_check_eq("negative clamps to 0:00", Hud.format_clock(-5.0), "0:00")
