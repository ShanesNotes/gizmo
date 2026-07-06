extends SceneTree

# Headless tests for HZ-042 AppShell death -> hub -> new run wiring.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_app_shell_tests.gd

const AppShellScript := preload("res://scripts/app_shell.gd")
const AppScene := preload("res://scenes/app.tscn")
const HubControllerScript := preload("res://scripts/hub_controller.gd")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RunLifecycle := preload("res://scripts/meta/run_lifecycle.gd")

class StubRunSurface:
	extends Node

	signal player_died()
	signal run_completed()

	var start_call_count := 0
	var received_bonuses: Dictionary = {}

	func start_run(run_bonuses: Dictionary) -> void:
		start_call_count += 1
		received_bonuses = run_bonuses.duplicate(true)

class MissingRunSignalsSurface:
	extends Node

	var start_call_count := 0

	func start_run(_run_bonuses: Dictionary) -> void:
		start_call_count += 1

var _passed := 0
var _failed := 0
var _surface_index := 0

func _initialize() -> void:
	print("Running AppShell tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_boots_into_hub_with_loaded_meta_state()
	await _test_hub_run_request_swaps_to_run_surface_with_bonuses()
	await _test_running_phase_ignores_reentrant_run_request()
	await _test_malformed_run_surface_is_rejected_without_leaving_hub()
	await _test_player_death_banks_saves_and_returns_to_hub()
	await _test_new_run_dismisses_lingering_summary_overlay()
	await _test_victory_returns_to_hub_and_persists_outcome_flag()
	await _test_double_death_same_frame_banks_once()
	await _test_double_victory_same_frame_banks_once()
	await _test_meta_persists_across_app_restart()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => AppShell failed to load/compile)" if _passed == 0 else ""]
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

func _make_stub_run_surface() -> Node:
	_surface_index += 1
	var surface := StubRunSurface.new()
	surface.name = "StubRunSurface%d" % _surface_index
	return surface

func _make_missing_signal_surface() -> Node:
	var surface := MissingRunSignalsSurface.new()
	surface.name = "MissingRunSignalsSurface"
	return surface

func _new_save_path(test_name: String) -> String:
	return "user://saves/app_shell_%s.cfg" % test_name

