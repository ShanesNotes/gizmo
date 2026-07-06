class_name RoomDoor
extends Area3D

signal exit_requested(connection: RoomConnection)

enum State { SEALED, OPEN }

@export var player_group: StringName = &"player"

var state: State = State.SEALED
var bound_connection: RoomConnection = null
var reward_type: RoomNode.RewardType = RoomNode.RewardType.BOON
var door_name: String = ""

var _exit_requested: bool = false

func _init() -> void:
	monitoring = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func open_for(connection: RoomConnection, next_reward_type: RoomNode.RewardType) -> void:
	if connection == null:
		push_error("RoomDoor: open_for requires a RoomConnection")
		seal()
		return

	bound_connection = connection
	reward_type = next_reward_type
	door_name = connection.door_name
	state = State.OPEN
	_exit_requested = false
	monitoring = true

func seal() -> void:
	state = State.SEALED
	monitoring = false
	bound_connection = null
	reward_type = RoomNode.RewardType.BOON
	door_name = ""
	_exit_requested = false

func telegraph_data() -> Dictionary:
	return {
		&"door_name": door_name,
		&"reward_type": reward_type,
	}

func _on_body_entered(body: Node3D) -> void:
	if state != State.OPEN:
		return
	if _exit_requested:
		return
	if bound_connection == null:
		return
	if not _is_player_body(body):
		return

	_exit_requested = true
	exit_requested.emit(bound_connection)

func _is_player_body(body: Node3D) -> bool:
	if body == null:
		return false
	if body is GizmoPlayer:
		return true
	return body is CharacterBody3D and body.is_in_group(player_group)
