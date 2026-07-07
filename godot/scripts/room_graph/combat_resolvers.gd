class_name CombatResolvers
extends Node

## CombatResolvers is the run combat module. Its seam is deliberately narrow:
## configure() receives scalar tuning plus Callables for player, kit, enemy
## snapshot, shard parent, run state, and HUD refresh. The module does not keep
## a RunOrchestrator back-reference; the orchestrator remains the owner of room
## lifecycle and only forwards room cleanup, enemy-death reclaim, and pickup
## reclaim calls across this seam.

const CombatEffectsScript := preload("res://scripts/room_graph/combat_effects.gd")
const CastShardPickupScript := preload("res://scripts/abilities/cast_shard_pickup.gd")

var melee_range: float = 2.0
var melee_arc_degrees: float = 120.0
var special_range: float = 2.75
var special_arc_degrees: float = 160.0
var cast_range: float = 8.0
var cast_arc_degrees: float = 20.0

var _player_provider: Callable = Callable()
var _ability_kit_provider: Callable = Callable()
var _enemy_snapshot_provider: Callable = Callable()
var _shard_parent_provider: Callable = Callable()
var _run_state_provider: Callable = Callable()
var _render_hud_payloads: Callable = Callable()
var _bound_kit: AbilityComponent = null
var _cast_shard_sequence: int = 0
var _cast_shards_by_key: Dictionary = {}
var _cast_shard_keys_by_spawn_id: Dictionary = {}

func configure(context: Dictionary) -> void:
	melee_range = float(context.get("melee_range", melee_range))
	melee_arc_degrees = float(context.get("melee_arc_degrees", melee_arc_degrees))
	special_range = float(context.get("special_range", special_range))
	special_arc_degrees = float(context.get("special_arc_degrees", special_arc_degrees))
	cast_range = float(context.get("cast_range", cast_range))
	cast_arc_degrees = float(context.get("cast_arc_degrees", cast_arc_degrees))
	_player_provider = context.get("player_provider", _player_provider) as Callable
	_ability_kit_provider = context.get("ability_kit_provider", _ability_kit_provider) as Callable
	_enemy_snapshot_provider = context.get("enemy_snapshot_provider", _enemy_snapshot_provider) as Callable
	_shard_parent_provider = context.get("shard_parent_provider", _shard_parent_provider) as Callable
	_run_state_provider = context.get("run_state_provider", _run_state_provider) as Callable
	_render_hud_payloads = context.get("render_hud_payloads", _render_hud_payloads) as Callable

func bind_ability_kit(kit: AbilityComponent) -> void:
	if _bound_kit == kit:
		return
	_disconnect_ability_kit()
	_bound_kit = kit
	if _bound_kit == null:
		return
	_connect_ability_signal(_bound_kit.dash_started, Callable(self, "_on_player_dash_started"))
	_connect_ability_signal(_bound_kit.attack_started, Callable(self, "_on_player_attack_started"))
	_connect_ability_signal(_bound_kit.special_started, Callable(self, "_on_player_special_started"))
	_connect_ability_signal(_bound_kit.cast_started, Callable(self, "_on_player_cast_started"))
	_connect_ability_signal(_bound_kit.surge_started, Callable(self, "_on_player_surge_started"))
	_connect_ability_signal(_bound_kit.cast_ammo_changed, Callable(self, "_on_player_cast_ammo_changed"))

func reset_for_run() -> void:
	_clear_cast_shards(false)
	_cast_shard_sequence = 0

func clear_for_room_cleanup(reclaim: bool) -> void:
	_clear_cast_shards(reclaim)

func reclaim_cast_shard_once(shard_key: String) -> bool:
	var run_state := _run_state()
	if not bool(run_state.get("run_active", false)) or bool(run_state.get("death_teardown_complete", false)):
		return false
	var key := shard_key.strip_edges()
	if key == "" or not _cast_shards_by_key.has(key):
		return false
	return _reclaim_cast_shard_key(key)

func reclaim_cast_shards_for_spawn_id(spawn_id: String) -> void:
	_reclaim_cast_shards_for_spawn_id(spawn_id)

func _connect_ability_signal(ability_signal: Signal, callback: Callable) -> void:
	if not ability_signal.is_connected(callback):
		ability_signal.connect(callback)

