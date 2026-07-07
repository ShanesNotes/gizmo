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
const SwingTimingScript := preload("res://scripts/room_graph/swing_timing.gd")
const CAST_HAND_OFFSET := Vector3(0.0, 1.2, 0.0)
const CAST_IMPACT_OFFSET := Vector3(0.0, 1.1, 0.0)
const SOFT_LOCK_RANGE_MULTIPLIER: float = 1.15
const SOFT_LOCK_HALF_ANGLE_DEGREES: float = 60.0

var melee_range: float = 2.0
var melee_arc_degrees: float = 120.0
var special_range: float = 2.75
var special_arc_degrees: float = 160.0
var cast_range: float = 8.0
var cast_arc_degrees: float = 20.0
var soft_lock_enabled: bool = true

var _player_provider: Callable = Callable()
var _ability_kit_provider: Callable = Callable()
var _enemy_snapshot_provider: Callable = Callable()
var _shard_parent_provider: Callable = Callable()
var _run_state_provider: Callable = Callable()
var _render_hud_payloads: Callable = Callable()
var _bound_kit: AbilityComponent = null
## Animation-led swings (playtest 2): each attack/special holds here for its
## SwingTiming contact delay so the damage frame IS the clip's contact frame.
var _pending_swings: Array[Dictionary] = []
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
	soft_lock_enabled = bool(context.get("soft_lock_enabled", soft_lock_enabled))
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
	_connect_ability_signal(_bound_kit.cooldown_started, Callable(self, "_on_player_cooldown_started"))
	_connect_ability_signal(_bound_kit.cooldown_finished, Callable(self, "_on_player_cooldown_finished"))

func reset_for_run() -> void:
	_clear_cast_shards(false)
	_pending_swings.clear()
	_cast_shard_sequence = 0

func clear_for_room_cleanup(reclaim: bool) -> void:
	_clear_cast_shards(reclaim)
	_pending_swings.clear()

func _physics_process(delta: float) -> void:
	tick_pending_swings(delta)

## Deterministic swing clock (public so headless suites can drive it). A swing
## fires when its contact delay elapses; it is dropped if combat input is no
## longer allowed or the player dash-cancelled out of the windup.
func tick_pending_swings(delta: float) -> void:
	if _pending_swings.is_empty():
		return
	var step := maxf(delta, 0.0)
	var due: Array[Dictionary] = []
	for swing in _pending_swings:
		swing["time_remaining"] = float(swing["time_remaining"]) - step
		if float(swing["time_remaining"]) <= 0.0:
			due.append(swing)
	for swing in due:
		_pending_swings.erase(swing)
		_fire_swing(swing)

func _schedule_swing(
	damage: float,
	attack_range: float,
	arc_degrees: float,
	contact_delay: float,
	opts: Dictionary = {}
) -> void:
	if contact_delay <= 0.0:
		_fire_swing({
			"damage": damage,
			"range": attack_range,
			"arc": arc_degrees,
			"opts": opts.duplicate(true),
		})
		return
	_pending_swings.append({
		"time_remaining": contact_delay,
		"damage": damage,
		"range": attack_range,
		"arc": arc_degrees,
		"opts": opts.duplicate(true),
	})

func _fire_swing(swing: Dictionary) -> void:
	if not _combat_input_allowed():
		return
	var kit := _ability_kit()
	if kit != null and kit.current_action_state() == PlayerActionStateMachine.ActionState.DASH:
		return
	var opts: Dictionary = swing.get("opts", {})
	var hits := _resolve_player_arc_damage(
		float(swing["damage"]),
		float(swing["range"]),
		float(swing["arc"]),
		opts
	)
	if hits > 0:
		_notify_audio_event(&"melee_hit")

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
	_disconnect_ability_signal(_bound_kit.cooldown_started, Callable(self, "_on_player_cooldown_started"))
	_disconnect_ability_signal(_bound_kit.cooldown_finished, Callable(self, "_on_player_cooldown_finished"))

func _disconnect_ability_signal(ability_signal: Signal, callback: Callable) -> void:
	if ability_signal.is_connected(callback):
		ability_signal.disconnect(callback)

func _on_player_dash_started(_direction: Vector3, _speed: float, _duration: float) -> void:
	if not _combat_input_allowed():
		return
	_notify_audio_event(&"dash_whoosh")
	_notify_audio_event(&"gizmo_chirp_effort")

