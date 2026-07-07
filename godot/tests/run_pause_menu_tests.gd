extends SceneTree

# Headless tests for HZ-106 pause menu behavior.
# Run with:
#   godot --headless --user-data-dir=/tmp/codex-godot-userdata-106 --path godot --script res://tests/run_pause_menu_tests.gd

const PauseMenuScene := preload("res://scenes/pause_menu.tscn")
const AppScene := preload("res://scenes/app.tscn")
const RunScene := preload("res://scenes/run.tscn")
const BoonDraftScene := preload("res://scenes/boon_draft.tscn")
const BoonDef := preload("res://scripts/boons/boon_def.gd")

const TEST_SAVE_ROOT := "/tmp/codex-godot-userdata-106/saves"

class StubRunSurface:
	extends Node

	signal player_died()
	signal run_completed()

	var run_active := true

	func _init(active: bool = true) -> void:
		run_active = active
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

func _initialize() -> void:
	print("Running pause menu tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_ui_cancel_toggles_pause_and_visibility()
	await _test_overlay_visibility_tracks_external_pause_state()
	await _test_resume_button_unpauses_tree()
	await _test_settings_button_opens_shared_panel()
	await _test_pause_guard_rejects_inactive_run_surface()
	await _test_real_app_shell_parented_end_screen_blocks_pause_guard()
	await _test_real_paused_death_teardown_unpauses_and_cancel_stays_blocked()
	await _test_abandon_run_uses_death_path_and_banks_currency()
	await _test_active_boon_draft_freezes_under_pause_overlay_then_resumes()
	await _test_no_pause_when_overlay_absent()
	await _test_run_scene_instances_pause_overlay()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => pause menu failed to load/compile)" if _passed == 0 else ""]
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

func _make_cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	return event

func _make_key_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event

func _make_boon(boon_id: StringName) -> BoonDef:
	var boon: BoonDef = BoonDef.new()
	boon.boon_id = boon_id
	boon.display_name = String(boon_id).capitalize()
	boon.description = "Test boon."
	boon.rarity = BoonDef.Rarity.COMMON
	boon.slot = BoonDef.Slot.ATTACK
	boon.domain = "test"
	return boon

func _new_harness(active: bool = true) -> Dictionary:
	var surface := StubRunSurface.new(active)
	surface.name = "Run"
	root.add_child(surface)
	var menu := PauseMenuScene.instantiate()
	surface.add_child(menu)
	await process_frame
	return {
		"surface": surface,
		"menu": menu,
	}

func _cleanup_harness(harness: Dictionary) -> void:
	paused = false
	var surface := harness.get("surface") as Node
	if surface != null and is_instance_valid(surface):
		surface.queue_free()
	await process_frame
	await process_frame
	paused = false

func _send_cancel(menu: Node) -> void:
	menu._unhandled_input(_make_cancel_event())
	await process_frame

func _resume_button(menu: Node) -> Button:
	return menu.get_node("Root/Center/Panel/Margin/VBox/ResumeButton") as Button

func _abandon_button(menu: Node) -> Button:
	return menu.get_node("Root/Center/Panel/Margin/VBox/AbandonButton") as Button

func _settings_button(menu: Node) -> Button:
	return menu.get_node("Root/Center/Panel/Margin/VBox/SettingsButton") as Button

func _settings_panel(menu: Node) -> Node:
	return menu.get_node("SettingsPanel")

func _new_save_path(test_name: String) -> String:
	return "%s/pause_menu_%s.cfg" % [TEST_SAVE_ROOT, test_name]

