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
	_test_rekindle_readout()
	print("")
	if _failed == 0 and _passed > 0:
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

# format_clock is M:SS for a COUNT-DOWN clock: round up so any time left still
# reads on the dial, and only the true end shows 0:00.
func _test_format_clock() -> void:
	_check_eq("zero -> 0:00", Hud.format_clock(0.0), "0:00")
	_check_eq("5s -> 0:05 (zero-padded)", Hud.format_clock(5.0), "0:05")
	_check_eq("65s -> 1:05", Hud.format_clock(65.0), "1:05")
	_check_eq("125s -> 2:05", Hud.format_clock(125.0), "2:05")
	_check_eq("full run 240s -> 4:00", Hud.format_clock(240.0), "4:00")
	_check_eq("negative clamps to 0:00", Hud.format_clock(-5.0), "0:00")
	# Count-down rounding: fractional time left rounds UP, never down to 0:00.
	_check_eq("0.1s left rounds up -> 0:01", Hud.format_clock(0.1), "0:01")
	_check_eq("59.1s left rounds up -> 1:00", Hud.format_clock(59.1), "1:00")

# rekindle_readout replaced the countdown (ADR 0005): the objective when Dormant, the
# live channel % while Rekindling, the win line when Rekindled. No clock, no round count.
func _test_rekindle_readout() -> void:
	_check_eq("dormant -> objective prompt", Hud.rekindle_readout(Simulation.BEACON_DORMANT, 0.0), "REKINDLE BEACON")
	_check_eq("rekindling shows live percent", Hud.rekindle_readout(Simulation.BEACON_REKINDLING, 0.6), "REKINDLING 60%")
	_check_eq("rekindling rounds the percent", Hud.rekindle_readout(Simulation.BEACON_REKINDLING, 0.005), "REKINDLING 1%")
	_check_eq("rekindled -> win line", Hud.rekindle_readout(Simulation.BEACON_REKINDLED, 1.0), "BEACON REKINDLED")
