extends SceneTree

# Headless tests for the HUD's pure logic and Path-A chrome absence (HZ-050).
#   godot --headless --path godot --script res://tests/run_hud_tests.gd
# Exits 0 if all pass, 1 if any fail.

var _passed := 0
var _failed := 0

const Ability := preload("res://scripts/abilities/ability.gd")
const BoonDef := preload("res://scripts/boons/boon_def.gd")
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
	await _test_boon_loadout()
	await _test_ability_bar()
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


func _make_boon(
	display_name: String,
	rarity: BoonDef.Rarity,
	slot: BoonDef.Slot,
) -> BoonDef:
	var boon: BoonDef = BoonDef.new()
	boon.boon_id = StringName(display_name.to_lower().replace(" ", "_"))
	boon.display_name = display_name
	boon.rarity = rarity
	boon.slot = slot
	return boon


func _boon_loadout_row(hud: Hud, index: int) -> HBoxContainer:
	var loadout: VBoxContainer = hud.get_node("%BoonLoadout") as VBoxContainer
	return loadout.get_child(index) as HBoxContainer


func _row_slot_label(row: HBoxContainer) -> Label:
	return row.get_child(0) as Label


func _row_name_label(row: HBoxContainer) -> Label:
	return row.get_child(1) as Label


func _rarity_tint(rarity: BoonDef.Rarity) -> Color:
	match rarity:
		BoonDef.Rarity.COMMON:
			return Color(0.7412, 0.6431, 0.4980, 1.0)
		BoonDef.Rarity.RARE:
			return Color(0.4078, 0.7608, 0.8000, 1.0)
		BoonDef.Rarity.EPIC:
			return Color(0.6078, 0.4353, 0.8118, 1.0)
		BoonDef.Rarity.LEGENDARY:
			return Color(0.9059, 0.7176, 0.2824, 1.0)
		_:
			return Color(0.7412, 0.5176, 0.4078, 1.0)


func _test_boon_loadout() -> void:
	var hud := await _instantiate_hud()
	var loadout: VBoxContainer = hud.get_node("%BoonLoadout") as VBoxContainer
	_check_eq("boon loadout hidden by default", loadout.visible, false)
	_check_eq("boon loadout empty by default", loadout.get_child_count(), 0)

	hud.render_boons([])
	_check_eq("render_boons([]) hides BoonLoadout", loadout.visible, false)
	_check_eq("render_boons([]) clears rows", loadout.get_child_count(), 0)

	var first_pick: Array[BoonDef] = [
		_make_boon("Spark-Cut", BoonDef.Rarity.COMMON, BoonDef.Slot.ATTACK),
		_make_boon("Gyre Step", BoonDef.Rarity.RARE, BoonDef.Slot.DASH),
	]
	hud.render_boons(first_pick)
	_check_eq("render_boons(2) shows BoonLoadout", loadout.visible, true)
	_check_eq("render_boons(2) creates 2 rows", loadout.get_child_count(), 2)

	var row0 := _boon_loadout_row(hud, 0)
	var row1 := _boon_loadout_row(hud, 1)
	_check_eq("row 0 slot label", _row_slot_label(row0).text, "Attack")
	_check_eq("row 0 boon name", _row_name_label(row0).text, "Spark-Cut")
	_check_eq(
		"row 0 rarity tint",
		_row_name_label(row0).get_theme_color("font_color"),
		_rarity_tint(BoonDef.Rarity.COMMON),
	)
	_check_eq("row 1 slot label", _row_slot_label(row1).text, "Dash")
	_check_eq("row 1 boon name", _row_name_label(row1).text, "Gyre Step")
	_check_eq(
		"row 1 rarity tint",
		_row_name_label(row1).get_theme_color("font_color"),
		_rarity_tint(BoonDef.Rarity.RARE),
	)

	var second_pick: Array[BoonDef] = [
		_make_boon("Brass Wake", BoonDef.Rarity.EPIC, BoonDef.Slot.PASSIVE),
	]
	hud.render_boons(second_pick)
	_check_eq("re-render replaces rows (count)", loadout.get_child_count(), 1)
	_check_eq("re-render row 0 slot label", _row_slot_label(_boon_loadout_row(hud, 0)).text, "Passive")
	_check_eq(
		"re-render row 0 boon name",
		_row_name_label(_boon_loadout_row(hud, 0)).text,
		"Brass Wake",
	)
	_check_eq(
		"re-render row 0 rarity tint",
		_row_name_label(_boon_loadout_row(hud, 0)).get_theme_color("font_color"),
		_rarity_tint(BoonDef.Rarity.EPIC),
	)

	await _cleanup_hud(hud)


