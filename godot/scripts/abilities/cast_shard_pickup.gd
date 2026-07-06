class_name CastShardPickup
extends Area3D

@export var player_group: StringName = &"player"

var shard_key: String = ""
var owner_spawn_id: String = ""

var _claimed := false
var _overlap_check_generation := 0

func _init() -> void:
	monitoring = true

func configure(p_shard_key: String, p_owner_spawn_id: String = "") -> void:
	shard_key = p_shard_key
	owner_spawn_id = p_owner_spawn_id

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	set_physics_process(true)
	_overlap_check_generation += 1
	call_deferred("_check_for_already_overlapping_player", _overlap_check_generation)

func _physics_process(_delta: float) -> void:
	if _claimed:
		set_physics_process(false)
		return
	_claim_first_overlapping_player()

func _on_body_entered(body: Node3D) -> void:
	_claim_from_body(body)

func _check_for_already_overlapping_player(generation: int) -> void:
	if not is_inside_tree():
		return
	await get_tree().physics_frame
	if generation != _overlap_check_generation or _claimed:
		return
	_claim_first_overlapping_player()

func _claim_first_overlapping_player() -> bool:
	for body in get_overlapping_bodies():
		if _claim_from_body(body as Node3D):
			return true
	return false

func _claim_from_body(body: Node3D) -> bool:
	if _claimed or not _is_player_body(body):
		return false
	var orchestrator := _find_orchestrator()
	if orchestrator == null:
		return false
	if bool(orchestrator.call("reclaim_cast_shard_once", shard_key)):
		_claimed = true
		set_deferred("monitoring", false)
		set_physics_process(false)
		return true
	return false

func _find_orchestrator() -> Node:
	var cursor: Node = self
	while cursor != null:
		if cursor.has_method("reclaim_cast_shard_once"):
			return cursor
		cursor = cursor.get_parent()
	push_warning("CastShardPickup '%s' found no RunOrchestrator ancestor; reclaim disabled." % name)
	return null

func _is_player_body(body: Node3D) -> bool:
	if body == null:
		return false
	return body is CharacterBody3D and body.is_in_group(player_group)
