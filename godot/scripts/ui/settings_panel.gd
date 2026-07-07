class_name SettingsPanel
extends CanvasLayer

const SETTINGS_SECTION := "audio"
const DEFAULT_SETTINGS_PATH := "user://settings.cfg"
const SILENCE_DB := -80.0
const MIN_AUDIBLE_LINEAR := 0.0001

@export var settings_path := DEFAULT_SETTINGS_PATH

@onready var _root: Control = %Root
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _done_button: Button = %DoneButton

var _loading := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.visible = false
	_master_slider.value_changed.connect(_on_slider_value_changed.bind(&"Master"))
	_music_slider.value_changed.connect(_on_slider_value_changed.bind(&"Music"))
	_sfx_slider.value_changed.connect(_on_slider_value_changed.bind(&"SFX"))
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
	_loading = false
	return OK if load_error == OK or load_error == ERR_FILE_NOT_FOUND else load_error

func save_settings() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value(SETTINGS_SECTION, "master", _master_slider.value)
	cfg.set_value(SETTINGS_SECTION, "music", _music_slider.value)
	cfg.set_value(SETTINGS_SECTION, "sfx", _sfx_slider.value)
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
		linear_value = float(cfg.get_value(SETTINGS_SECTION, key, linear_value))
	linear_value = clampf(linear_value, float(slider.min_value), float(slider.max_value))
	slider.set_value_no_signal(linear_value)
	_apply_bus_linear(bus_name, linear_value)

func _on_slider_value_changed(value: float, bus_name: StringName) -> void:
	_apply_bus_linear(bus_name, value)
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
