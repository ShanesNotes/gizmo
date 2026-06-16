extends SceneTree

const PanelScene := preload("res://ui/components/panel/panel.tscn")
const LumenTheme := preload("res://ui/theme.tres")

var _failures := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_theme_tokens()
	await _test_panel_instantiates()

	if _failures == 0:
		print("UI smoke tests passed")
	quit(_failures)

func _test_theme_tokens() -> void:
	_assert_true(LumenTheme is Theme, "theme.tres loads as a Theme")
	_assert_true(LumenTheme.has_color("gold_leaf", "LumenTokens"), "gold_leaf token exists")
	_assert_true(LumenTheme.has_color("panel", "LumenTokens"), "panel token exists")
	_assert_true(LumenTheme.has_color("lumen_dim", "LumenTokens"), "lumen_dim token exists")
	_assert_true(LumenTheme.has_constant("radius_md", "LumenTokens"), "radius_md token exists")
	_assert_true(LumenTheme.has_font_size("type_body", "LumenTokens"), "type_body token exists")
	_assert_true(LumenTheme.has_stylebox("gold", "LumenPanel"), "gold Panel style exists")
	_assert_true(LumenTheme.has_stylebox("danger", "LumenPanel"), "danger Panel style exists")
	_assert_true(LumenTheme.has_stylebox("plain", "LumenPanel"), "plain Panel style exists")

func _test_panel_instantiates() -> void:
	var panel := PanelScene.instantiate()
	get_root().add_child(panel)
	panel.set("eyebrow_text", "The Claiming")
	panel.set("body_text", "bounty verdict")
	panel.set("tone", 1)
	panel.set("dashed", false)
	await process_frame

	_assert_true(panel is PanelContainer, "Panel scene root is PanelContainer")
	_assert_equal(panel.name, "LumenPanel", "Panel scene root node name")
	_assert_equal(panel.get_node("Margin/Stack/Eyebrow").text, "THE CLAIMING", "eyebrow uppercases like the React Panel")
	_assert_equal(panel.get_node("Margin/Stack/Body").text, "bounty verdict", "body text syncs")
	_assert_equal(panel.get("tone"), 1, "danger tone is settable")
	_assert_equal(panel.get("dashed"), false, "dashed toggle is settable")
	panel.queue_free()

func _assert_true(value: bool, label: String) -> void:
	if not value:
		_failures += 1
		push_error("FAIL: %s" % label)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		_failures += 1
		push_error("FAIL: %s — expected %s, got %s" % [label, expected, actual])