func _disconnect_ability_kit() -> void:
	if _bound_kit == null:
		return
	_disconnect_ability_signal(_bound_kit.dash_started, Callable(self, "_on_player_dash_started"))
	_disconnect_ability_signal(_bound_kit.attack_started, Callable(self, "_on_player_attack_started"))
	_disconnect_ability_signal(_bound_kit.special_started, Callable(self, "_on_player_special_started"))
	_disconnect_ability_signal(_bound_kit.cast_started, Callable(self, "_on_player_cast_started"))
	_disconnect_ability_signal(_bound_kit.surge_started, Callable(self, "_on_player_surge_started"))
	_disconnect_ability_signal(_bound_kit.cast_ammo_changed, Callable(self, "_on_player_cast_ammo_changed"))

func _disconnect_ability_signal(ability_signal: Signal, callback: Callable) -> void:
	if ability_signal.is_connected(callback):
		ability_signal.disconnect(callback)

func _on_player_dash_started(_direction: Vector3, _speed: float, _duration: float) -> void:
	if not _combat_input_allowed():
		return
	_notify_audio_event(&"dash_whoosh")

func _on_player_attack_started(_step: int, damage: float) -> void:
	if not _combat_input_allowed():
		return
	_spawn_swing_read(melee_range)
	var hits := _resolve_player_arc_damage(damage, melee_range, melee_arc_degrees)
	if hits > 0:
		_notify_audio_event(&"melee_hit")

func _on_player_special_started(potency: float) -> void:
	if not _combat_input_allowed():
		return
	_spawn_swing_read(special_range)
	var hits := _resolve_player_arc_damage(potency, special_range, special_arc_degrees)
	if hits > 0:
		_notify_audio_event(&"melee_hit")

func _on_player_cast_started(potency: float) -> void:
	if not _combat_input_allowed():
		# The kit consumed ammo before emitting; a gated cast must refund or
		# the stone is silently stranded (HZ-074 audit HIGH).
		_refund_cast_ammo()
		return
	_notify_audio_event(&"cast_shot")
	_resolve_player_cast_damage(potency)

func _on_player_cast_ammo_changed(_current_ammo: int, _max_ammo: int, _lodged_ammo: int) -> void:
	_render_hud()

func _on_player_surge_started(damage: float, radius: float, stagger_seconds: float) -> void:
	if not _combat_input_allowed():
		return
	var active_player := _player()
	if active_player == null:
		return
	_notify_audio_event(&"surge_burst")
	var center := active_player.global_position
	CombatEffectsScript.spawn_burst_ring(_shard_parent(), center, radius)
	var snapshot: Array = _enemy_snapshot()
	for candidate in snapshot:
		if not (candidate is GreyboxEnemy) or not is_instance_valid(candidate):
			continue
		var enemy := candidate as GreyboxEnemy
		if enemy.is_dead() or enemy.is_spawning() or _xz_distance(enemy.global_position, center) > radius:
			continue
		enemy.stagger(stagger_seconds)
		enemy.take_damage(damage, false)
	_render_hud()

func _spawn_swing_read(swing_range: float) -> void:
	var active_player := _player()
	if active_player == null:
		return
	CombatEffectsScript.spawn_swing_wedge(
		_shard_parent(),
		active_player.global_position,
		_player_facing_direction(active_player),
		swing_range
	)

func _resolve_player_arc_damage(damage: float, attack_range: float, arc_degrees: float) -> int:
	var active_player := _player()
	if active_player == null or damage <= 0.0:
		_render_hud()
		return 0
	var center := active_player.global_position
	var forward := _player_facing_direction(active_player)
	var hits := 0
	for enemy in _damageable_enemy_snapshot():
		if not _is_enemy_in_player_arc(enemy, center, forward, attack_range, arc_degrees):
			continue
		enemy.take_damage(damage, true)
		hits += 1
	_render_hud()
	return hits

func _resolve_player_cast_damage(damage: float) -> GreyboxEnemy:
	var active_player := _player()
	if active_player == null:
		# Post-consume abort: never strand the stone (HZ-074 audit HIGH).
		_refund_cast_ammo()
		_render_hud()
		return null
	var center := active_player.global_position
	var forward := _player_facing_direction(active_player)
	var target := _first_enemy_in_cast_corridor(center, forward)
	if target == null:
		_register_cast_shard("", center + _flat_forward_or_default(forward) * maxf(cast_range, 0.0))
		_render_hud()
		return null

	_register_cast_shard(target.spawn_id, target.global_position)
	if damage > 0.0:
		target.take_damage(damage, true)
	_render_hud()
	return target

