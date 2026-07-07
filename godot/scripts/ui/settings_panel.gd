class_name SettingsPanel
extends CanvasLayer

const AUDIO_SETTINGS_SECTION := "audio"
const DISPLAY_SETTINGS_SECTION := "display"
const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
const SILENCE_DB := -80.0
const MIN_AUDIBLE_LINEAR := 0.0001
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC := true

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
