class_name TitleScreen
extends Control

const AppSceneDefault := preload("res://scenes/app.tscn")

@export var app_scene: PackedScene = AppSceneDefault

@onready var _start_button: Button = %StartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton
@onready var _settings_panel: Node = %SettingsPanel

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(quit_game)
	_start_button.grab_focus()

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

func _on_settings_pressed() -> void:
	if _settings_panel != null and _settings_panel.has_method(&"open"):
		_settings_panel.call(&"open")
