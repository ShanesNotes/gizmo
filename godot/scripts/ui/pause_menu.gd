class_name PauseMenu
extends CanvasLayer

@export var run_surface_group: StringName = &"run_surface"
@export var blocking_overlay_group: StringName = &"blocking_overlay"

const INK_LEATHER := Color(0.1020, 0.0824, 0.0706, 0.92)
const INK_LEATHER_DARK := Color(0.0706, 0.0549, 0.0941, 0.96)
const DIM_VIOLET := Color(0.0706, 0.0549, 0.0941, 0.55)
const BRASS := Color(0.6902, 0.5529, 0.3412, 1.0)
const BRASS_LIT := Color(0.8784, 0.7569, 0.4784, 1.0)
const PARCHMENT_LIGHT := Color(0.9922, 0.9373, 0.8706, 1.0)
const PARCHMENT_DIM := Color(0.7569, 0.6667, 0.5686, 1.0)

@onready var _root: Control = %Root
@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _how_to_keep_button: Button = %HowToKeepButton
@onready var _abandon_button: Button = %AbandonButton
@onready var _settings_panel: Node = %SettingsPanel
@onready var _controls_card: Node = %ControlsCard

var _owns_pause := false
var _last_overlay_visible := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_apply_storybook_theme()
	_resume_button.pressed.connect(_on_resume_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_how_to_keep_button.pressed.connect(_on_how_to_keep_pressed)
	_abandon_button.pressed.connect(_on_abandon_pressed)
	if _controls_card != null and _controls_card.has_method(&"close"):
		_controls_card.call(&"close")
	_sync_overlay_visibility()

func _process(_delta: float) -> void:
	if _owns_pause and get_tree().paused and _find_live_run_surface() == null:
		resume()
	else:
		_sync_overlay_visibility()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return

	var settings_open := (
		_settings_panel != null
		and _settings_panel.has_method(&"is_open")
		and bool(_settings_panel.call(&"is_open"))
	)
	if get_tree().paused and settings_open:
		_settings_panel.call(&"close")
		get_viewport().set_input_as_handled()
		return

	var controls_open := (
		_controls_card != null
		and _controls_card.has_method(&"is_open")
		and bool(_controls_card.call(&"is_open"))
	)
	if get_tree().paused and controls_open:
		_controls_card.call(&"close")
		get_viewport().set_input_as_handled()
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
	if _settings_panel != null and _settings_panel.has_method(&"close"):
		_settings_panel.call(&"close")
	if _controls_card != null and _controls_card.has_method(&"close"):
		_controls_card.call(&"close")
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
	if not should_show and _settings_panel != null and _settings_panel.has_method(&"close"):
		_settings_panel.call(&"close")
	if not should_show and _controls_card != null and _controls_card.has_method(&"close"):
		_controls_card.call(&"close")
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

func _on_settings_pressed() -> void:
	if _settings_panel != null and _settings_panel.has_method(&"open"):
		_settings_panel.call(&"open")

func _on_how_to_keep_pressed() -> void:
	if _controls_card != null and _controls_card.has_method(&"open"):
		_controls_card.call(&"open")

func _on_abandon_pressed() -> void:
	var run_surface := _find_live_run_surface()
	resume()
	if run_surface == null:
		return
	if run_surface.has_signal(&"player_died"):
		run_surface.emit_signal(&"player_died")

func _apply_storybook_theme() -> void:
	var dim := get_node_or_null("Root/Dim") as ColorRect
	if dim != null:
		dim.color = DIM_VIOLET

	var panel := get_node_or_null("Root/Center/Panel") as PanelContainer
	if panel != null:
		panel.add_theme_stylebox_override(&"panel", _panel_style())

	var title := get_node_or_null("Root/Center/Panel/Margin/VBox/TitleLabel") as Label
	if title != null:
		title.add_theme_color_override(&"font_color", BRASS_LIT)
		title.add_theme_font_size_override(&"font_size", 48)

	var flavor := get_node_or_null("Root/Center/Panel/Margin/VBox/FlavorLabel") as Label
	if flavor != null:
		flavor.add_theme_color_override(&"font_color", PARCHMENT_DIM)
		flavor.add_theme_font_size_override(&"font_size", 18)

	var buttons: Array[Button] = [
		_resume_button,
		_settings_button,
		_how_to_keep_button,
		_abandon_button,
	]
	for button in buttons:
		_apply_storybook_button(button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = INK_LEATHER
	style.border_color = BRASS
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 12
	return style

func _apply_storybook_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 230.0), 48.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override(&"font_size", 20)
	button.add_theme_color_override(&"font_color", PARCHMENT_LIGHT)
	button.add_theme_color_override(&"font_hover_color", BRASS_LIT)
	button.add_theme_color_override(&"font_focus_color", BRASS_LIT)
	button.add_theme_color_override(&"font_pressed_color", PARCHMENT_LIGHT)
	button.add_theme_stylebox_override(&"normal", _button_style(INK_LEATHER, BRASS, 2, 10))
	button.add_theme_stylebox_override(&"hover", _button_style(Color(0.145, 0.112, 0.082, 0.96), BRASS_LIT, 2, 10))
	button.add_theme_stylebox_override(&"pressed", _button_style(INK_LEATHER_DARK, BRASS, 2, 10))
	button.add_theme_stylebox_override(&"focus", _button_style(Color(0.8784, 0.7569, 0.4784, 0.22), BRASS_LIT, 3, 10))

func _button_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 22.0
	style.content_margin_top = 10.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 10.0
	return style
