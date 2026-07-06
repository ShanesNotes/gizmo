extends SceneTree

# Headless tests for the end screen's run-summary contract.
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_end_screen_tests.gd
# Exits 0 if all pass, 1 if any fail.

var _passed := 0
var _failed := 0

const EndScreen := preload("res://scripts/end_screen.gd")
const EndScreenScene := preload("res://scenes/end_screen.tscn")

func _initialize() -> void:
	print("Running end-screen tests...")
	await _test_run_summary_renders_victory_payload()
	await _test_run_summary_renders_loss_payload()
	await _test_end_screen_declares_blocking_overlay_group()
	await _test_retired_copy_tokens_are_absent()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr("FAIL - %d passed, %d failed" % [_passed, _failed])
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s" % desc)

func _check_eq(desc: String, actual: Variant, want: Variant) -> void:
	_check("%s (got %s, want %s)" % [desc, actual, want], actual == want)

func _new_screen() -> EndScreen:
	var screen := EndScreenScene.instantiate() as EndScreen
	root.add_child(screen)
	await process_frame
	return screen

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _label_text(screen: EndScreen, node_path: String) -> String:
	var label := screen.get_node(node_path) as Label
	return label.text if label != null else ""

func _test_run_summary_renders_victory_payload() -> void:
	var screen := await _new_screen()
	screen.show_run_summary({
		"rooms_cleared": 8,
		"boons_taken": 3,
		"scrap_banked": 41,
		"survived_seconds": 125.2,
		"victory": true,
	})

	_check("summary becomes visible", screen.get_node("Root").visible)
	_check_eq("victory title", _label_text(screen, "Root/Center/Panel/Margin/VBox/TitleLabel"), "RUN COMPLETE")
	_check_eq("result stat", _label_text(screen, "Root/Center/Panel/Margin/VBox/Stats/ResultValue"), "COMPLETE")
	_check_eq("rooms stat", _label_text(screen, "Root/Center/Panel/Margin/VBox/Stats/RoomsValue"), "8")
	_check_eq("boons stat", _label_text(screen, "Root/Center/Panel/Margin/VBox/Stats/BoonsValue"), "3")
	_check_eq("scrap stat", _label_text(screen, "Root/Center/Panel/Margin/VBox/Stats/ScrapValue"), "41")
	_check_eq("survived stat uses HUD clock", _label_text(screen, "Root/Center/Panel/Margin/VBox/Stats/SurvivedValue"), "2:06")

	await _cleanup(screen)

func _test_run_summary_renders_loss_payload() -> void:
	var screen := await _new_screen()
	screen.show_run_summary({
		"rooms_cleared": 2,
		"boons_taken": 1,
		"scrap_banked": 7,
		"survived_seconds": 0.0,
		"victory": false,
	})

	_check_eq("loss title", _label_text(screen, "Root/Center/Panel/Margin/VBox/TitleLabel"), "RUN LOST")
	_check_eq("loss result stat", _label_text(screen, "Root/Center/Panel/Margin/VBox/Stats/ResultValue"), "LOST")
	_check_eq("zero survived stat", _label_text(screen, "Root/Center/Panel/Margin/VBox/Stats/SurvivedValue"), "0:00")

	await _cleanup(screen)

func _test_end_screen_declares_blocking_overlay_group() -> void:
	var screen := await _new_screen()
	_check("EndScreen participates in global blocking overlay group", screen.is_in_group(&"blocking_overlay"))
	await _cleanup(screen)

func _test_retired_copy_tokens_are_absent() -> void:
	var tokens: Array[String] = [
		"wa" + "ve",
		"count" + "down",
		"lev" + "el",
		"x" + "p",
	]
	var paths: Array[String] = [
		"res://scenes/end_screen.tscn",
		"res://scripts/end_screen.gd",
		"res://tests/run_end_screen_tests.gd",
	]
	for path in paths:
		var text := FileAccess.get_file_as_string(path).to_lower()
		for token in tokens:
			_check("%s retired token absent from %s" % [token, path], not text.contains(token))
