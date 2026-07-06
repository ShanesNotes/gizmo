class_name AppShell
extends Node

const HubSceneDefault := preload("res://scenes/hub.tscn")
const RunSceneDefault := preload("res://scenes/run.tscn")
const EndScreenSceneDefault := preload("res://scenes/end_screen.tscn")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RunLifecycle := preload("res://scripts/meta/run_lifecycle.gd")

const MUSIC_STATE_HUB: StringName = &"HUB"
const MUSIC_STATE_COMBAT: StringName = &"COMBAT"

const START_RUN_METHODS: Array[StringName] = [
	&"start_new_run",
	&"begin_run",
	&"start_run",
]
const RUN_SURFACE_LOAD_FAILURE_COPY := "Run surface failed to load - run the import step (see docs/hades-pivot/export.md)."

class PlaceholderRunSurface:
	extends Node

	signal player_died()
	signal run_completed()

	var received_bonuses: Dictionary = {}

	func start_run(run_bonuses: Dictionary) -> void:
		received_bonuses = run_bonuses.duplicate(true)

@export var meta_save_path: String = MetaState.DEFAULT_SAVE_PATH
@export var hub_scene: PackedScene = HubSceneDefault
@export var run_surface_scene: PackedScene = RunSceneDefault
@export var end_screen_scene: PackedScene = EndScreenSceneDefault
@export var entry_room_id: String = "room_00"

var run_surface_factory: Callable = Callable()
var meta_state: MetaState
var lifecycle: RunLifecycle
var last_return_was_victory := false
var last_run_summary: Dictionary = {}
var audio_director: Node = null

var _summary_overlay: EndScreen = null

@onready var content_slot: Node = get_node_or_null("ContentSlot")

func _ready() -> void:
	_ensure_content_slot()
	_resolve_audio_director()
	_load_meta_state()
	lifecycle = RunLifecycle.new(meta_state)
	_show_hub()

func _load_meta_state() -> void:
	var loaded: Resource = MetaState.load_from_path(meta_save_path)
	meta_state = loaded if loaded is MetaState else MetaState.new()
	last_return_was_victory = meta_state.last_return_was_victory

func _show_hub() -> void:
	if hub_scene == null:
		push_error("AppShell requires a hub_scene.")
		return

	var hub: Node = hub_scene.instantiate()
	_inject_meta_state(hub)
	_connect_hub(hub)
	_swap_content(hub)
	_set_audio_zone_state(MUSIC_STATE_HUB)

func _on_hub_run_requested() -> void:
	if _defer_from_physics_frame(&"_on_hub_run_requested"):
		return
	if lifecycle == null:
		push_error("AppShell cannot start a run without RunLifecycle.")
		return
	if lifecycle.phase != RunLifecycle.Phase.HUB:
		push_error("AppShell ignored run_requested outside HUB phase.")
		return
	# Defensive: a lingering end-screen overlay must not stack over live gameplay.
	_dismiss_run_summary()

	var hub := _active_content()
	var run_surface: Node = _instantiate_run_surface()
	if run_surface == null:
		push_error("AppShell could not create a run surface.")
		return
	_configure_run_surface_for_shell(run_surface)
	if not _connect_run_surface(run_surface):
		run_surface.free()
		_show_run_surface_load_failure(hub)
		return
	_clear_run_surface_load_failure(hub)

	lifecycle.start_new_run(entry_room_id)
	_swap_content(run_surface)
	_set_audio_zone_state(MUSIC_STATE_COMBAT)
	_call_start_run_entry(run_surface, lifecycle.run_bonuses)

func _instantiate_run_surface() -> Node:
	if run_surface_factory.is_valid():
		var factory_result: Variant = run_surface_factory.call()
		if factory_result is Node:
			return factory_result
		push_error("AppShell run_surface_factory must return a Node.")
		return null

	if run_surface_scene != null:
		return run_surface_scene.instantiate()

	var placeholder: Node = PlaceholderRunSurface.new()
	placeholder.name = "RunSurface"
	return placeholder

