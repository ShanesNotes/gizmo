class_name ControlsCard
extends PanelContainer

## The brass keeping-plate: every control on one card. Shown at the end of the
## campfire opening and from the pause menu's HOW TO KEEP entry.

const TITLE := "HOW TO KEEP"
const CONTROL_ROWS: Array[Array] = [
	["WASD", "Move"],
	["LEFT CLICK", "Swing"],
	["RIGHT CLICK", "Special"],
	["Q", "Cast"],
	["SPACE", "Dash"],
	["F", "Surge"],
	["ESC", "Pause"],
]

const PARCHMENT := Color(0.9804, 0.8980, 0.8000, 1.0)
const INK_TEXT := Color(0.2078, 0.1725, 0.1686, 1.0)
const BRASS := Color(0.6902, 0.5529, 0.3412, 1.0)
const BRASS_LIT := Color(0.8784, 0.7569, 0.4784, 1.0)
const KEY_COLOR := Color(0.2078, 0.1725, 0.1686, 1.0)
const ACTION_COLOR := Color(0.4941, 0.1059, 0.0863, 1.0)

@onready var _grid: GridContainer = %ControlsGrid
@onready var _title_label: Label = %CardTitleLabel

func _ready() -> void:
	_apply_storybook_theme()
	_title_label.text = TITLE
	_build_rows()

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func is_open() -> bool:
	return visible

func _build_rows() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for row in CONTROL_ROWS:
		var fallback_key := String(row[0])
		var action_text := String(row[1])
		_grid.add_child(_make_label(action_text, ACTION_COLOR, HORIZONTAL_ALIGNMENT_LEFT))
		_grid.add_child(_make_label(_binding_label_for(action_text, fallback_key), KEY_COLOR, HORIZONTAL_ALIGNMENT_RIGHT))

func _make_label(text: String, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", 20 if alignment == HORIZONTAL_ALIGNMENT_LEFT else 18)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _apply_storybook_theme() -> void:
	add_theme_stylebox_override(&"panel", _card_style())
	custom_minimum_size = Vector2(maxf(custom_minimum_size.x, 430.0), custom_minimum_size.y)
	_title_label.add_theme_color_override(&"font_color", INK_TEXT)
	_title_label.add_theme_font_size_override(&"font_size", 30)
	_grid.add_theme_constant_override(&"h_separation", 28)
	_grid.add_theme_constant_override(&"v_separation", 10)

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PARCHMENT
	style.border_color = BRASS
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.40)
	style.shadow_size = 10
	return style

func _binding_label_for(action_text: String, fallback_key: String) -> String:
	if action_text == "Move":
		return _join_controller_keyboard(_move_controller_label(), _move_keyboard_label(fallback_key), fallback_key)

	var actions := _input_actions_for(action_text)
	var keyboard := _keyboard_label_for_actions(actions)
	var controller := _controller_label_for_actions(actions)
	return _join_controller_keyboard(controller, keyboard, fallback_key)

func _input_actions_for(action_text: String) -> Array[StringName]:
	match action_text:
		"Swing":
			return [&"gizmo_attack"]
		"Special":
			return [&"gizmo_special"]
		"Cast":
			return [&"gizmo_cast"]
		"Dash":
			return [&"gizmo_dash"]
		"Surge":
			return [&"gizmo_surge"]
		"Pause":
			return [&"ui_cancel"]
		_:
			return []

func _move_keyboard_label(fallback_key: String) -> String:
	var keys: Array[String] = []
	for action in [&"gizmo_move_up", &"gizmo_move_left", &"gizmo_move_down", &"gizmo_move_right"]:
		_append_keyboard_events(keys, action)
	if _has_all(keys, ["W", "A", "S", "D"]):
		return "WASD"
	if keys.is_empty():
		for action in [&"move_up", &"move_left", &"move_down", &"move_right"]:
			_append_keyboard_events(keys, action)
	if keys.is_empty():
		return fallback_key
	return " / ".join(keys)

