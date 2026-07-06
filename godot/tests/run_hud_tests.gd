extends SceneTree

# Headless tests for the HUD's pure logic and Path-A chrome absence (HZ-050).
#   godot --headless --path godot --script res://tests/run_hud_tests.gd
# Exits 0 if all pass, 1 if any fail.

var _passed := 0
var _failed := 0

const Hud := preload("res://scripts/hud.gd")
const HudScene := preload("res://scenes/hud.tscn")

const RETIRED_NODE_PATHS: Array[String] = [
	"Root/LevelCluster",
	"Root/LevelCluster/GemBadge/LevelLabel",
	"Root/LevelCluster/XpBar",
	"Root/ObjectivePanel",
	"Root/ObjectivePanel/Margin/ObjectiveLabel",
	"Root/LevelUpFlash",
]

const RETIRED_SOURCE_TOKENS: Array[String] = [
	"beacon",
	"rekindle",
	"levellabel",
	"levelcluster",
	"level_up",
	"xpbar",
	"xp_progress",
	"xp_fill",
	"objectivelabel",
	"levelupflash",
]

func _initialize() -> void:
	print("Running HUD tests…")
	_test_format_clock()
	_test_retired_nodes_absent()
	_test_retired_source_tokens_absent()
	await _test_guard_pips()
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

func _check_null(desc: String, actual: Variant) -> void:
	if actual == null:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s (expected null, got %s)" % [desc, actual])

# format_clock is M:SS for elapsed/survived time displays. It rounds up so a
# partial second still reads; only true zero shows 0:00.
func _test_format_clock() -> void:
	_check_eq("zero -> 0:00", Hud.format_clock(0.0), "0:00")
	_check_eq("5s -> 0:05 (zero-padded)", Hud.format_clock(5.0), "0:05")
	_check_eq("65s -> 1:05", Hud.format_clock(65.0), "1:05")
	_check_eq("125s -> 2:05", Hud.format_clock(125.0), "2:05")
	_check_eq("full run 240s -> 4:00", Hud.format_clock(240.0), "4:00")
	_check_eq("negative clamps to 0:00", Hud.format_clock(-5.0), "0:00")
	_check_eq("0.1s left rounds up -> 0:01", Hud.format_clock(0.1), "0:01")
	_check_eq("59.1s left rounds up -> 1:00", Hud.format_clock(59.1), "1:00")

func _test_retired_nodes_absent() -> void:
	var hud: Node = HudScene.instantiate()
	var root: Node = hud.get_node("Root")
	for path in RETIRED_NODE_PATHS:
		_check_null("retired node absent: %s" % path, root.get_node_or_null(path))
	hud.free()

func _test_retired_source_tokens_absent() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/hud.gd").to_lower()
	for token in RETIRED_SOURCE_TOKENS:
		if source.find(token) == -1:
			_passed += 1
			print("  ok   - hud.gd has no '%s' identifier" % token)
		else:
			_failed += 1
			printerr("  FAIL - hud.gd still contains '%s'" % token)


func _instantiate_hud() -> Hud:
	var hud: Hud = HudScene.instantiate()
	root.add_child(hud)
	await process_frame
	return hud


func _cleanup_hud(hud: Hud) -> void:
	hud.queue_free()
	await process_frame


func _guard_pip_counts(hud: Hud) -> Dictionary:
	var row: HBoxContainer = hud.get_node("%GuardPips") as HBoxContainer
	var visible := 0
	var filled := 0
	for child in row.get_children():
		var pip := child as ColorRect
		if not pip.visible:
			continue
		visible += 1
		if is_equal_approx(pip.color.a, 1.0):
			filled += 1
	return {"row_visible": row.visible, "visible": visible, "filled": filled}


func _test_guard_pips() -> void:
	var hud := await _instantiate_hud()
	var counts := _guard_pip_counts(hud)
	_check_eq("guard pips hidden by default (row)", counts["row_visible"], false)

	hud.render_guard(0, 0)
	counts = _guard_pip_counts(hud)
	_check_eq("guard_max=0 hides GuardPips row", counts["row_visible"], false)

	hud.render_guard(2, 4)
	counts = _guard_pip_counts(hud)
	_check_eq("render_guard(2,4) shows row", counts["row_visible"], true)
	_check_eq("render_guard(2,4) shows 4 pips", counts["visible"], 4)
	_check_eq("render_guard(2,4) fills 2 pips", counts["filled"], 2)

	hud.render_guard(1, 2)
	counts = _guard_pip_counts(hud)
	_check_eq("render_guard(1,2) shows 2 pips", counts["visible"], 2)
	_check_eq("render_guard(1,2) fills 1 pip", counts["filled"], 1)

	hud.render_guard(99, 2)
	counts = _guard_pip_counts(hud)
	_check_eq("guard > guard_max clamps fill to guard_max", counts["filled"], 2)

	hud.render_guard(-3, 4)
	counts = _guard_pip_counts(hud)
	_check_eq("negative guard clamps to zero filled", counts["filled"], 0)

	hud.render_guard(1, -2)
	counts = _guard_pip_counts(hud)
	_check_eq("negative guard_max hides row", counts["row_visible"], false)

	hud.render_guard(3, 99)
	counts = _guard_pip_counts(hud)
	_check_eq("guard_max > cap shows at most 4 pips", counts["visible"], 4)
	_check_eq("guard_max > cap clamps fill", counts["filled"], 3)

	await _cleanup_hud(hud)