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