class_name CastShardPickup
extends Area3D

@export var player_group: StringName = &"player"
@export_range(0.0, 10.0, 0.1) var magnet_radius: float = 2.5
@export_range(0.0, 30.0, 0.1) var magnet_lerp_speed: float = 8.0

const OWNER_CHEST_OFFSET := Vector3(0.0, 1.1, 0.0)
const FLOOR_HEIGHT := 0.45
const OWNER_PULSE_BASE_ENERGY := 0.65
const OWNER_PULSE_ENERGY_RANGE := 0.35
const OWNER_PULSE_SPEED := 2.4

var shard_key: String = ""
var owner_spawn_id: String = ""

var _claimed := false
var _overlap_check_generation := 0
var _owner_enemy_ref: WeakRef = null
var _owner_was_tracked := false
var _last_owner_floor_position := Vector3.ZERO
var _pulse_time := 0.0
var _pulse_material: StandardMaterial3D = null

func _init() -> void:
	monitoring = true

func configure(p_shard_key: String, p_owner_spawn_id: String = "", p_owner_enemy: Node3D = null) -> void:
	shard_key = p_shard_key
	owner_spawn_id = p_owner_spawn_id
	_set_owner_enemy(p_owner_enemy)

func release_owner_tracking(drop_to_floor: bool = true) -> void:
	_owner_enemy_ref = null
	owner_spawn_id = ""
	if drop_to_floor:
		_drop_to_floor()
	_owner_was_tracked = false
	_reset_owner_pulse()

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	set_physics_process(true)
	set_process(true)
	_cache_visual_material()
	_track_live_owner()
	_overlap_check_generation += 1
	call_deferred("_check_for_already_overlapping_player", _overlap_check_generation)

func _physics_process(_delta: float) -> void:
	if _claimed:
		set_process(false)
		set_physics_process(false)
		return
	if _track_live_owner():
		_claim_first_overlapping_player()
		return
	_magnet_toward_player(_delta)
	_claim_first_overlapping_player()

func _process(delta: float) -> void:
	if _claimed:
		set_process(false)
		return
	if _owner_enemy() != null:
		_pulse_owner_lodged_visual(delta)
	else:
		_reset_owner_pulse()

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
		_spawn_collect_pulse()
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

func _magnet_toward_player(delta: float) -> void:
	var player := _nearest_player_in_magnet_radius()
	if player == null:
		return
	var target := player.global_position
	target.y = global_position.y
	var weight := clampf(delta * magnet_lerp_speed, 0.0, 1.0)
	global_position = global_position.lerp(target, weight)

func _nearest_player_in_magnet_radius() -> Node3D:
	if magnet_radius <= 0.0 or not is_inside_tree():
		return null
	var nearest: Node3D = null
	var nearest_distance_sq := magnet_radius * magnet_radius
	for candidate in get_tree().get_nodes_in_group(String(player_group)):
		if not (candidate is Node3D) or not is_instance_valid(candidate):
			continue
		var candidate_body := candidate as Node3D
		var distance_sq := global_position.distance_squared_to(candidate_body.global_position)
		if distance_sq <= nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest = candidate_body
	return nearest

func _set_owner_enemy(owner_enemy: Node3D) -> void:
	if owner_enemy != null and is_instance_valid(owner_enemy):
		_owner_enemy_ref = weakref(owner_enemy)
		_last_owner_floor_position = owner_enemy.global_position
	else:
		_owner_enemy_ref = null

func _track_live_owner() -> bool:
	var owner := _owner_enemy()
	if owner == null:
		if _owner_enemy_ref != null or _owner_was_tracked:
			release_owner_tracking(true)
		return false
	_owner_was_tracked = true
	_last_owner_floor_position = owner.global_position
	global_position = owner.global_position + OWNER_CHEST_OFFSET
	return true

func _owner_enemy() -> Node3D:
	if _owner_enemy_ref == null:
		return null
	var owner_object: Object = _owner_enemy_ref.get_ref()
	if not (owner_object is Node3D) or not is_instance_valid(owner_object):
		return null
	var owner := owner_object as Node3D
	if _node_is_dead(owner):
		return null
	return owner

func _node_is_dead(node: Node) -> bool:
	return node != null and node.has_method(&"is_dead") and bool(node.call(&"is_dead"))

func _drop_to_floor() -> void:
	var floor_position := _last_owner_floor_position if _owner_was_tracked else global_position
	global_position = Vector3(floor_position.x, maxf(floor_position.y, FLOOR_HEIGHT), floor_position.z)

func _cache_visual_material() -> void:
	var visual := get_node_or_null("Visual") as MeshInstance3D
	if visual != null and visual.material_override is StandardMaterial3D:
		_pulse_material = visual.material_override as StandardMaterial3D

func _pulse_owner_lodged_visual(delta: float) -> void:
	if _pulse_material == null:
		_cache_visual_material()
	if _pulse_material == null:
		return
	_pulse_time += maxf(delta, 0.0)
	var wave := (sin(_pulse_time * TAU * OWNER_PULSE_SPEED) + 1.0) * 0.5
	_pulse_material.emission_energy_multiplier = OWNER_PULSE_BASE_ENERGY + wave * OWNER_PULSE_ENERGY_RANGE

func _reset_owner_pulse() -> void:
	if _pulse_material == null:
		return
	_pulse_material.emission_energy_multiplier = 0.45

func _spawn_collect_pulse() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var pulse := MeshInstance3D.new()
	pulse.name = "CollectSparklePulse"
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.44
	pulse.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.95, 0.78, 0.38, 0.65)
	material.emission_enabled = true
	material.emission = Color(0.95, 0.58, 0.16, 1.0)
	material.emission_energy_multiplier = 1.15
	material.roughness = 0.55
	pulse.material_override = material
	parent.add_child(pulse)
	pulse.global_position = global_position
	pulse.scale = Vector3.ONE * 0.35
	var tween := pulse.create_tween()
	tween.tween_property(pulse, "scale", Vector3.ONE * 1.25, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(pulse.queue_free)
