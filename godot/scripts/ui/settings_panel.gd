class_name SettingsPanel
extends CanvasLayer

const AUDIO_SETTINGS_SECTION := "audio"
const DISPLAY_SETTINGS_SECTION := "display"
const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
const SILENCE_DB := -80.0
const MIN_AUDIBLE_LINEAR := 0.0001
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC := true
const INK_LEATHER := Color(0.1020, 0.0824, 0.0706, 0.92)
const INK_LEATHER_DARK := Color(0.0706, 0.0549, 0.0941, 0.96)
const DIM_VIOLET := Color(0.0706, 0.0549, 0.0941, 0.62)
const BRASS := Color(0.6902, 0.5529, 0.3412, 1.0)
const BRASS_LIT := Color(0.8784, 0.7569, 0.4784, 1.0)
const PARCHMENT_LIGHT := Color(0.9922, 0.9373, 0.8706, 1.0)
const PARCHMENT_DIM := Color(0.7569, 0.6667, 0.5686, 1.0)

@export var settings_path := DEFAULT_SETTINGS_PATH

@onready var _root: Control = %Root
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var _vsync_toggle: CheckButton = %VSyncToggle
@onready var _done_button: Button = %DoneButton

var _loading := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_apply_storybook_theme()
	_master_slider.value_changed.connect(_on_slider_value_changed.bind(&"Master"))
	_music_slider.value_changed.connect(_on_slider_value_changed.bind(&"Music"))
	_sfx_slider.value_changed.connect(_on_slider_value_changed.bind(&"SFX"))
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_vsync_toggle.toggled.connect(_on_vsync_toggled)
	_done_button.pressed.connect(close)
	load_settings()

func open() -> void:
	_root.visible = true
	_done_button.grab_focus()

func close() -> void:
	_root.visible = false

func is_open() -> bool:
	return _root != null and _root.visible

func load_settings() -> Error:
	var cfg := ConfigFile.new()
	var load_error := cfg.load(settings_path)
	_loading = true
	_load_slider_from_config(cfg, load_error, &"Master", "master", _master_slider)
	_load_slider_from_config(cfg, load_error, &"Music", "music", _music_slider)
	_load_slider_from_config(cfg, load_error, &"SFX", "sfx", _sfx_slider)
	_load_display_from_config(cfg, load_error)
	_loading = false
	return OK if load_error == OK or load_error == ERR_FILE_NOT_FOUND else load_error