func _connect_hub(hub: Node) -> void:
	if not hub.has_signal(&"run_requested"):
		push_error("AppShell hub content must expose run_requested.")
		return

	var callback := Callable(self, "_on_hub_run_requested")
	if not hub.is_connected(&"run_requested", callback):
		hub.connect(&"run_requested", callback)

func _connect_run_surface(run_surface: Node) -> bool:
	var valid := true
	if not run_surface.has_signal(&"player_died"):
		push_error("AppShell run surface must expose player_died.")
		valid = false

	if not run_surface.has_signal(&"run_completed"):
		push_error("AppShell run surface must expose run_completed.")
		valid = false
	if not valid:
		return false

	var death_callback := Callable(self, "_on_run_surface_player_died")
	if not run_surface.is_connected(&"player_died", death_callback):
		run_surface.connect(&"player_died", death_callback)

	var completion_callback := Callable(self, "_on_run_surface_run_completed")
	if not run_surface.is_connected(&"run_completed", completion_callback):
		run_surface.connect(&"run_completed", completion_callback)
	return true

func _on_run_surface_player_died(_payload: Variant = null) -> void:
	if _defer_from_physics_frame(&"_on_run_surface_player_died", [_payload]):
		return
	_return_to_hub(false)

func _on_run_surface_run_completed(_payload: Variant = null) -> void:
	if _defer_from_physics_frame(&"_on_run_surface_run_completed", [_payload]):
		return
	_return_to_hub(true)

func _return_to_hub(victory: bool) -> void:
	if lifecycle == null:
		return
	if lifecycle.phase != RunLifecycle.Phase.RUNNING:
		return

	var run_surface := _active_content()
	var summary := _run_summary_from_surface(run_surface, victory)
	var earned_scrap := maxi(0, int(summary.get("scrap_banked", summary.get("scrap_earned", 0))))
	var earned_sparks := maxi(0, int(summary.get("sparks_banked", summary.get("sparks_earned", 0))))
	if earned_scrap > 0 or earned_sparks > 0:
		lifecycle.add_run_currency(earned_scrap, earned_sparks)

	var banked_scrap := lifecycle.run_scrap
	var banked_sparks := lifecycle.run_sparks
	last_return_was_victory = victory
	meta_state.last_return_was_victory = victory

	var save_error: Error = lifecycle.handle_player_death(meta_save_path)
	if save_error != OK:
		push_error("AppShell could not save meta state on hub return: %s" % save_error)

	_show_hub()
	summary["victory"] = victory
	summary["scrap_banked"] = banked_scrap
	summary["sparks_banked"] = banked_sparks
	summary["survived_seconds"] = maxf(
		0.0,
		float(summary.get("survived_seconds", summary.get("elapsed", 0.0)))
	)
	last_run_summary = summary.duplicate(true)
	_show_run_summary_overlay(summary)

func _inject_meta_state(content: Node) -> void:
	if _object_has_property(content, "meta_state"):
		content.set("meta_state", meta_state)

func _call_start_run_entry(run_surface: Node, run_bonuses: Dictionary) -> bool:
	for method_name in START_RUN_METHODS:
		if run_surface.has_method(method_name):
			if _method_argument_count(run_surface, method_name) <= 0:
				run_surface.call(method_name)
			else:
				run_surface.call(method_name, run_bonuses)
			return true

	push_error("AppShell run surface must expose a start_run-style entry method.")
	return false

func _configure_run_surface_for_shell(run_surface: Node) -> void:
	if _object_has_property(run_surface, "auto_start"):
		run_surface.set("auto_start", false)

