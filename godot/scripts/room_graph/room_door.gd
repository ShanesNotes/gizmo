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
var _overlap_check_generation: int = 0

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
	_overlap_check_generation += 1
	call_deferred("_check_for_already_overlapping_player", _overlap_check_generation)

func seal() -> void:
	state = State.SEALED
	monitoring = false
	bound_connection = null
	reward_type = RoomNode.RewardType.BOON
	door_name = ""
	_exit_requested = false
	_overlap_check_generation += 1

func telegraph_data() -> Dictionary:
	return {
		&"door_name": door_name,
		&"reward_type": reward_type,
	}

func _on_body_entered(body: Node3D) -> void:
	_request_exit_from_body(body)

func _check_for_already_overlapping_player(generation: int) -> void:
	if not is_inside_tree():
		return
	await get_tree().physics_frame
	if generation != _overlap_check_generation:
		return
	if state != State.OPEN or _exit_requested or bound_connection == null:
		return
	for body in get_overlapping_bodies():
		if _request_exit_from_body(body):
			return

func _request_exit_from_body(body: Node3D) -> bool:
	if state != State.OPEN:
		return false
	if _exit_requested:
		return false
	if bound_connection == null:
		return false
	if not _is_player_body(body):
		return false

	_exit_requested = true
	exit_requested.emit(bound_connection)
	return true

func _is_player_body(body: Node3D) -> bool:
	if body == null:
		return false
	return body is CharacterBody3D and body.is_in_group(player_group)