func _first_enemy_in_cast_corridor(center: Vector3, forward: Vector3) -> GreyboxEnemy:
	var flat_forward := _flat_forward_or_default(forward)
	var best: GreyboxEnemy = null
	var best_projection := INF
	var best_distance := INF
	for enemy in _damageable_enemy_snapshot():
		var offset := Vector3(enemy.global_position.x - center.x, 0.0, enemy.global_position.z - center.z)
		var distance := offset.length()
		if distance > maxf(cast_range, 0.0):
			continue
		if distance <= 0.000001:
			return enemy
		var projection := flat_forward.dot(offset)
		if projection < 0.0:
			continue
		if not _offset_in_forward_arc(offset, flat_forward, cast_arc_degrees):
			continue
		if projection < best_projection - 0.001 or (absf(projection - best_projection) <= 0.001 and distance < best_distance):
			best = enemy
			best_projection = projection
			best_distance = distance
	return best

func _is_enemy_in_melee_arc(enemy: GreyboxEnemy, center: Vector3, forward: Vector3) -> bool:
	return _is_enemy_in_player_arc(enemy, center, forward, melee_range, melee_arc_degrees)

func _is_enemy_in_player_arc(
	enemy: GreyboxEnemy,
	center: Vector3,
	forward: Vector3,
	attack_range: float,
	arc_degrees: float
) -> bool:
	var offset := Vector3(enemy.global_position.x - center.x, 0.0, enemy.global_position.z - center.z)
	var distance := offset.length()
	if distance > maxf(attack_range, 0.0):
		return false
	if distance <= 0.000001:
		return true

	return _offset_in_forward_arc(offset, forward, arc_degrees)

func _offset_in_forward_arc(offset: Vector3, forward: Vector3, arc_degrees: float) -> bool:
	var distance := offset.length()
	if distance <= 0.000001:
		return true
	var flat_forward := _flat_forward_or_default(forward)
	if arc_degrees >= 359.9:
		return true
	var half_arc := deg_to_rad(clampf(arc_degrees, 1.0, 360.0) * 0.5)
	return flat_forward.dot(offset / distance) >= cos(half_arc)

func _flat_forward_or_default(forward: Vector3) -> Vector3:
	var flat_forward := Vector3(forward.x, 0.0, forward.z)
	if flat_forward.length_squared() <= 0.000001:
		return Vector3(0.0, 0.0, -1.0)
	return flat_forward.normalized()

func _damageable_enemy_snapshot() -> Array[GreyboxEnemy]:
	var enemies: Array[GreyboxEnemy] = []
	var snapshot: Array = _enemy_snapshot()
	for candidate in snapshot:
		if not (candidate is GreyboxEnemy) or not is_instance_valid(candidate):
			continue
		var enemy := candidate as GreyboxEnemy
		if _enemy_can_receive_player_damage(enemy):
			enemies.append(enemy)
	return enemies

func _enemy_can_receive_player_damage(enemy: GreyboxEnemy) -> bool:
	return enemy != null and is_instance_valid(enemy) and not enemy.is_dead() and not enemy.is_spawning()

func _refund_cast_ammo() -> void:
	var kit := _ability_kit()
	if kit != null:
		kit.reclaim_cast_ammo(1)

func _register_cast_shard(owner_spawn_id: String, position: Vector3) -> String:
	_cast_shard_sequence += 1
	var shard_key := "cast_shard:%d" % _cast_shard_sequence
	var pickup := _spawn_cast_shard_pickup(shard_key, owner_spawn_id, position)
	_cast_shards_by_key[shard_key] = {
		"spawn_id": owner_spawn_id,
		"pickup": pickup,
	}
	if owner_spawn_id != "":
		var keys: Array = _cast_shard_keys_by_spawn_id.get(owner_spawn_id, [])
		keys.append(shard_key)
		_cast_shard_keys_by_spawn_id[owner_spawn_id] = keys
	return shard_key

func _spawn_cast_shard_pickup(shard_key: String, owner_spawn_id: String, position: Vector3) -> Area3D:
	var parent := _shard_parent()
	if parent == null:
		return null

	var pickup := CastShardPickupScript.new() as Area3D
	pickup.name = "CastShardPickup%d" % _cast_shard_sequence
	pickup.call("configure", shard_key, owner_spawn_id)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	shape.shape = sphere
	pickup.add_child(shape)

	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.88, 0.74, 0.38, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.55, 0.34, 0.08, 1.0)
	material.emission_energy_multiplier = 0.45
	material.roughness = 0.78
	visual.material_override = material
	pickup.add_child(visual)

	parent.add_child(pickup)
	pickup.global_position = Vector3(position.x, maxf(position.y, 0.45), position.z)
	return pickup

func _reclaim_cast_shards_for_spawn_id(spawn_id: String) -> void:
	var keys: Array = _cast_shard_keys_by_spawn_id.get(spawn_id, []).duplicate()
	for key in keys:
		var shard_key := String(key)
		if _reclaim_cast_shard_key(shard_key):
			continue
		# Reclaim refused (e.g. ammo already full): the victim is being freed,
		# so convert the record to an ownerless floor pickup instead of
		# orphaning it against a dead spawn_id (HZ-074 audit).
		_disown_cast_shard(shard_key)

