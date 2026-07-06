class_name RoomDoor
extends Area3D

signal exit_requested(connection: RoomConnection)

enum State { SEALED, OPEN }

const TELEGRAPH_LABEL_NAME := &"RewardTelegraph"

@export var player_group: StringName = &"player"

var state: State = State.SEALED
var bound_connection: RoomConnection = null
var reward_type: RoomNode.RewardType = RoomNode.RewardType.BOON
var door_name: String = ""

var _exit_requested: bool = false
var _overlap_check_generation: int = 0
var _telegraph_label: Label3D = null

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
	_show_reward_telegraph(next_reward_type)
	_overlap_check_generation += 1
	call_deferred("_check_for_already_overlapping_player", _overlap_check_generation)

func seal() -> void:
	state = State.SEALED
	monitoring = false
	bound_connection = null
	reward_type = RoomNode.RewardType.BOON
	door_name = ""
	_exit_requested = false
	_hide_reward_telegraph()
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

func _ensure_telegraph_label() -> Label3D:
	if _telegraph_label != null and is_instance_valid(_telegraph_label):
		return _telegraph_label

	_telegraph_label = Label3D.new()
	_telegraph_label.name = TELEGRAPH_LABEL_NAME
	_telegraph_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_telegraph_label.font_size = 32
	_telegraph_label.position = Vector3(0.0, 1.5, 0.0)
	_telegraph_label.visible = false
	add_child(_telegraph_label)
	return _telegraph_label

func _reward_telegraph_text(next_reward_type: RoomNode.RewardType) -> String:
	match next_reward_type:
		RoomNode.RewardType.BOON:
			return "BOON"
		RoomNode.RewardType.SCRAP:
			return "SCRAP"
		RoomNode.RewardType.SPARKS:
			return "SPARKS"
		RoomNode.RewardType.HAMMER:
			return "HAMMER"
		RoomNode.RewardType.HEAL:
			return "HEAL"
		RoomNode.RewardType.SHOP:
			return "SHOP"
		_:
			return "UNKNOWN"

func _reward_telegraph_color(next_reward_type: RoomNode.RewardType) -> Color:
	match next_reward_type:
		RoomNode.RewardType.BOON:
			return Color(1.0, 0.843, 0.0)
		RoomNode.RewardType.SCRAP:
			return Color(0.804, 0.498, 0.196)
		RoomNode.RewardType.SPARKS:
			return Color(0.259, 0.522, 0.957)
		RoomNode.RewardType.HAMMER:
			return Color(1.0, 0.549, 0.0)
		RoomNode.RewardType.HEAL:
			return Color(0.298, 0.686, 0.314)
		RoomNode.RewardType.SHOP:
			return Color(0.612, 0.153, 0.690)
		_:
			return Color.WHITE

func _show_reward_telegraph(next_reward_type: RoomNode.RewardType) -> void:
	var label := _ensure_telegraph_label()
	label.text = _reward_telegraph_text(next_reward_type)
	label.modulate = _reward_telegraph_color(next_reward_type)
	label.visible = true

func _hide_reward_telegraph() -> void:
	if _telegraph_label != null and is_instance_valid(_telegraph_label):
		_telegraph_label.visible = false
