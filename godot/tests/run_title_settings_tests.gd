extends SceneTree

# Headless tests for HZ-092 title screen and shared settings panel.
# Run with:
#   HOME=/tmp/codex-godot-userdata-092 godot --headless --user-data-dir=/tmp/codex-godot-userdata-092 --path godot --script res://tests/run_title_settings_tests.gd

const TitleScreenScene := preload("res://scenes/title_screen.tscn")
const SettingsPanelScene := preload("res://scenes/settings_panel.tscn")
const PauseMenuScene := preload("res://scenes/pause_menu.tscn")

const EXPECTED_MAIN_SCENE := "res://scenes/title_screen.tscn"
const TEST_SETTINGS_PATH := "user://title_settings_tests.cfg"

class StubRunSurface:
	extends Node

	signal player_died()
	signal run_completed()

	var run_active := true

	func _init() -> void:
		add_to_group(&"run_surface")

	func run_summary(_victory: bool = false) -> Dictionary:
		return {
			"victory": _victory,
			"rooms_cleared": 0,
			"boons_taken": 0,
			"scrap_banked": 0,
			"sparks_banked": 0,
			"survived_seconds": 0.0,
		}

var _passed := 0
var _failed := 0
var _original_bus_db := {}

func _initialize() -> void:
	print("Running title/settings tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	_original_bus_db = _snapshot_bus_db()
	_remove_settings_file()

	await _test_project_main_scene_points_at_title()
	await _test_title_scene_loads_headless()
	await _test_title_settings_button_opens_panel()
	await _test_start_path_reaches_app_shell()
	await _test_volume_sliders_apply_persist_and_reload()
	await _test_pause_menu_settings_button_exists_and_opens_panel()

	_restore_bus_db(_original_bus_db)
	_remove_settings_file()

	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => title/settings suite failed to load/compile)" if _passed == 0 else ""]
		)
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s" % desc)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	_check("%s (got %s, expected %s)" % [desc, actual, expected], actual == expected)

func _check_almost(desc: String, actual: float, expected: float, tolerance: float = 0.001) -> void:
	_check(
		"%s (got %.4f, expected %.4f)" % [desc, actual, expected],
		absf(actual - expected) <= tolerance
	)

func _remove_settings_file() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))

func _snapshot_bus_db() -> Dictionary:
	var snapshot := {}
	for bus_name in [&"Master", &"Music", &"SFX"]:
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			snapshot[bus_name] = AudioServer.get_bus_volume_db(index)
	return snapshot

func _restore_bus_db(snapshot: Dictionary) -> void:
	for bus_name in snapshot.keys():
		var index := AudioServer.get_bus_index(bus_name)
		if index >= 0:
			AudioServer.set_bus_volume_db(index, float(snapshot[bus_name]))

func _slider(panel: Node, slider_name: String) -> HSlider:
	return panel.get_node("Root/Center/Panel/Margin/VBox/SettingsGrid/%s" % slider_name) as HSlider

func _bus_volume_db(bus_name: StringName) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return INF
	return AudioServer.get_bus_volume_db(index)

func _object_has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _make_cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	return event

func _new_pause_harness() -> Dictionary:
	var surface := StubRunSurface.new()
	surface.name = "Run"
	root.add_child(surface)
	var menu := PauseMenuScene.instantiate()
	surface.add_child(menu)
	await process_frame
	return {
		"surface": surface,
		"menu": menu,
	}

func _cleanup_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
	await process_frame
	await process_frame

func _test_project_main_scene_points_at_title() -> void:
	_check_eq(
		"project main scene points at title_screen.tscn",
		ProjectSettings.get_setting("application/run/main_scene"),
		EXPECTED_MAIN_SCENE
	)

func _test_title_scene_loads_headless() -> void:
	var title := TitleScreenScene.instantiate()
	root.add_child(title)
	await process_frame

	_check("title scene instantiates", title != null and title.is_inside_tree())
	_check_eq("wordmark renders", title.get_node("Center/Menu/WordmarkLabel").text, "GIZMO")
	_check_eq("subtitle renders sentence case", title.get_node("Center/Menu/SubtitleLabel").text, "keep it safe, keep it alive")
	_check("START button exists", title.get_node_or_null("Center/Menu/StartButton") is Button)
	_check("SETTINGS button exists on title", title.get_node_or_null("Center/Menu/SettingsButton") is Button)
	_check("QUIT button exists", title.get_node_or_null("Center/Menu/QuitButton") is Button)

	await _cleanup_node(title)

