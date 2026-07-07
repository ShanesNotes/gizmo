class_name RoomDoor
extends Area3D

signal exit_requested(connection: RoomConnection)

enum State { SEALED, OPEN }

const TELEGRAPH_LABEL_NAME := &"RewardTelegraph"
const UNLOCK_SHINE_NAME := &"UnlockShine"
# Warm gold flash on unlock (tokens.metal.gold_lit #e0c17a — room-clear reward beat).
const UNLOCK_SHINE_COLOR := Color(0.878, 0.757, 0.478)
const UNLOCK_SHINE_PEAK_ENERGY := 2.2
const UNLOCK_SHINE_SECONDS := 0.45

@export var player_group: StringName = &"player"

var state: State = State.SEALED
var bound_connection: RoomConnection = null
var reward_type: RoomNode.RewardType = RoomNode.RewardType.BOON
var door_name: String = ""

var _exit_requested: bool = false
var _overlap_check_generation: int = 0
var _telegraph_label: Label3D = null
var _unlock_shine: OmniLight3D = null
var _shine_tween: Tween = null

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
	_notify_audio_event(&"door_open")
	_show_reward_telegraph(next_reward_type)
	_play_unlock_shine()
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
	_snuff_unlock_shine()
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
			return "INGENUITY"
		RoomNode.RewardType.HEAL:
			return "MENDING"
		RoomNode.RewardType.SHOP:
			return "TRADE"
		RoomNode.RewardType.REST:
			return "SANCTUARY"
		RoomNode.RewardType.REWARD:
			return "RELIQUARY"
		_:
			return "UNMARKED"

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
		RoomNode.RewardType.REST:
			return Color(0.42, 0.82, 0.72)
		RoomNode.RewardType.REWARD:
			return Color(0.78, 0.86, 0.92)
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

func _ensure_unlock_shine() -> OmniLight3D:
	if _unlock_shine != null and is_instance_valid(_unlock_shine):
		return _unlock_shine

	_unlock_shine = OmniLight3D.new()
	_unlock_shine.name = UNLOCK_SHINE_NAME
	_unlock_shine.light_color = UNLOCK_SHINE_COLOR
	_unlock_shine.omni_range = 4.0
	_unlock_shine.light_energy = 0.0
	_unlock_shine.position = Vector3(0.0, 1.2, 0.0)
	add_child(_unlock_shine)
	return _unlock_shine

## Cosmetic room-clear beat: a brief warm flash on the door telegraph when it
## unlocks. Purely visual — no gameplay state.
func _play_unlock_shine() -> void:
	var shine := _ensure_unlock_shine()
	if _shine_tween != null and _shine_tween.is_valid():
		_shine_tween.kill()
	shine.light_energy = UNLOCK_SHINE_PEAK_ENERGY
	if not is_inside_tree():
		return
	_shine_tween = create_tween()
	_shine_tween.tween_property(shine, "light_energy", 0.0, UNLOCK_SHINE_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _snuff_unlock_shine() -> void:
	if _shine_tween != null and _shine_tween.is_valid():
		_shine_tween.kill()
	if _unlock_shine != null and is_instance_valid(_unlock_shine):
		_unlock_shine.light_energy = 0.0

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)
