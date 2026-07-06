class_name PauseMenu
extends CanvasLayer

@export var run_surface_group: StringName = &"run_surface"
@export var blocking_overlay_group: StringName = &"blocking_overlay"

@onready var _root: Control = %Root
@onready var _resume_button: Button = %ResumeButton
@onready var _abandon_button: Button = %AbandonButton

var _owns_pause := false
var _last_overlay_visible := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_abandon_button.pressed.connect(_on_abandon_pressed)
	_sync_overlay_visibility()

func _process(_delta: float) -> void:
	if _owns_pause and get_tree().paused and _find_live_run_surface() == null:
		resume()
	else:
		_sync_overlay_visibility()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return

	if get_tree().paused:
		resume()
		get_viewport().set_input_as_handled()
		return

	if request_pause():
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if _owns_pause and get_tree() != null and get_tree().paused:
		get_tree().paused = false

func request_pause() -> bool:
	if get_tree().paused:
		_sync_overlay_visibility()
		return true
	if _find_live_run_surface() == null:
		return false

	get_tree().paused = true
	_owns_pause = true
	_sync_overlay_visibility()
	return true

func resume() -> void:
	if get_tree().paused:
		get_tree().paused = false
	_owns_pause = false
	_sync_overlay_visibility()

func is_overlay_visible() -> bool:
	return _root != null and _root.visible

func _sync_overlay_visibility() -> void:
	if _root == null:
		return

	var should_show := get_tree().paused and _find_live_run_surface() != null
	_root.visible = should_show
	if should_show and not _last_overlay_visible:
		_resume_button.grab_focus()
	_last_overlay_visible = should_show

func _find_live_run_surface() -> Node:
	var cursor := get_parent()
	while cursor != null and cursor != get_tree().root:
		if _is_run_surface_candidate(cursor):
			if _is_run_surface_live(cursor):
				return cursor
			return null
		cursor = cursor.get_parent()
	return null

func _is_run_surface_candidate(node: Node) -> bool:
	if node.is_in_group(run_surface_group):
		return true
	return node.has_signal(&"player_died") and node.has_signal(&"run_completed") and node.has_method(&"run_summary")

func _is_run_surface_live(node: Node) -> bool:
	if _has_blocking_overlay():
		return false

	var active_state: Variant = _get_bool_property(node, [&"_run_active", &"run_active"])
	if active_state is bool:
		return active_state
	return true

func _get_bool_property(node: Node, property_names: Array[StringName]) -> Variant:
	for property in node.get_property_list():
		var property_name := StringName(str(property.get("name", "")))
		if property_names.has(property_name):
			return node.get(property_name)
	return null

func _has_blocking_overlay() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	for overlay in tree.get_nodes_in_group(blocking_overlay_group):
		if overlay == self:
			continue
		if overlay is Node and (overlay as Node).is_inside_tree():
			return true
	return false

func _on_resume_pressed() -> void:
	resume()

func _on_abandon_pressed() -> void:
	var run_surface := _find_live_run_surface()
	resume()
	if run_surface == null:
		return
	if run_surface.has_signal(&"player_died"):
		run_surface.emit_signal(&"player_died")