func _test_title_settings_button_opens_panel() -> void:
	var title := TitleScreenScene.instantiate()
	root.add_child(title)
	await process_frame

	var settings_button := title.get_node("Center/Menu/SettingsButton") as Button
	var panel := title.get_node("SettingsPanel") as Node
	settings_button.emit_signal(&"pressed")
	await process_frame

	_check("title settings panel exposes open state", panel != null and panel.has_method(&"is_open"))
	_check("title settings button opens settings panel", panel != null and bool(panel.call(&"is_open")))

	await _cleanup_node(title)

func _test_start_path_reaches_app_shell() -> void:
	var title := TitleScreenScene.instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame

	var start_button := title.get_node("Center/Menu/StartButton") as Button
	start_button.emit_signal(&"pressed")
	await process_frame
	await process_frame

	var next_scene := current_scene
	_check("START changes away from title screen", next_scene != null and next_scene != title)
	_check(
		"START reaches AppShell duck type",
		next_scene != null
		and next_scene.get_node_or_null("ContentSlot") != null
		and _object_has_property(next_scene, "hub_scene")
		and _object_has_property(next_scene, "run_surface_scene")
	)

	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
	current_scene = null
	await process_frame
	await process_frame

func _test_volume_sliders_apply_persist_and_reload() -> void:
	_remove_settings_file()

	var panel := SettingsPanelScene.instantiate()
	panel.settings_path = TEST_SETTINGS_PATH
	root.add_child(panel)
	await process_frame

	var cases := [
		{"bus": &"Master", "slider": "MasterSlider", "key": "master", "value": 0.80},
		{"bus": &"Music", "slider": "MusicSlider", "key": "music", "value": 0.42},
		{"bus": &"SFX", "slider": "SFXSlider", "key": "sfx", "value": 0.64},
	]

	for item in cases:
		var slider := _slider(panel, item["slider"])
		slider.value = float(item["value"])
		await process_frame
		_check_almost(
			"%s slider maps to bus volume_db" % String(item["bus"]),
			_bus_volume_db(item["bus"]),
			linear_to_db(float(item["value"]))
		)

	var cfg := ConfigFile.new()
	var load_error := cfg.load(TEST_SETTINGS_PATH)
	_check_eq("settings ConfigFile is written", load_error, OK)
	for item in cases:
		_check_almost(
			"%s slider persists linear value" % String(item["bus"]),
			float(cfg.get_value("audio", String(item["key"]), -1.0)),
			float(item["value"])
		)

	await _cleanup_node(panel)
	for item in cases:
		var index := AudioServer.get_bus_index(item["bus"])
		if index >= 0:
			AudioServer.set_bus_volume_db(index, 0.0)

	var reloaded := SettingsPanelScene.instantiate()
	reloaded.settings_path = TEST_SETTINGS_PATH
	root.add_child(reloaded)
	await process_frame

	for item in cases:
		_check_almost(
			"%s persisted value reloads into bus volume_db" % String(item["bus"]),
			_bus_volume_db(item["bus"]),
			linear_to_db(float(item["value"]))
		)
		_check_almost(
			"%s persisted value reloads into slider" % String(item["bus"]),
			_slider(reloaded, item["slider"]).value,
			float(item["value"])
		)

	await _cleanup_node(reloaded)

func _test_pause_menu_settings_button_exists_and_opens_panel() -> void:
	var harness := await _new_pause_harness()
	var menu := harness["menu"] as Node

	menu._unhandled_input(_make_cancel_event())
	await process_frame

	var settings_button := menu.get_node_or_null("Root/Center/Panel/Margin/VBox/SettingsButton") as Button
	var settings_panel := menu.get_node_or_null("SettingsPanel") as Node
	_check("pause menu settings button exists", settings_button is Button)
	_check("pause menu settings panel exists", settings_panel != null)

	if settings_button != null:
		settings_button.emit_signal(&"pressed")
	await process_frame

	_check(
		"pause menu settings button opens panel",
		settings_panel != null and settings_panel.has_method(&"is_open") and bool(settings_panel.call(&"is_open"))
	)
	_check("opening pause settings keeps tree paused", paused)

	paused = false
	await _cleanup_node(harness["surface"] as Node)