func _move_controller_label() -> String:
	var values: Array[String] = []
	var has_left_stick := false
	var has_dpad := false
	for action in [
		&"gizmo_move_up",
		&"gizmo_move_left",
		&"gizmo_move_down",
		&"gizmo_move_right",
		&"move_up",
		&"move_left",
		&"move_down",
		&"move_right",
	]:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				var motion := event as InputEventJoypadMotion
				if int(motion.axis) == 0 or int(motion.axis) == 1:
					has_left_stick = true
				else:
					_append_unique(values, _joy_motion_text(motion))
			elif event is InputEventJoypadButton:
				var button := event as InputEventJoypadButton
				if int(button.button_index) >= 11 and int(button.button_index) <= 14:
					has_dpad = true
				else:
					_append_unique(values, _joy_button_text(button))
	if has_left_stick:
		values.push_front("Left Stick")
	if has_dpad:
		_append_unique(values, "D-Pad")
	return " / ".join(values)

func _keyboard_label_for_actions(actions: Array[StringName]) -> String:
	var values: Array[String] = []
	for action in actions:
		_append_keyboard_events(values, action)
	return " / ".join(values)

func _controller_label_for_actions(actions: Array[StringName]) -> String:
	var values: Array[String] = []
	for action in actions:
		_append_controller_events(values, action)
	return " / ".join(values)

func _append_keyboard_events(values: Array[String], action: StringName) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			_append_unique(values, _key_text(event as InputEventKey))
		elif event is InputEventMouseButton:
			_append_unique(values, _mouse_text(event as InputEventMouseButton))

func _append_controller_events(values: Array[String], action: StringName) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			_append_unique(values, _joy_button_text(event as InputEventJoypadButton))
		elif event is InputEventJoypadMotion:
			_append_unique(values, _joy_motion_text(event as InputEventJoypadMotion))

func _key_text(event: InputEventKey) -> String:
	var code := event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if code == 0:
		return ""
	var text := OS.get_keycode_string(code)
	match text:
		"Space":
			return "Space"
		"Escape":
			return "Esc"
		_:
			return text.to_upper() if text.length() == 1 else text

func _mouse_text(event: InputEventMouseButton) -> String:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			return "Left Click"
		MOUSE_BUTTON_RIGHT:
			return "Right Click"
		MOUSE_BUTTON_MIDDLE:
			return "Middle Click"
		_:
			return "Mouse %d" % int(event.button_index)

func _joy_button_text(event: InputEventJoypadButton) -> String:
	match int(event.button_index):
		0:
			return "A"
		1:
			return "B"
		2:
			return "X"
		3:
			return "Y"
		4:
			return "LB"
		5:
			return "RB"
		6:
			return "LT"
		7:
			return "RT"
		11:
			return "D-Pad Up"
		12:
			return "D-Pad Down"
		13:
			return "D-Pad Left"
		14:
			return "D-Pad Right"
		_:
			return "Pad %d" % int(event.button_index)

func _joy_motion_text(event: InputEventJoypadMotion) -> String:
	match int(event.axis):
		0, 1:
			return "Left Stick"
		2, 3:
			return "Right Stick"
		4:
			return "LT"
		5:
			return "RT"
		_:
			return "Stick %d" % int(event.axis)

func _join_controller_keyboard(controller: String, keyboard: String, fallback_key: String) -> String:
	if not controller.is_empty() and not keyboard.is_empty():
		return "%s / %s" % [controller, keyboard]
	if not keyboard.is_empty():
		return keyboard
	if not controller.is_empty():
		return controller
	return fallback_key

func _append_unique(values: Array[String], value: String) -> void:
	if value.is_empty() or values.has(value):
		return
	values.append(value)

func _has_all(values: Array[String], required: Array[String]) -> bool:
	for value in required:
		if not values.has(value):
			return false
	return true