func _reclaim_cast_shard_key(shard_key: String) -> bool:
	if not _cast_shards_by_key.has(shard_key):
		return false
	var kit := _ability_kit()
	if kit == null:
		return false
	var reclaimed := kit.reclaim_cast_ammo(1)
	if reclaimed <= 0:
		return false
	_remove_cast_shard_record(shard_key)
	_render_hud()
	return true

func _disown_cast_shard(shard_key: String) -> void:
	if not _cast_shards_by_key.has(shard_key):
		return
	var record: Dictionary = _cast_shards_by_key[shard_key]
	var spawn_id := String(record.get("spawn_id", ""))
	record["spawn_id"] = ""
	_cast_shards_by_key[shard_key] = record
	if spawn_id == "":
		return
	var keys: Array = _cast_shard_keys_by_spawn_id.get(spawn_id, [])
	keys.erase(shard_key)
	if keys.is_empty():
		_cast_shard_keys_by_spawn_id.erase(spawn_id)
	else:
		_cast_shard_keys_by_spawn_id[spawn_id] = keys

func _clear_cast_shards(reclaim: bool) -> void:
	var keys: Array = _cast_shards_by_key.keys()
	for key in keys:
		var shard_key := String(key)
		if reclaim and _reclaim_cast_shard_key(shard_key):
			continue
		_remove_cast_shard_record(shard_key)
	_cast_shards_by_key.clear()
	_cast_shard_keys_by_spawn_id.clear()

func _remove_cast_shard_record(shard_key: String) -> void:
	var record: Dictionary = _cast_shards_by_key.get(shard_key, {})
	var spawn_id := String(record.get("spawn_id", ""))
	var pickup := record.get("pickup") as Node
	if pickup != null and is_instance_valid(pickup):
		pickup.queue_free()
	_cast_shards_by_key.erase(shard_key)

	if spawn_id == "":
		return
	var keys: Array = _cast_shard_keys_by_spawn_id.get(spawn_id, [])
	keys.erase(shard_key)
	if keys.is_empty():
		_cast_shard_keys_by_spawn_id.erase(spawn_id)
	else:
		_cast_shard_keys_by_spawn_id[spawn_id] = keys

func _combat_input_allowed() -> bool:
	var state := _run_state()
	return (
		bool(state.get("run_active", false))
		and not bool(state.get("death_teardown_complete", false))
		and not bool(state.get("transitioning", false))
	)

func _player() -> CharacterBody3D:
	if not _player_provider.is_valid():
		return null
	var candidate = _player_provider.call()
	if candidate is CharacterBody3D and is_instance_valid(candidate):
		return candidate as CharacterBody3D
	return null

func _ability_kit() -> AbilityComponent:
	if not _ability_kit_provider.is_valid():
		return null
	var candidate = _ability_kit_provider.call()
	if candidate is AbilityComponent and is_instance_valid(candidate):
		return candidate as AbilityComponent
	return null

func _enemy_snapshot() -> Array:
	if not _enemy_snapshot_provider.is_valid():
		return []
	var candidate = _enemy_snapshot_provider.call()
	if candidate is Array:
		return candidate as Array
	if candidate is Dictionary:
		return (candidate as Dictionary).values()
	return []

func _shard_parent() -> Node:
	if not _shard_parent_provider.is_valid():
		return null
	var candidate = _shard_parent_provider.call()
	if candidate is Node and is_instance_valid(candidate):
		return candidate as Node
	return null

func _run_state() -> Dictionary:
	if not _run_state_provider.is_valid():
		return {}
	var candidate = _run_state_provider.call()
	if candidate is Dictionary:
		return candidate as Dictionary
	return {}

func _render_hud() -> void:
	if _render_hud_payloads.is_valid():
		_render_hud_payloads.call()

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)

func _player_facing_direction(active_player: CharacterBody3D) -> Vector3:
	if active_player == null:
		return Vector3(0.0, 0.0, -1.0)

	var motor = active_player.get("motor")
	if motor != null:
		var facing := Vector3(motor.get("facing_direction"))
		if facing.length_squared() > 0.000001:
			return facing.normalized()

	var pivot := active_player.get_node_or_null("VisualPivot") as Node3D
	if pivot != null:
		var visual_forward := -pivot.global_transform.basis.z
		visual_forward.y = 0.0
		if visual_forward.length_squared() > 0.000001:
			return visual_forward.normalized()
	return Vector3(0.0, 0.0, -1.0)

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