func _remove_save(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _new_app(save_path: String) -> Node:
	var app: Node = AppScene.instantiate()
	if app == null:
		_check("app scene instantiates", false)
		return null
	if app.get_script() != AppShellScript:
		_check("app scene has AppShell script before configuration", false)
		app.queue_free()
		return null
	app.meta_save_path = save_path
	app.run_surface_factory = Callable(self, "_make_stub_run_surface")
	root.add_child(app)
	await process_frame
	return app

func _current_content(app: Node) -> Node:
	var slot := app.get_node("ContentSlot")
	if slot.get_child_count() == 0:
		return null
	return slot.get_child(0)

func _current_hub(app: Node) -> Node:
	return _current_content(app)

func _current_surface(app: Node) -> StubRunSurface:
	return _current_content(app) as StubRunSurface

func _flush_free_queue() -> void:
	await process_frame
	await process_frame

func _cleanup_app(app: Node, save_path: String) -> void:
	app.queue_free()
	await _flush_free_queue()
	_remove_save(save_path)

func _test_boots_into_hub_with_loaded_meta_state() -> void:
	var save_path := _new_save_path("boot")
	_remove_save(save_path)
	var seeded_meta: MetaState = MetaState.new()
	seeded_meta.scrap_banked = 19
	var seed_error := seeded_meta.save_to_path(save_path)
	_check_eq("seed meta save succeeds for boot test", seed_error, OK)

	var app := await _new_app(save_path)
	if app == null:
		return
	var hub := _current_hub(app)
	var scrap_label := hub.get_node("HubUi/Root/ScrapLabel") as Label

	_check("app scene root has AppShell script", app.get_script() == AppShellScript)
	_check("app scene has a ContentSlot node", app.get_node_or_null("ContentSlot") is Node)
	_check("app boots into the hub scene", hub.get_script() == HubControllerScript)
	_check("AppShell owns a loaded MetaState", app.meta_state is MetaState)
	_check_eq("loaded meta state uses save scrap", app.meta_state.scrap_banked, 19)
	_check("AppShell owns RunLifecycle", app.lifecycle is RunLifecycle)
	_check("RunLifecycle uses the same MetaState instance", app.lifecycle.meta_state == app.meta_state)
	_check_eq("RunLifecycle starts in HUB phase", app.lifecycle.phase, RunLifecycle.Phase.HUB)
	_check_eq("hub scrap label reflects loaded meta on boot", scrap_label.text, "SCRAP 19")

	await _cleanup_app(app, save_path)

func _test_hub_run_request_swaps_to_run_surface_with_bonuses() -> void:
	var save_path := _new_save_path("start_run")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	app.meta_state.stat_grades["dash_charges"] = 1
	app.meta_state.stat_grades["guard_max"] = 2
	app.meta_state.stat_grades["draft_rerolls"] = 1
	var hub := _current_hub(app)

	hub.run_requested.emit()
	await _flush_free_queue()
	var surface := _current_surface(app)

	_check("hub run_requested swaps to a run surface", surface is StubRunSurface)
	_check_eq("content slot has exactly one active child after run swap", app.get_node("ContentSlot").get_child_count(), 1)
	_check("old hub content is freed after run swap", not is_instance_valid(hub))
	_check_eq("lifecycle enters RUNNING phase", app.lifecycle.phase, RunLifecycle.Phase.RUNNING)
	_check_eq("lifecycle computes run bonuses from meta", app.lifecycle.run_bonuses["extra_dash_charges"], 1)
	_check_eq("run surface start_run is called once", surface.start_call_count, 1)
	_check_eq("run surface receives extra_dash_charges bonus", surface.received_bonuses["extra_dash_charges"], 1)
	_check_eq("run surface receives extra_guard bonus", surface.received_bonuses["extra_guard"], 2)
	_check_eq("run surface receives draft_rerolls bonus", surface.received_bonuses["draft_rerolls"], 1)

	await _cleanup_app(app, save_path)

func _test_running_phase_ignores_reentrant_run_request() -> void:
	var save_path := _new_save_path("reentrant")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	var hub := _current_hub(app)

	hub.run_requested.emit()
	var surface := _current_surface(app)
	app.lifecycle.add_run_currency(9, 0)
	hub.run_requested.emit()
	await _flush_free_queue()

	_check("reentrant run request keeps the active run surface", is_instance_valid(surface) and _current_content(app) == surface)
	if is_instance_valid(surface):
		_check_eq("reentrant run request does not restart the surface", surface.start_call_count, 1)
	_check_eq("reentrant run request does not reset live run scrap", app.lifecycle.run_scrap, 9)
	_check_eq("reentrant run request leaves lifecycle RUNNING", app.lifecycle.phase, RunLifecycle.Phase.RUNNING)

	await _cleanup_app(app, save_path)

func _test_malformed_run_surface_is_rejected_without_leaving_hub() -> void:
	var save_path := _new_save_path("missing_run_signals")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	app.run_surface_factory = Callable(self, "_make_missing_signal_surface")
	var hub := _current_hub(app)

	hub.run_requested.emit()
	await _flush_free_queue()

	_check("malformed run surface keeps the original hub active", is_instance_valid(hub) and _current_content(app) == hub)
	_check_eq("malformed run surface leaves lifecycle in HUB phase", app.lifecycle.phase, RunLifecycle.Phase.HUB)
	_check_eq("malformed run surface keeps one content child", app.get_node("ContentSlot").get_child_count(), 1)

	await _cleanup_app(app, save_path)

func _test_player_death_banks_saves_and_returns_to_hub() -> void:
	var save_path := _new_save_path("death")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	var hub := _current_hub(app)
	hub.run_requested.emit()
	await _flush_free_queue()
	var surface := _current_surface(app)
	app.lifecycle.add_run_currency(27, 0)

	surface.player_died.emit()
	await _flush_free_queue()
	var returned_hub := _current_hub(app)
	var scrap_label := returned_hub.get_node("HubUi/Root/ScrapLabel") as Label
	var loaded: MetaState = MetaState.load_from_path(save_path)

	_check("death frees the old run surface", not is_instance_valid(surface))
	_check("death swaps back to hub", returned_hub.get_script() == HubControllerScript)
	_check_eq("death returns lifecycle to HUB phase", app.lifecycle.phase, RunLifecycle.Phase.HUB)
	_check_eq("death banks run scrap into meta", app.meta_state.scrap_banked, 27)
	_check_eq("death resets run scrap", app.lifecycle.run_scrap, 0)
	_check_eq("returned hub scrap label reflects banked scrap", scrap_label.text, "SCRAP 27")
	_check_eq("death save persists banked scrap", loaded.scrap_banked, 27)
	_check_eq("death records non-victory outcome in save", _saved_victory_flag(save_path), false)
	_check_eq("death return save has bank and outcome in one file", _saved_return_snapshot(save_path), {
		"scrap_banked": 27,
		"last_return_was_victory": false,
	})

	await _cleanup_app(app, save_path)

func _test_new_run_dismisses_lingering_summary_overlay() -> void:
	var save_path := _new_save_path("overlay")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	_current_hub(app).run_requested.emit()
	await _flush_free_queue()
	_current_surface(app).player_died.emit()
	await _flush_free_queue()
	_check("death shows a run-summary overlay", is_instance_valid(app._summary_overlay))

	var overlay: Node = app._summary_overlay
	_current_hub(app).run_requested.emit()
	await _flush_free_queue()

	_check("starting a new run frees the lingering summary overlay", not is_instance_valid(overlay))
	_check("new run swaps to a run surface despite prior overlay", _current_surface(app) != null)

	await _cleanup_app(app, save_path)

func _test_victory_returns_to_hub_and_persists_outcome_flag() -> void:
	var save_path := _new_save_path("victory")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	_current_hub(app).run_requested.emit()
	await _flush_free_queue()
	var surface := _current_surface(app)
	app.lifecycle.add_run_currency(11, 0)

	surface.run_completed.emit()
	await _flush_free_queue()
	var returned_hub := _current_hub(app)
	var loaded: MetaState = MetaState.load_from_path(save_path)

	_check("victory frees the old run surface", not is_instance_valid(surface))
	_check("victory swaps back to hub", returned_hub.get_script() == HubControllerScript)
	_check_eq("victory returns lifecycle to HUB phase", app.lifecycle.phase, RunLifecycle.Phase.HUB)
	_check_eq("victory return persists banked scrap through the shared return path", loaded.scrap_banked, 11)
	_check_eq("AppShell records last return as victory", app.last_return_was_victory, true)
	_check_eq("victory flag is persisted beside the meta save", _saved_victory_flag(save_path), true)
	_check_eq("victory return save has bank and outcome in one file", _saved_return_snapshot(save_path), {
		"scrap_banked": 11,
		"last_return_was_victory": true,
	})

	await _cleanup_app(app, save_path)

func _test_double_death_same_frame_banks_once() -> void:
	var save_path := _new_save_path("double_death")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	_current_hub(app).run_requested.emit()
	await _flush_free_queue()
	var surface := _current_surface(app)
	app.lifecycle.add_run_currency(13, 0)

	surface.player_died.emit()
	surface.player_died.emit()
	await _flush_free_queue()
	var loaded: MetaState = MetaState.load_from_path(save_path)

	_check_eq("double death banks run scrap once", app.meta_state.scrap_banked, 13)
	_check_eq("double death save persists one bank", loaded.scrap_banked, 13)
	_check_eq("double death leaves lifecycle HUB", app.lifecycle.phase, RunLifecycle.Phase.HUB)
	_check_eq("double death records non-victory outcome", _saved_victory_flag(save_path), false)

	await _cleanup_app(app, save_path)

func _test_double_victory_same_frame_banks_once() -> void:
	var save_path := _new_save_path("double_victory")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	_current_hub(app).run_requested.emit()
	await _flush_free_queue()
	var surface := _current_surface(app)
	app.lifecycle.add_run_currency(17, 0)

	surface.run_completed.emit()
	surface.run_completed.emit()
	await _flush_free_queue()
	var loaded: MetaState = MetaState.load_from_path(save_path)

	_check_eq("double victory banks run scrap once", app.meta_state.scrap_banked, 17)
	_check_eq("double victory save persists one bank", loaded.scrap_banked, 17)
	_check_eq("double victory leaves lifecycle HUB", app.lifecycle.phase, RunLifecycle.Phase.HUB)
	_check_eq("double victory records victory outcome", _saved_victory_flag(save_path), true)

	await _cleanup_app(app, save_path)

func _test_meta_persists_across_app_restart() -> void:
	var save_path := _new_save_path("restart")
	_remove_save(save_path)
	var app := await _new_app(save_path)
	if app == null:
		return
	_current_hub(app).run_requested.emit()
	await _flush_free_queue()
	var surface := _current_surface(app)
	app.lifecycle.add_run_currency(34, 0)
	surface.player_died.emit()
	await _flush_free_queue()
	app.queue_free()
	await _flush_free_queue()

	var restarted_app := await _new_app(save_path)
	if restarted_app == null:
		return
	var restarted_hub := _current_hub(restarted_app)
	var scrap_label := restarted_hub.get_node("HubUi/Root/ScrapLabel") as Label

	_check_eq("new AppShell loads saved scrap after restart", restarted_app.meta_state.scrap_banked, 34)
	_check_eq("restarted hub label reflects persisted scrap", scrap_label.text, "SCRAP 34")
	_check_eq("restarted app begins back in HUB phase", restarted_app.lifecycle.phase, RunLifecycle.Phase.HUB)

	await _cleanup_app(restarted_app, save_path)

func _saved_victory_flag(path: String) -> bool:
	var cfg := ConfigFile.new()
	var load_error := cfg.load(path)
	if load_error != OK:
		return false
	return bool(cfg.get_value("run_history", "last_return_was_victory", false))

func _saved_return_snapshot(path: String) -> Dictionary:
	var cfg := ConfigFile.new()
	var load_error := cfg.load(path)
	if load_error != OK:
		return {}
	return {
		"scrap_banked": int(cfg.get_value("currency", "scrap_banked", -1)),
		"last_return_was_victory": bool(cfg.get_value("run_history", "last_return_was_victory", false)),
	}