func _ability_bar_slot(hud: Hud, index: int) -> PanelContainer:
	var bar: HBoxContainer = hud.get_node("%AbilityBar") as HBoxContainer
	return bar.get_child(index) as PanelContainer


func _ability_slot_label(panel: PanelContainer) -> Label:
	var col: VBoxContainer = panel.get_child(0).get_child(0) as VBoxContainer
	return col.get_child(0) as Label


func _ability_status_label(panel: PanelContainer) -> Label:
	var col: VBoxContainer = panel.get_child(0).get_child(0) as VBoxContainer
	return col.get_child(1) as Label


func _test_ability_bar() -> void:
	var hud := await _instantiate_hud()
	var bar: HBoxContainer = hud.get_node("%AbilityBar") as HBoxContainer
	_check_eq("ability bar hidden by default", bar.visible, false)
	_check_eq("ability bar empty by default", bar.get_child_count(), 0)

	hud.render_abilities([])
	_check_eq("render_abilities([]) hides AbilityBar", bar.visible, false)
	_check_eq("render_abilities([]) clears slots", bar.get_child_count(), 0)

	var four_states: Array = [
		{"kind": Ability.AbilityKind.DASH, "ready": true, "count": 2},
		{"kind": Ability.AbilityKind.ATTACK, "ready": true, "count": -1},
		{"kind": Ability.AbilityKind.SPECIAL, "ready": false, "count": -1},
		{"kind": Ability.AbilityKind.CAST, "ready": true, "count": 5},
	]
	hud.render_abilities(four_states)
	_check_eq("render_abilities(4) shows AbilityBar", bar.visible, true)
	_check_eq("render_abilities(4) creates 4 slots", bar.get_child_count(), 4)

	var dash_slot := _ability_bar_slot(hud, 0)
	var attack_slot := _ability_bar_slot(hud, 1)
	var special_slot := _ability_bar_slot(hud, 2)
	var cast_slot := _ability_bar_slot(hud, 3)
	_check_eq("slot 0 kind label", _ability_slot_label(dash_slot).text, "DASH")
	_check_eq("slot 1 kind label", _ability_slot_label(attack_slot).text, "ATTACK")
	_check_eq("slot 2 kind label", _ability_slot_label(special_slot).text, "SPECIAL")
	_check_eq("slot 3 kind label", _ability_slot_label(cast_slot).text, "CAST")
	_check_eq("ready slot modulate alpha", is_equal_approx(dash_slot.modulate.a, 1.0), true)
	_check_eq("not-ready slot dims (alpha 0.4)", is_equal_approx(special_slot.modulate.a, 0.4), true)
	_check_eq("count >= 0 shows status text", _ability_status_label(dash_slot).text, "2")
	_check_eq("count >= 0 status visible", _ability_status_label(dash_slot).visible, true)
	_check_eq("count -1 hides status label", _ability_status_label(attack_slot).visible, false)
	_check_eq("cast ammo count", _ability_status_label(cast_slot).text, "5")

	var second_states: Array = [
		{"kind": Ability.AbilityKind.ATTACK, "ready": false, "count": 1},
	]
	hud.render_abilities(second_states)
	_check_eq("re-render replaces slots (count)", bar.get_child_count(), 1)
	var rerendered := _ability_bar_slot(hud, 0)
	_check_eq("re-render slot 0 kind label", _ability_slot_label(rerendered).text, "ATTACK")
	_check_eq("re-render slot 0 count", _ability_status_label(rerendered).text, "1")
	_check_eq("re-render not-ready dims", is_equal_approx(rerendered.modulate.a, 0.4), true)

	await _cleanup_hud(hud)