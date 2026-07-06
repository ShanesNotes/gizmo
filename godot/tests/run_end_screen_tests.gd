extends SceneTree

# Headless tests for the end screen's copy and rendered scene state.
#   godot --headless --path godot --script res://tests/run_end_screen_tests.gd
# Exits 0 if all pass, 1 if any fail.

var _passed := 0
var _failed := 0

const EndScreen := preload("res://scripts/end_screen.gd")
const EndScreenScene := preload("res://scenes/end_screen.tscn")

func _initialize() -> void:
	print("Running end-screen tests…")
	_test_outcome()
	await _test_show_outcome()
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

func _check_no_match(desc: String, text: String, regex: RegEx) -> void:
	if regex.search(text) == null:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s (matched forbidden text in %s)" % [desc, text])

func _screen_text(screen: Node) -> String:
	var parts: Array[String] = []
	_collect_text(screen, parts)
	return "\n".join(parts)

func _collect_text(node: Node, parts: Array[String]) -> void:
	if node is Label or node is Button:
		parts.append(node.text)
	for child in node.get_children():
		_collect_text(child, parts)

func _make_sim(phase: String, level: int, kills: int, sparks: int) -> Simulation:
	var sim := Simulation.new()
	sim.phase = phase
	sim.level = level
	sim.kills = kills
	sim.xp = sparks
	sim.elapsed = 137.0
	return sim

# outcome() maps the finished phase to {title, flavor, win}. A "playing" phase has
# no outcome (defensive empty title), so a mis-call shows nothing, not a wrong banner.
func _test_outcome() -> void:
	var win := EndScreen.outcome(Simulation.PHASE_COMPLETE)
	_check_eq("complete -> win", win["win"], true)
	_check_eq("complete -> Beacon Rekindled", win["title"], "Beacon Rekindled")

	var loss := EndScreen.outcome(Simulation.PHASE_GAMEOVER)
	_check_eq("gameover -> not win", loss["win"], false)
	_check_eq("gameover -> Gizmo's light failed", loss["title"], "Gizmo's light failed")

	var playing := EndScreen.outcome(Simulation.PHASE_PLAYING)
	_check_eq("playing -> no outcome (empty title)", playing["title"], "")
	_check_eq("playing -> not win", playing["win"], false)

func _test_show_outcome() -> void:
	var forbidden := RegEx.new()
	forbidden.compile("(?i)(survived|time|[0-9]+:[0-9]{2})")

	var win_screen := EndScreenScene.instantiate()
	get_root().add_child(win_screen)
	await process_frame
	win_screen.show_outcome(_make_sim(Simulation.PHASE_COMPLETE, 4, 9, 27))
	_check_eq("win path renders exact title", win_screen.get_node("Root/Center/Panel/Margin/VBox/TitleLabel").text, "Beacon Rekindled")
	_check_eq("win stats render level/kills/Sparks", win_screen.get_node("Root/Center/Panel/Margin/VBox/StatsValue").text, "Level 4 · 9 kills · 27 Sparks")
	_check_no_match("win screen has no survived/time/clock text", _screen_text(win_screen), forbidden)
	win_screen.queue_free()

	var loss_screen := EndScreenScene.instantiate()
	get_root().add_child(loss_screen)
	await process_frame
	loss_screen.show_outcome(_make_sim(Simulation.PHASE_GAMEOVER, 2, 3, 11))
	_check_eq("loss path renders exact title", loss_screen.get_node("Root/Center/Panel/Margin/VBox/TitleLabel").text, "Gizmo's light failed")
	_check_eq("loss stats render level/kills/Sparks", loss_screen.get_node("Root/Center/Panel/Margin/VBox/StatsValue").text, "Level 2 · 3 kills · 11 Sparks")
	_check_no_match("loss screen has no survived/time/clock text", _screen_text(loss_screen), forbidden)
	loss_screen.queue_free()
