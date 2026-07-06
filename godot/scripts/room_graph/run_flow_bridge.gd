class_name RunFlowBridge
extends Node

const BoonDef := preload("res://scripts/boons/boon_def.gd")
const BoonDraft := preload("res://scripts/boons/boon_draft.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RunController := preload("res://scripts/room_graph/run_controller.gd")

signal reward_granted(reward_type: RoomNode.RewardType, connection: RoomConnection)
signal draft_started(connection: RoomConnection, offers: Array[BoonDef])
signal exit_completed(connection: RoomConnection, accepted: bool)
signal _ui_boon_chosen(boon: BoonDef)

var run_controller: RunController
var boon_draft: BoonDraft
var ui_surface: Object
var ability_kit: AbilityComponent
var boon_pool: Array[BoonDef] = []
var rng: RandomNumberGenerator
var offer_count: int = BoonDraft.DEFAULT_OFFER_COUNT

var _draft_open := false
var _consumed_boon_exit_keys: Dictionary = {}

func configure(
	initial_run_controller: RunController,
	initial_boon_draft: BoonDraft,
	initial_ui_surface: Object,
	initial_boon_pool: Array[BoonDef] = [],
	initial_rng: RandomNumberGenerator = null,
	initial_ability_kit: AbilityComponent = null,
) -> void:
	run_controller = initial_run_controller
	boon_draft = initial_boon_draft
	ui_surface = initial_ui_surface
	boon_pool = initial_boon_pool
	rng = initial_rng
	ability_kit = initial_ability_kit
	_draft_open = false
	_consumed_boon_exit_keys.clear()

func set_ability_kit(target_ability_kit: AbilityComponent) -> void:
	ability_kit = target_ability_kit

func set_boon_pool(pool: Array[BoonDef]) -> void:
	boon_pool = pool

func request_exit(connection: RoomConnection) -> bool:
	if _draft_open:
		push_error("RunFlowBridge: request_exit rejected while a boon draft is open.")
		return false
	if not _can_request_exit(connection):
		return false

	var reward_type := run_controller.exit_reward_type(connection)
	if reward_type != RoomNode.RewardType.BOON:
		reward_granted.emit(reward_type, connection)
		var non_boon_accepted := run_controller.choose_exit(connection)
		exit_completed.emit(connection, non_boon_accepted)
		return non_boon_accepted

	if _is_boon_exit_consumed(connection):
		var consumed_exit_accepted := run_controller.choose_exit(connection)
		exit_completed.emit(connection, consumed_exit_accepted)
		return consumed_exit_accepted

	if not _can_choose_exit_now(connection):
		exit_completed.emit(connection, false)
		return false

	return await _request_boon_exit(connection)

func is_draft_open() -> bool:
	return _draft_open

func _request_boon_exit(connection: RoomConnection) -> bool:
	if ability_kit == null:
		push_error("RunFlowBridge: BOON exits require an injected AbilityComponent.")
		exit_completed.emit(connection, false)
		return false

	_draft_open = true
	var offers := boon_draft.offer_between_rooms(
		run_controller.graph,
		run_controller.current_room_id,
		boon_pool,
		_active_rng(),
		offer_count
	)
	if offers.size() != offer_count:
		push_error("RunFlowBridge: expected %d boon offers, got %d." % [offer_count, offers.size()])
		_clear_draft()
		exit_completed.emit(connection, false)
		return false

	var connect_error := ui_surface.connect(&"boon_chosen", Callable(self, "_on_ui_boon_chosen"), CONNECT_ONE_SHOT)
	if connect_error != OK:
		push_error("RunFlowBridge: could not connect to ui_surface.boon_chosen.")
		_clear_draft()
		exit_completed.emit(connection, false)
		return false

	ui_surface.call("present", offers)
	draft_started.emit(connection, offers)

	var chosen_boon: BoonDef = await _ui_boon_chosen
	var accepted := boon_draft.accept_boon(chosen_boon, ability_kit)
	if not accepted:
		push_error("RunFlowBridge: selected boon could not be applied.")
		_clear_draft()
		exit_completed.emit(connection, false)
		return false

	_mark_boon_exit_consumed(connection)
	var exit_accepted := run_controller.choose_exit(connection)
	_clear_draft()
	exit_completed.emit(connection, exit_accepted)
	return exit_accepted

func _on_ui_boon_chosen(boon: BoonDef) -> void:
	_ui_boon_chosen.emit(boon)

func _can_request_exit(connection: RoomConnection) -> bool:
	if run_controller == null:
		push_error("RunFlowBridge: missing RunController.")
		return false
	if boon_draft == null:
		push_error("RunFlowBridge: missing BoonDraft.")
		return false
	if ui_surface == null:
		push_error("RunFlowBridge: missing UI surface.")
		return false
	if connection == null:
		push_error("RunFlowBridge: request_exit called with null connection.")
		return false
	if not ui_surface.has_method("present"):
		push_error("RunFlowBridge: UI surface must expose present(offers).")
		return false
	if not ui_surface.has_signal(&"boon_chosen"):
		push_error("RunFlowBridge: UI surface must expose boon_chosen.")
		return false
	return true

func _can_choose_exit_now(connection: RoomConnection) -> bool:
	if run_controller == null or run_controller.graph == null:
		return false
	if connection == null:
		return false
	if connection.from_room_id != run_controller.current_room_id:
		return false

	var current_room := run_controller.graph.get_room(run_controller.current_room_id)
	if current_room == null or current_room.state != RoomNode.State.CLEARED:
		return false

	var destination := run_controller.graph.get_room(connection.to_room_id)
	return destination != null and destination.state == RoomNode.State.AVAILABLE

func _active_rng() -> RandomNumberGenerator:
	if rng != null:
		return rng
	rng = RandomNumberGenerator.new()
	rng.randomize()
	return rng

func _clear_draft() -> void:
	_draft_open = false

func _mark_boon_exit_consumed(connection: RoomConnection) -> void:
	_consumed_boon_exit_keys[_connection_key(connection)] = true

func _is_boon_exit_consumed(connection: RoomConnection) -> bool:
	return _consumed_boon_exit_keys.has(_connection_key(connection))

func _connection_key(connection: RoomConnection) -> String:
	if connection == null:
		return ""
	return "%s>%s:%s" % [connection.from_room_id, connection.to_room_id, connection.door_name]