func _remove_save(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _new_real_app(save_path: String) -> Node:
	_remove_save(save_path)
	var app := AppScene.instantiate()
	app.meta_save_path = save_path
	root.add_child(app)
	await process_frame
	return app

func _current_content(app: Node) -> Node:
	var slot := app.get_node_or_null("ContentSlot")
	if slot == null or slot.get_child_count() == 0:
		return null
	return slot.get_child(0)

func _start_real_run(app: Node) -> Node:
	var hub := _current_content(app)
	if hub != null and hub.has_signal(&"run_requested"):
		hub.emit_signal(&"run_requested")
	await _flush_free_queue()
	return _current_content(app)

func _show_real_end_screen_overlay(app: Node, scrap_banked: int = 0) -> Node:
	app.call(&"_show_run_summary_overlay", {
		"victory": false,
		"rooms_cleared": 1,
		"boons_taken": 0,
		"scrap_banked": scrap_banked,
		"sparks_banked": 0,
		"survived_seconds": 0.0,
	})
	await process_frame
	return app.get("_summary_overlay") as Node

func _flush_free_queue() -> void:
	await process_frame
	await process_frame

func _cleanup_app(app: Node, save_path: String) -> void:
	paused = false
	if app != null and is_instance_valid(app):
		app.queue_free()
	await _flush_free_queue()
	_remove_save(save_path)
	paused = false

func _saved_return_snapshot(path: String) -> Dictionary:
	var cfg := ConfigFile.new()
	var load_error := cfg.load(path)
	if load_error != OK:
		return {}
	return {
		"scrap_banked": int(cfg.get_value("currency", "scrap_banked", -1)),
		"sparks_banked": int(cfg.get_value("currency", "sparks_banked", -1)),
		"last_return_was_victory": bool(cfg.get_value("run_history", "last_return_was_victory", true)),
	}

func _test_ui_cancel_toggles_pause_and_visibility() -> void:
	var harness := await _new_harness()
	var menu := harness["menu"] as Node

	_check("menu starts with tree unpaused", not paused)
	_check("overlay starts hidden", not menu.is_overlay_visible())

	await _send_cancel(menu)
	_check("ui_cancel pauses the tree", paused)
	_check("overlay is visible while paused", menu.is_overlay_visible())

	await _send_cancel(menu)
	_check("second ui_cancel unpauses the tree", not paused)
	_check("overlay hides after unpause", not menu.is_overlay_visible())

	await _cleanup_harness(harness)

func _test_overlay_visibility_tracks_external_pause_state() -> void:
	var harness := await _new_harness()
	var menu := harness["menu"] as Node

	paused = true
	await process_frame
	_check("overlay shows when tree is paused externally", menu.is_overlay_visible())

	paused = false
	await process_frame
	_check("overlay hides when tree is unpaused externally", not menu.is_overlay_visible())

	await _cleanup_harness(harness)

func _test_resume_button_unpauses_tree() -> void:
	var harness := await _new_harness()
	var menu := harness["menu"] as Node

	await _send_cancel(menu)
	_resume_button(menu).emit_signal(&"pressed")
	await process_frame

	_check("resume button unpauses the tree", not paused)
	_check("resume button hides the overlay", not menu.is_overlay_visible())

	await _cleanup_harness(harness)

func _test_settings_button_opens_shared_panel() -> void:
	var harness := await _new_harness()
	var menu := harness["menu"] as Node

	await _send_cancel(menu)
	_check("settings button exists", _settings_button(menu) is Button)
	_check("settings panel exists", _settings_panel(menu) != null)

	_settings_button(menu).emit_signal(&"pressed")
	await process_frame

	var panel := _settings_panel(menu)
	_check("settings button opens settings panel", panel.has_method(&"is_open") and bool(panel.call(&"is_open")))
	_check("opening settings preserves pause state", paused)
	_check("opening settings preserves pause overlay", menu.is_overlay_visible())

	if panel.has_method(&"close"):
		panel.call(&"close")

	await _cleanup_harness(harness)

func _test_pause_guard_rejects_inactive_run_surface() -> void:
	var harness := await _new_harness(false)
	var menu := harness["menu"] as Node

	await _send_cancel(menu)

	_check("inactive run surface does not pause", not paused)
	_check("inactive run surface keeps overlay hidden", not menu.is_overlay_visible())

	await _cleanup_harness(harness)

func _test_real_app_shell_parented_end_screen_blocks_pause_guard() -> void:
	var save_path := _new_save_path("blocking_overlay")
	var app := await _new_real_app(save_path)
	var run := await _start_real_run(app)
	var menu := run.get_node("PauseMenu") as PauseMenu
	var overlay := await _show_real_end_screen_overlay(app)

	_check("real run scene exposes PauseMenu", menu is PauseMenu)
	_check("real AppShell parents EndScreen overlay on itself", overlay != null and overlay.get_parent() == app)

	await _send_cancel(menu)

	_check("real shell-level EndScreen blocks ui_cancel pause", not paused)
	_check("pause UI stays hidden behind shell-level EndScreen", not menu.is_overlay_visible())

	await _cleanup_app(app, save_path)

func _test_real_paused_death_teardown_unpauses_and_cancel_stays_blocked() -> void:
	var save_path := _new_save_path("paused_death")
	var app := await _new_real_app(save_path)
	var run := await _start_real_run(app)
	var menu := run.get_node("PauseMenu") as PauseMenu

	await _send_cancel(menu)
	_check("real run is paused before death", paused and menu.is_overlay_visible())

	run.emit_signal(&"player_died")
	await _flush_free_queue()
	var overlay := app.get("_summary_overlay") as Node

	_check("paused death teardown unpauses the tree", not paused)
	_check("paused death leaves real EndScreen overlay live", overlay != null and overlay.is_inside_tree())

	Input.parse_input_event(_make_cancel_event())
	await process_frame
	_check("ui_cancel with real EndScreen overlay live does not pause", not paused)

	await _cleanup_app(app, save_path)

func _test_abandon_run_uses_death_path_and_banks_currency() -> void:
	var save_path := _new_save_path("abandon_run")
	var app := await _new_real_app(save_path)
	var run := await _start_real_run(app)
	var menu := run.get_node("PauseMenu") as PauseMenu
	var death_events := {"count": 0}
	run.player_died.connect(func() -> void:
		death_events["count"] = int(death_events["count"]) + 1
	)
	run.scrap_earned = 31
	run.sparks_earned = 4

	await _send_cancel(menu)
	_abandon_button(menu).emit_signal(&"pressed")
	await _flush_free_queue()

	_check_eq("Abandon Run emits the run surface death signal once", int(death_events["count"]), 1)
	_check("Abandon Run unpauses before hub return", not paused)
	_check("Abandon Run frees the old run surface", not is_instance_valid(run))
	_check_eq("Abandon Run records loss outcome", bool(app.last_run_summary.get("victory", true)), false)
	_check_eq("Abandon Run banks scrap through death summary", int(app.last_run_summary.get("scrap_banked", -1)), 31)
	_check_eq("Abandon Run banks sparks through death summary", int(app.last_run_summary.get("sparks_banked", -1)), 4)
	_check_eq("Abandon Run save matches death-path banking", _saved_return_snapshot(save_path), {
		"scrap_banked": 31,
		"sparks_banked": 4,
		"last_return_was_victory": false,
	})

	await _cleanup_app(app, save_path)

func _test_active_boon_draft_freezes_under_pause_overlay_then_resumes() -> void:
	var surface := StubRunSurface.new()
	surface.name = "RunWithDraft"
	root.add_child(surface)
	var draft := BoonDraftScene.instantiate() as BoonDraftUI
	surface.add_child(draft)
	var menu := PauseMenuScene.instantiate()
	surface.add_child(menu)
	await process_frame

	var chosen_ids: Array[StringName] = []
	draft.boon_chosen.connect(func(boon: BoonDef) -> void:
		chosen_ids.append(boon.boon_id)
	)
	var offers: Array[BoonDef] = [
		_make_boon(&"draft_one"),
		_make_boon(&"draft_two"),
		_make_boon(&"draft_three"),
	]
	draft.present(offers)

	await _send_cancel(menu)
	Input.parse_input_event(_make_key_event(KEY_1))
	await process_frame

	_check("open boon draft remains visible under pause overlay", draft.visible)
	_check_eq("paused boon draft ignores choice input", chosen_ids.size(), 0)

	await _send_cancel(menu)
	Input.parse_input_event(_make_key_event(KEY_1))
	await process_frame

	_check_eq("boon draft accepts normally after resume", chosen_ids, [&"draft_one"])
	_check("boon draft hides after resumed choice", not draft.visible)

	await _cleanup_harness({"surface": surface, "menu": menu})

func _test_no_pause_when_overlay_absent() -> void:
	var surface := StubRunSurface.new()
	surface.name = "RunWithoutPauseMenu"
	root.add_child(surface)

	Input.parse_input_event(_make_cancel_event())
	await process_frame

	_check("ui_cancel does not pause without pause overlay in tree", not paused)

	surface.queue_free()
	await process_frame

func _test_run_scene_instances_pause_overlay() -> void:
	var run = RunScene.instantiate()
	run.auto_start = false
	root.add_child(run)
	await process_frame
	var menu := run.get_node_or_null("PauseMenu") as PauseMenu

	_check("run scene marks root as run_surface group", run.is_in_group(&"run_surface"))
	_check("run scene instances pause menu at run root", menu is PauseMenu and menu.get_parent() == run)
	_check_eq("run scene PauseMenu processes while paused", menu.process_mode, Node.PROCESS_MODE_ALWAYS)

	run.queue_free()
	await _flush_free_queue()
