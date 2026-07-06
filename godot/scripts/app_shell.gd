class_name AppShell
extends Node

const HubSceneDefault := preload("res://scenes/hub.tscn")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RunLifecycle := preload("res://scripts/meta/run_lifecycle.gd")

const START_RUN_METHODS: Array[StringName] = [
	&"start_run",
	&"start_new_run",
	&"begin_run",
]

class PlaceholderRunSurface:
	extends Node

	signal player_died()
	signal run_completed()

	var received_bonuses: Dictionary = {}

	func start_run(run_bonuses: Dictionary) -> void:
		received_bonuses = run_bonuses.duplicate(true)

@export var meta_save_path: String = MetaState.DEFAULT_SAVE_PATH
@export var hub_scene: PackedScene = HubSceneDefault
@export var run_surface_scene: PackedScene
@export var entry_room_id: String = "room_00"

var run_surface_factory: Callable = Callable()
var meta_state: MetaState
var lifecycle: RunLifecycle
var last_return_was_victory := false

@onready var content_slot: Node = get_node_or_null("ContentSlot")

func _ready() -> void:
	_ensure_content_slot()
	_load_meta_state()
	lifecycle = RunLifecycle.new(meta_state)
	_show_hub()

func _load_meta_state() -> void:
	var loaded: Resource = MetaState.load_from_path(meta_save_path)
	meta_state = loaded if loaded is MetaState else MetaState.new()
	last_return_was_victory = _load_saved_victory_flag()

func _show_hub() -> void:
	if hub_scene == null:
		push_error("AppShell requires a hub_scene.")
		return

	var hub: Node = hub_scene.instantiate()
	_inject_meta_state(hub)
	_connect_hub(hub)
	_swap_content(hub)

func _on_hub_run_requested() -> void:
	if lifecycle == null:
		push_error("AppShell cannot start a run without RunLifecycle.")
		return

	lifecycle.start_new_run(entry_room_id)
	var run_surface: Node = _instantiate_run_surface()
	if run_surface == null:
		push_error("AppShell could not create a run surface.")
		return

	_connect_run_surface(run_surface)
	_swap_content(run_surface)
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

func _connect_run_surface(run_surface: Node) -> void:
	if not run_surface.has_signal(&"player_died"):
		push_error("AppShell run surface must expose player_died.")
	else:
		run_surface.connect(&"player_died", Callable(self, "_on_run_surface_player_died"))

	if not run_surface.has_signal(&"run_completed"):
		push_error("AppShell run surface must expose run_completed.")
	else:
		run_surface.connect(&"run_completed", Callable(self, "_on_run_surface_run_completed"))

func _on_run_surface_player_died(_payload: Variant = null) -> void:
	_return_to_hub(false)

func _on_run_surface_run_completed(_payload: Variant = null) -> void:
	_return_to_hub(true)

func _return_to_hub(victory: bool) -> void:
	if lifecycle == null:
		return
	if lifecycle.phase != RunLifecycle.Phase.RUNNING:
		return

	last_return_was_victory = victory
	lifecycle.set_meta(&"last_return_was_victory", victory)

	var save_error: Error = lifecycle.handle_player_death(meta_save_path)
	if save_error != OK:
		push_error("AppShell could not save meta state on hub return: %s" % save_error)

	var outcome_error: Error = _save_victory_flag(victory)
	if outcome_error != OK:
		push_error("AppShell could not persist run outcome: %s" % outcome_error)

	_show_hub()

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

func _swap_content(next_content: Node) -> void:
	_ensure_content_slot()
	for child in content_slot.get_children():
		content_slot.remove_child(child)
		child.queue_free()
	content_slot.add_child(next_content)

func _ensure_content_slot() -> void:
	if content_slot != null:
		return
	content_slot = Node.new()
	content_slot.name = "ContentSlot"
	add_child(content_slot)

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

func _load_saved_victory_flag() -> bool:
	var config := ConfigFile.new()
	if config.load(meta_save_path) != OK:
		return false
	return bool(config.get_value("run_history", "last_return_was_victory", false))

func _save_victory_flag(victory: bool) -> Error:
	if meta_save_path == "":
		return OK

	var config := ConfigFile.new()
	var load_error := config.load(meta_save_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error

	config.set_value("run_history", "last_return_was_victory", victory)
	return config.save(meta_save_path)
