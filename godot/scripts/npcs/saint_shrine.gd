class_name SaintShrine
extends Area3D

const DEFAULT_SAVE_PATH := "user://saves/shrines.cfg"
const SAVE_SECTION := "met"
const PLAYER_GROUP: StringName = &"player"
const PROMPT_TEXT := "venerate"

@export var saint_role: StringName = &"bearer"
@export var display_title: String = "the Bearer - Saint Christopher"
@export var shrine_save_path: String = DEFAULT_SAVE_PATH

var audio_director: Node = null

var _player_bodies: Array[Node3D] = []
var _proximity_shape: CollisionShape3D = null
var _prompt_label: Label3D = null
var _plaque_label: Label3D = null

static func has_met(role: StringName, path: String = DEFAULT_SAVE_PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	return bool(config.get_value(SAVE_SECTION, String(role), false))

static func mark_met(role: StringName, path: String = DEFAULT_SAVE_PATH) -> Error:
	var dir_error := _ensure_base_dir(path)
	if dir_error != OK:
		return dir_error
	var config := ConfigFile.new()
	config.load(path)
	config.set_value(SAVE_SECTION, String(role), true)
	return config.save(path)

static func _ensure_base_dir(path: String) -> Error:
	var base_dir := path.get_base_dir()
	if base_dir == "" or base_dir == ".":
		return OK
	var absolute_dir := base_dir
	if not absolute_dir.is_absolute_path():
		absolute_dir = ProjectSettings.globalize_path(base_dir)
	return DirAccess.make_dir_recursive_absolute(absolute_dir)

func _init() -> void:
	monitoring = true

func _ready() -> void:
	if audio_director == null:
		audio_director = get_node_or_null("/root/AudioDirector")
	_ensure_proximity_shape()
	_ensure_prompt_label()
	_ensure_plaque_label()
	_sync_labels()
	_update_prompt_visibility()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_accept"):
		return
	if not _has_player_inside():
		return
	if _saint_voice_active():
		_consume_input()
		return
	_venerate()
	_consume_input()

func _on_body_entered(body: Node3D) -> void:
	if not _is_player_body(body):
		return
	if not _player_bodies.has(body):
		_player_bodies.append(body)
	_update_prompt_visibility()

func _on_body_exited(body: Node3D) -> void:
	_player_bodies.erase(body)
	_update_prompt_visibility()

func _venerate() -> void:
	var already_met := has_met(saint_role, shrine_save_path)
	var line_id := _offer_line_id()
	if not already_met:
		line_id = _meeting_line_id()
		mark_met(saint_role, shrine_save_path)
	_speak(line_id)

func _speak(line_id: StringName) -> void:
	if line_id == &"" or audio_director == null:
		return
	if audio_director.has_method(&"play_voice_line"):
		audio_director.call(&"play_voice_line", line_id)

func _meeting_line_id() -> StringName:
	return StringName("saint_%s_meeting" % String(saint_role))

func _offer_line_id() -> StringName:
	return StringName("saint_%s_offer" % String(saint_role))

func _saint_voice_active() -> bool:
	if audio_director == null or not audio_director.has_method(&"describe"):
		return false
	var description_value: Variant = audio_director.call(&"describe")
	if not (description_value is Dictionary):
		return false
	var description := description_value as Dictionary
	return bool(description.get("voice_speaking", false)) \
			and String(description.get("last_voice_line", "")).begins_with("saint_")

func _has_player_inside() -> bool:
	for index in range(_player_bodies.size() - 1, -1, -1):
		var body := _player_bodies[index]
		if body == null or not is_instance_valid(body):
			_player_bodies.remove_at(index)
	return not _player_bodies.is_empty()

func _is_player_body(body: Node3D) -> bool:
	if body == null or not (body is CharacterBody3D):
		return false
	if body.is_in_group(PLAYER_GROUP):
		return true
	if not is_inside_tree():
		return true
	return get_tree().get_nodes_in_group(PLAYER_GROUP).is_empty()

func _ensure_proximity_shape() -> CollisionShape3D:
	if _proximity_shape != null and is_instance_valid(_proximity_shape):
		return _proximity_shape
	_proximity_shape = get_node_or_null("ProximityShape") as CollisionShape3D
	if _proximity_shape == null:
		_proximity_shape = CollisionShape3D.new()
		_proximity_shape.name = "ProximityShape"
		add_child(_proximity_shape)
	var cylinder := _proximity_shape.shape as CylinderShape3D
	if cylinder == null:
		cylinder = CylinderShape3D.new()
		_proximity_shape.shape = cylinder
	cylinder.radius = 1.0
	cylinder.height = 2.0
	_proximity_shape.position = Vector3(0.0, 1.0, 0.0)
	return _proximity_shape

func _ensure_prompt_label() -> Label3D:
	if _prompt_label != null and is_instance_valid(_prompt_label):
		return _prompt_label
	_prompt_label = get_node_or_null("PromptLabel") as Label3D
	if _prompt_label == null:
		_prompt_label = Label3D.new()
		_prompt_label.name = "PromptLabel"
		add_child(_prompt_label)
	_prompt_label.text = PROMPT_TEXT
	_prompt_label.position = Vector3(0.0, 2.15, 0.0)
	_prompt_label.font_size = 34
	_prompt_label.outline_size = 8
	_prompt_label.outline_modulate = Color(0.1, 0.06, 0.03, 1.0)
	_prompt_label.modulate = Color(1.0, 0.82, 0.38, 1.0)
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.no_depth_test = true
	return _prompt_label

func _ensure_plaque_label() -> Label3D:
	if _plaque_label != null and is_instance_valid(_plaque_label):
		return _plaque_label
	_plaque_label = get_node_or_null("PlaqueLabel") as Label3D
	if _plaque_label == null:
		_plaque_label = Label3D.new()
		_plaque_label.name = "PlaqueLabel"
		add_child(_plaque_label)
	_plaque_label.position = Vector3(0.0, 0.62, 0.72)
	_plaque_label.font_size = 24
	_plaque_label.outline_size = 6
	_plaque_label.outline_modulate = Color(0.08, 0.05, 0.03, 1.0)
	_plaque_label.modulate = Color(0.96, 0.76, 0.42, 1.0)
	_plaque_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plaque_label.no_depth_test = true
	return _plaque_label

func _sync_labels() -> void:
	if _prompt_label != null:
		_prompt_label.text = PROMPT_TEXT
	if _plaque_label != null:
		_plaque_label.text = display_title

func _update_prompt_visibility() -> void:
	if _prompt_label != null:
		_prompt_label.visible = _has_player_inside()

func _consume_input() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