func _run_summary_from_surface(run_surface: Node, victory: bool) -> Dictionary:
	var summary := {
		"victory": victory,
		"rooms_cleared": 0,
		"boons_taken": 0,
		"scrap_banked": 0,
		"sparks_banked": 0,
		"survived_seconds": 0.0,
	}
	if run_surface == null or not run_surface.has_method(&"run_summary"):
		return summary

	var raw_summary: Variant
	if _method_argument_count(run_surface, &"run_summary") <= 0:
		raw_summary = run_surface.call(&"run_summary")
	else:
		raw_summary = run_surface.call(&"run_summary", victory)
	if raw_summary is Dictionary:
		summary.merge(raw_summary as Dictionary, true)
	summary["victory"] = victory
	return summary

func _show_run_summary_overlay(summary: Dictionary) -> void:
	if end_screen_scene == null:
		return
	if _summary_overlay != null and is_instance_valid(_summary_overlay):
		_summary_overlay.queue_free()

	var screen := end_screen_scene.instantiate() as EndScreen
	if screen == null:
		push_error("AppShell end_screen_scene must instantiate EndScreen.")
		return
	_summary_overlay = screen
	add_child(screen)
	_wire_summary_dismiss(screen)
	screen.show_run_summary(summary)

func _wire_summary_dismiss(screen: EndScreen) -> void:
	var retry_button := screen.get_node_or_null("Root/Center/Panel/Margin/VBox/RetryButton") as Button
	if retry_button == null:
		return

	var reload_callback := Callable(screen, "_on_retry_pressed")
	if retry_button.is_connected(&"pressed", reload_callback):
		retry_button.disconnect(&"pressed", reload_callback)

	var dismiss_callback := Callable(self, "_dismiss_run_summary")
	if not retry_button.is_connected(&"pressed", dismiss_callback):
		retry_button.connect(&"pressed", dismiss_callback)

func _dismiss_run_summary() -> void:
	if _summary_overlay != null and is_instance_valid(_summary_overlay):
		_summary_overlay.queue_free()
	_summary_overlay = null

func _show_run_surface_load_failure(hub: Node) -> void:
	if hub != null and hub.has_method(&"show_run_surface_load_failure"):
		hub.call(&"show_run_surface_load_failure", RUN_SURFACE_LOAD_FAILURE_COPY)

func _clear_run_surface_load_failure(hub: Node) -> void:
	if hub != null and hub.has_method(&"clear_run_surface_load_failure"):
		hub.call(&"clear_run_surface_load_failure")

func _swap_content(next_content: Node) -> void:
	_ensure_content_slot()
	for child in content_slot.get_children():
		content_slot.remove_child(child)
		child.queue_free()
	content_slot.add_child(next_content)

func _defer_from_physics_frame(method_name: StringName, args: Array = []) -> bool:
	if not Engine.is_in_physics_frame():
		return false
	call_deferred(&"_call_after_process_frame", method_name, args)
	return true

func _call_after_process_frame(method_name: StringName, args: Array) -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	callv(method_name, args)

func _ensure_content_slot() -> void:
	if content_slot != null:
		return
	content_slot = Node.new()
	content_slot.name = "ContentSlot"
	add_child(content_slot)

func _resolve_audio_director() -> void:
	if audio_director != null:
		return
	audio_director = get_node_or_null("/root/AudioDirector")

func _set_audio_zone_state(state: StringName) -> void:
	if audio_director == null or not is_instance_valid(audio_director):
		return
	if audio_director.has_method(&"set_zone_state"):
		audio_director.call(&"set_zone_state", state)
	elif audio_director.has_method(&"set_music_state"):
		audio_director.call(&"set_music_state", state)

func _active_content() -> Node:
	_ensure_content_slot()
	if content_slot.get_child_count() == 0:
		return null
	return content_slot.get_child(0)

func _object_has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func _method_argument_count(object: Object, method_name: StringName) -> int:
	for method in object.get_method_list():
		if String(method.get("name", "")) == String(method_name):
			return (method.get("args", []) as Array).size()
	return 1
