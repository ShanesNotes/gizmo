class_name TitleScreen
extends Control

const AppSceneDefault := preload("res://scenes/app.tscn")

@export var app_scene: PackedScene = AppSceneDefault

const INK_LEATHER := Color(0.1020, 0.0824, 0.0706, 0.92)
const INK_LEATHER_DARK := Color(0.0706, 0.0549, 0.0941, 0.96)
const BRASS := Color(0.6902, 0.5529, 0.3412, 1.0)
const BRASS_LIT := Color(0.8784, 0.7569, 0.4784, 1.0)
const PARCHMENT_LIGHT := Color(0.9922, 0.9373, 0.8706, 1.0)
const PARCHMENT_DIM := Color(0.7569, 0.6667, 0.5686, 1.0)

@onready var _start_button: Button = %StartButton
@onready var _replay_opening_button: Button = %ReplayOpeningButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_panel: Node = %SettingsPanel

var _start_pulse_tween: Tween = null

func _ready() -> void:
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"play_ui_context"):
		director.call(&"play_ui_context", &"main_menu")
	_apply_storybook_theme()
	_start_button.pressed.connect(_on_start_pressed)
	_replay_opening_button.pressed.connect(_on_replay_opening_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(quit_game)
	_start_button.grab_focus()
	_start_press_start_pulse()

func _exit_tree() -> void:
	if _start_pulse_tween != null and _start_pulse_tween.is_valid():
		_start_pulse_tween.kill()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	quit_game()
	get_viewport().set_input_as_handled()

func start_game() -> Error:
	if app_scene == null:
		push_error("TitleScreen requires an app_scene.")
		return ERR_CANT_CREATE
	return get_tree().change_scene_to_packed(app_scene)

func quit_game() -> void:
	get_tree().quit()

func _on_start_pressed() -> void:
	start_game()

func _on_replay_opening_pressed() -> void:
	OpeningSequence.replay_requested = true
	start_game()

func _on_settings_pressed() -> void:
	if _settings_panel != null and _settings_panel.has_method(&"open"):
		_settings_panel.call(&"open")

func _apply_storybook_theme() -> void:
	var buttons: Array[Button] = [
		_start_button,
		_replay_opening_button,
		_settings_button,
		_quit_button,
	]
	for button in buttons:
		_apply_storybook_button(button)

	var wordmark := get_node_or_null("Center/Menu/WordmarkLabel") as Label
	if wordmark != null:
		wordmark.add_theme_color_override(&"font_color", BRASS_LIT)
		wordmark.add_theme_color_override(&"font_shadow_color", Color(0.0, 0.0, 0.0, 0.78))
		wordmark.add_theme_constant_override(&"shadow_offset_x", 2)
		wordmark.add_theme_constant_override(&"shadow_offset_y", 3)
		wordmark.add_theme_font_size_override(&"font_size", 104)

	var subtitle := get_node_or_null("Center/Menu/SubtitleLabel") as Label
	if subtitle != null:
		subtitle.add_theme_color_override(&"font_color", PARCHMENT_DIM)
		subtitle.add_theme_font_size_override(&"font_size", 24)

func _apply_storybook_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 260.0), 48.0)
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

func _start_press_start_pulse() -> void:
	if _start_pulse_tween != null and _start_pulse_tween.is_valid():
		_start_pulse_tween.kill()
	if not is_inside_tree() or _start_button == null:
		return
	_start_button.modulate.a = 1.0
	_start_pulse_tween = create_tween().set_loops()
	_start_pulse_tween.tween_property(_start_button, "modulate:a", 0.72, 1.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_start_pulse_tween.tween_property(_start_button, "modulate:a", 1.0, 1.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