func _on_player_attack_started(step: int, damage: float) -> void:
	if not _combat_input_allowed():
		return
	var contact_delay := SwingTimingScript.melee_contact_delay(step)
	_soft_lock_player_facing(melee_range)
	_spawn_swing_read(melee_range, melee_arc_degrees, contact_delay, -1.0 if step == 2 else 1.0)
	_apply_melee_lunge()
	_schedule_swing(damage, melee_range, melee_arc_degrees, contact_delay, _damage_pop_opts(&"attack", damage, step))

## HUD dash-slot cooldown surface: the payload's "ready" flag only reads right
## if the HUD re-renders exactly when a cooldown starts and ends.
func _on_player_cooldown_started(_ability: Ability, _duration: float) -> void:
	_render_hud()

func _on_player_cooldown_finished(_ability_id: StringName) -> void:
	_render_hud()

## Small forward lunge on melee commit (feel pass): routed through the motor's
## dash channel so displacement stays collision-safe via move_and_slide. A real
## dash always wins — the lunge never overrides an active dash burst.
func _apply_melee_lunge() -> void:
	var active_player := _player()
	if active_player == null:
		return
	var motor = active_player.get("motor")
	if motor == null or not motor.has_method("begin_dash"):
		return
	if bool(motor.call("is_dashing")):
		return
	motor.call("begin_dash", _player_facing_direction(active_player), 3.5, 0.08)

func _on_player_special_started(potency: float) -> void:
	if not _combat_input_allowed():
		return
	var contact_delay := SwingTimingScript.special_contact_delay()
	_soft_lock_player_facing(special_range)
	_spawn_swing_read(special_range, special_arc_degrees, contact_delay, 1.0)
	_schedule_swing(potency, special_range, special_arc_degrees, contact_delay, _damage_pop_opts(&"special", potency))

func _on_player_cast_started(potency: float) -> void:
	if not _combat_input_allowed():
		# The kit consumed ammo before emitting; a gated cast must refund or
		# the stone is silently stranded (HZ-074 audit HIGH).
		_refund_cast_ammo()
		return
	_notify_audio_event(&"cast_shot")
	_resolve_player_cast_damage(potency, _damage_pop_opts(&"cast", potency))

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
	CombatEffectsScript.spawn_surge_shockwave(_shard_parent(), center, radius)
	CombatEffectsScript.shake_active_camera(active_player, 0.18, 0.12)
	var snapshot: Array = _enemy_snapshot()
	var opts := _damage_pop_opts(&"surge", damage)
	for candidate in snapshot:
		if not (candidate is GreyboxEnemy) or not is_instance_valid(candidate):
			continue
		var enemy := candidate as GreyboxEnemy
		if enemy.is_dead() or enemy.is_spawning() or _xz_distance(enemy.global_position, center) > radius:
			continue
		enemy.stagger(stagger_seconds)
		enemy.take_damage(damage, false, opts)
	_render_hud()

## Swing read: an arc trail that sweeps over the clip's windup->contact
## window, alternating direction with the combo so step 2 visibly returns.
func _spawn_swing_read(swing_range: float, arc_degrees: float, sweep_seconds: float, sweep_sign: float) -> void:
	var active_player := _player()
	if active_player == null:
		return
	CombatEffectsScript.spawn_swing_trail(
		_shard_parent(),
		active_player.global_position,
		_player_facing_direction(active_player),
		swing_range,
		arc_degrees,
		sweep_seconds,
		sweep_sign
	)

func _soft_lock_player_facing(ability_range: float) -> void:
	if not soft_lock_enabled:
		return
	var active_player := _player()
	if active_player == null:
		return
	var motor = active_player.get("motor")
	if not (motor is Object):
		return
	var current_forward := _player_facing_direction(active_player)
	var target_direction := _soft_lock_direction_to_nearest_enemy(
		active_player.global_position,
		current_forward,
		ability_range * SOFT_LOCK_RANGE_MULTIPLIER
	)
	if target_direction == Vector3.ZERO:
		return
	(motor as Object).set("facing_direction", target_direction)

func _soft_lock_direction_to_nearest_enemy(center: Vector3, forward: Vector3, max_range: float) -> Vector3:
	if max_range <= 0.0:
		return Vector3.ZERO
	var flat_forward := _flat_forward_or_default(forward)
	var minimum_dot := cos(deg_to_rad(SOFT_LOCK_HALF_ANGLE_DEGREES))
	var best_direction := Vector3.ZERO
	var best_distance := INF
	for enemy in _damageable_enemy_snapshot():
		var offset := Vector3(enemy.global_position.x - center.x, 0.0, enemy.global_position.z - center.z)
		var distance := offset.length()
		if distance <= 0.000001 or distance > max_range:
			continue
		var direction := offset / distance
		if flat_forward.dot(direction) < minimum_dot:
			continue
		if distance < best_distance:
			best_distance = distance
			best_direction = direction
	return best_direction

