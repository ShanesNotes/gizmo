class_name HubController
extends Node3D

const MetaState := preload("res://scripts/meta/meta_state.gd")

signal run_requested()

@export var movement_speed: float = 4.0
@export var acceleration: float = 32.0
@export var friction: float = 40.0

var meta_state: MetaState:
	get:
		return _meta_state
	set(value):
		_meta_state = value
		_render_meta_state()

@onready var _scrap_label: Label = %ScrapLabel
@onready var _run_door: Area3D = %RunDoor
@onready var _player_body: CharacterBody3D = %GizmoPlaceholder

var _meta_state: MetaState = null
var _requested_body_ids: Dictionary = {}

func _ready() -> void:
	if _meta_state == null:
		_meta_state = MetaState.new()
	_run_door.body_entered.connect(_on_run_door_body_entered)
	_run_door.body_exited.connect(_on_run_door_body_exited)
	_render_meta_state()

func _physics_process(delta: float) -> void:
	if _player_body == null:
		return

	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	if direction != Vector3.ZERO:
		_player_body.velocity.x = move_toward(_player_body.velocity.x, direction.x * movement_speed, acceleration * delta)
		_player_body.velocity.z = move_toward(_player_body.velocity.z, direction.z * movement_speed, acceleration * delta)
	else:
		_player_body.velocity.x = move_toward(_player_body.velocity.x, 0.0, friction * delta)
		_player_body.velocity.z = move_toward(_player_body.velocity.z, 0.0, friction * delta)

	_player_body.move_and_slide()

func _render_meta_state() -> void:
	if _scrap_label == null or _meta_state == null:
		return
	_scrap_label.text = "SCRAP %d" % _meta_state.scrap_banked

func _on_run_door_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	var body_id := body.get_instance_id()
	if _requested_body_ids.has(body_id):
		return
	_requested_body_ids[body_id] = true
	run_requested.emit()

func _on_run_door_body_exited(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	_requested_body_ids.erase(body.get_instance_id())