func save_settings() -> Error:
	var cfg := ConfigFile.new()
	var load_error := cfg.load(settings_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		push_warning("SettingsPanel could not load existing settings before save: %s" % load_error)
	cfg.set_value(AUDIO_SETTINGS_SECTION, "master", _master_slider.value)
	cfg.set_value(AUDIO_SETTINGS_SECTION, "music", _music_slider.value)
	cfg.set_value(AUDIO_SETTINGS_SECTION, "sfx", _sfx_slider.value)
	cfg.set_value(DISPLAY_SETTINGS_SECTION, "fullscreen", _fullscreen_toggle.button_pressed)
	cfg.set_value(DISPLAY_SETTINGS_SECTION, "vsync", _vsync_toggle.button_pressed)
	var save_error := cfg.save(settings_path)
	if save_error != OK:
		push_error("SettingsPanel could not save settings to %s: %s" % [settings_path, save_error])
	return save_error

func _load_slider_from_config(
	cfg: ConfigFile,
	load_error: Error,
	bus_name: StringName,
	key: String,
	slider: HSlider
) -> void:
	var linear_value := _current_bus_linear(bus_name)
	if load_error == OK:
		linear_value = float(cfg.get_value(AUDIO_SETTINGS_SECTION, key, linear_value))
	linear_value = clampf(linear_value, float(slider.min_value), float(slider.max_value))
	slider.set_value_no_signal(linear_value)
	_apply_bus_linear(bus_name, linear_value)

func _load_display_from_config(cfg: ConfigFile, load_error: Error) -> void:
	var fullscreen := DEFAULT_FULLSCREEN
	var vsync := DEFAULT_VSYNC
	if load_error == OK:
		fullscreen = bool(cfg.get_value(DISPLAY_SETTINGS_SECTION, "fullscreen", fullscreen))
		vsync = bool(cfg.get_value(DISPLAY_SETTINGS_SECTION, "vsync", vsync))
	_fullscreen_toggle.set_pressed_no_signal(fullscreen)
	_vsync_toggle.set_pressed_no_signal(vsync)
	_apply_fullscreen(fullscreen)
	_apply_vsync(vsync)

func _on_slider_value_changed(value: float, bus_name: StringName) -> void:
	_apply_bus_linear(bus_name, value)
	if not _loading:
		save_settings()

func _on_fullscreen_toggled(enabled: bool) -> void:
	_apply_fullscreen(enabled)
	if not _loading:
		save_settings()

func _on_vsync_toggled(enabled: bool) -> void:
	_apply_vsync(enabled)
	if not _loading:
		save_settings()

func _apply_bus_linear(bus_name: StringName, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("SettingsPanel could not find audio bus: %s" % String(bus_name))
		return
	AudioServer.set_bus_volume_db(bus_index, _volume_db_for_linear(linear_value))

func _current_bus_linear(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return 1.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)

func _volume_db_for_linear(linear_value: float) -> float:
	if linear_value <= 0.0:
		return SILENCE_DB
	return linear_to_db(clampf(linear_value, MIN_AUDIBLE_LINEAR, 1.0))

func _apply_fullscreen(enabled: bool) -> void:
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)

func _apply_vsync(enabled: bool) -> void:
	var target_mode := DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != target_mode:
		DisplayServer.window_set_vsync_mode(target_mode)

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
		title.add_theme_font_size_override(&"font_size", 46)

	var grid := get_node_or_null("Root/Center/Panel/Margin/VBox/SettingsGrid") as GridContainer
	if grid != null:
		grid.add_theme_constant_override(&"h_separation", 22)
		grid.add_theme_constant_override(&"v_separation", 14)
		for child in grid.get_children():
			var label := child as Label
			if label != null:
				label.add_theme_color_override(&"font_color", BRASS_LIT)
				label.add_theme_font_size_override(&"font_size", 16)

	var sliders: Array[HSlider] = [_master_slider, _music_slider, _sfx_slider]
	for slider in sliders:
		_apply_slider_theme(slider)
	var toggles: Array[CheckButton] = [_fullscreen_toggle, _vsync_toggle]
	for toggle in toggles:
		_apply_toggle_theme(toggle)
	_apply_storybook_button(_done_button)

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

func _apply_slider_theme(slider: HSlider) -> void:
	if slider == null:
		return
	slider.custom_minimum_size = Vector2(maxf(slider.custom_minimum_size.x, 300.0), 40.0)
	slider.focus_mode = Control.FOCUS_ALL
	slider.add_theme_stylebox_override(&"slider", _slider_track_style(INK_LEATHER_DARK, BRASS, 2))
	slider.add_theme_stylebox_override(&"grabber_area", _slider_track_style(BRASS, BRASS_LIT, 1))
	slider.add_theme_stylebox_override(&"grabber_area_highlight", _slider_track_style(BRASS_LIT, PARCHMENT_LIGHT, 1))
	slider.add_theme_stylebox_override(&"focus", _button_style(Color(0.8784, 0.7569, 0.4784, 0.18), BRASS_LIT, 2, 8))

func _apply_toggle_theme(toggle: CheckButton) -> void:
	if toggle == null:
		return
	toggle.custom_minimum_size = Vector2(maxf(toggle.custom_minimum_size.x, 300.0), 44.0)
	toggle.focus_mode = Control.FOCUS_ALL
	toggle.add_theme_font_size_override(&"font_size", 18)
	toggle.add_theme_color_override(&"font_color", PARCHMENT_LIGHT)
	toggle.add_theme_color_override(&"font_hover_color", BRASS_LIT)
	toggle.add_theme_color_override(&"font_focus_color", BRASS_LIT)
	toggle.add_theme_color_override(&"font_pressed_color", PARCHMENT_LIGHT)
	toggle.add_theme_stylebox_override(&"normal", _button_style(Color(0.1020, 0.0824, 0.0706, 0.50), BRASS, 1, 8))
	toggle.add_theme_stylebox_override(&"hover", _button_style(Color(0.145, 0.112, 0.082, 0.70), BRASS_LIT, 1, 8))
	toggle.add_theme_stylebox_override(&"pressed", _button_style(Color(0.0706, 0.0549, 0.0941, 0.70), BRASS, 1, 8))
	toggle.add_theme_stylebox_override(&"focus", _button_style(Color(0.8784, 0.7569, 0.4784, 0.20), BRASS_LIT, 2, 8))

func _apply_storybook_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 180.0), 48.0)
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

func _slider_track_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := _button_style(bg_color, border_color, border_width, 8)
	style.content_margin_left = 0.0
	style.content_margin_top = 4.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 4.0
	return style

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
	style.content_margin_left = 18.0
	style.content_margin_top = 8.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 8.0
	return style