func _resolve_player_arc_damage(
	damage: float,
	attack_range: float,
	arc_degrees: float,
	opts: Dictionary = {}
) -> int:
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
		enemy.take_damage(damage, true, opts)
		hits += 1
	_render_hud()
	return hits

func _resolve_player_cast_damage(damage: float, opts: Dictionary = {}) -> GreyboxEnemy:
	var active_player := _player()
	if active_player == null:
		# Post-consume abort: never strand the stone (HZ-074 audit HIGH).
		_refund_cast_ammo()
		_render_hud()
		return null
	var center := active_player.global_position
	var forward := _player_facing_direction(active_player)
	var target := _first_enemy_in_cast_corridor(center, forward)
	var cast_origin := center + CAST_HAND_OFFSET
	if target == null:
		var miss_position := center + _flat_forward_or_default(forward) * maxf(cast_range, 0.0)
		CombatEffectsScript.spawn_cast_bolt(_shard_parent(), cast_origin, miss_position + CAST_IMPACT_OFFSET)
		_register_cast_shard("", miss_position)
		_render_hud()
		return null

	CombatEffectsScript.spawn_cast_bolt(_shard_parent(), cast_origin, target.global_position + CAST_IMPACT_OFFSET)
	_register_cast_shard(target.spawn_id, target.global_position, target)
	_notify_audio_event(&"cast_lodge")
	if damage > 0.0:
		target.take_damage(damage, true, opts)
	_render_hud()
	return target

func _damage_pop_opts(ability_id: StringName, current_damage: float, step: int = 0) -> Dictionary:
	return {
		"crit": false,
		"boosted": _damage_exceeds_base(ability_id, current_damage, step),
	}

func _damage_exceeds_base(ability_id: StringName, current_damage: float, step: int = 0) -> bool:
	var base_damage := _base_damage_for(ability_id, step)
	return base_damage >= 0.0 and current_damage > base_damage + 0.001

func _base_damage_for(ability_id: StringName, step: int = 0) -> float:
	var kit := _ability_kit()
	if kit == null and _bound_kit != null and is_instance_valid(_bound_kit):
		kit = _bound_kit
	if kit == null:
		return -1.0
	var ability := kit.get_ability(ability_id)
	if ability == null:
		return -1.0
	if ability.has_method("damage_for_step"):
		return float(ability.call("damage_for_step", step))
	if ability_id == &"surge":
		var surge_damage = ability.get("damage")
		if surge_damage != null:
			return float(surge_damage)
	return ability.potency

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

func _register_cast_shard(owner_spawn_id: String, position: Vector3, owner_enemy: Node3D = null) -> String:
	_cast_shard_sequence += 1
	var shard_key := "cast_shard:%d" % _cast_shard_sequence
	var pickup := _spawn_cast_shard_pickup(shard_key, owner_spawn_id, position, owner_enemy)
	_cast_shards_by_key[shard_key] = {
		"spawn_id": owner_spawn_id,
		"pickup": pickup,
	}
	if owner_spawn_id != "":
		var keys: Array = _cast_shard_keys_by_spawn_id.get(owner_spawn_id, [])
		keys.append(shard_key)
		_cast_shard_keys_by_spawn_id[owner_spawn_id] = keys
	return shard_key

func _spawn_cast_shard_pickup(shard_key: String, owner_spawn_id: String, position: Vector3, owner_enemy: Node3D = null) -> Area3D:
	var parent := _shard_parent()
	if parent == null:
		return null

	var pickup := CastShardPickupScript.new() as Area3D
	pickup.name = "CastShardPickup%d" % _cast_shard_sequence
	pickup.call("configure", shard_key, owner_spawn_id, owner_enemy)

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
	if owner_enemy != null and is_instance_valid(owner_enemy):
		pickup.global_position = owner_enemy.global_position + CAST_IMPACT_OFFSET
	else:
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
	_notify_audio_event(&"cast_reclaim")
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
	var pickup := record.get("pickup") as Node
	if pickup != null and is_instance_valid(pickup) and pickup.has_method(&"release_owner_tracking"):
		pickup.call(&"release_owner_tracking", true)
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
