extends SceneTree

# Headless tests for the end screen's pure logic. The visual layout is verified by
# eye (run res://scenes/end_screen.tscn); only outcome() — the phase→copy mapping —
# is unit-tested.
#   godot --headless --path godot --script res://tests/run_end_screen_tests.gd
# Exits 0 if all pass, 1 if any fail.

var _passed := 0
var _failed := 0

const EndScreen := preload("res://scripts/end_screen.gd")

func _initialize() -> void:
	print("Running end-screen tests…")
	_test_outcome()
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

# outcome() maps the finished phase to {title, flavor, win}. A "playing" phase has
# no outcome (defensive empty title), so a mis-call shows nothing, not a wrong banner.
func _test_outcome() -> void:
	var win := EndScreen.outcome(Simulation.PHASE_COMPLETE)
	_check_eq("complete -> win", win["win"], true)
	_check_eq("complete -> RUN COMPLETE", win["title"], "RUN COMPLETE")

	var loss := EndScreen.outcome(Simulation.PHASE_GAMEOVER)
	_check_eq("gameover -> not win", loss["win"], false)
	_check_eq("gameover -> GIZMO OFFLINE", loss["title"], "GIZMO OFFLINE")

	var playing := EndScreen.outcome(Simulation.PHASE_PLAYING)
	_check_eq("playing -> no outcome (empty title)", playing["title"], "")
	_check_eq("playing -> not win", playing["win"], false)
