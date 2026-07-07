class_name GreyboxEnemy
extends CharacterBody3D

signal damage_event(event: Dictionary)
signal damage_taken(spawn_id: String, amount: float, charges_spark: bool)
signal died(spawn_id: String)

const EnemyArchetypesScript := preload("res://scripts/enemies/enemy_archetypes.gd")
const CombatEffectsScript := preload("res://scripts/room_graph/combat_effects.gd")
const EnemyBrainScript := preload("res://scripts/enemies/enemy_brain.gd")

const SHIELDED_OVERSHIELD_FRACTION := 0.35
const FRENZIED_SPEED_MULTIPLIER := 1.4
const FRENZIED_WINDUP_MULTIPLIER := 0.75
const FRENZIED_HP_MULTIPLIER := 0.8
const WARDED_RADIUS_METERS := 6.0
const WARDED_DAMAGE_MULTIPLIER := 0.5

@export var archetype: String = EnemyArchetypesScript.ARCHETYPE_CHAFF
@export var spawn_id: String = ""
@export_range(0.0, 5.0, 0.05) var spawn_windup: float = 0.8
@export var turn_speed: float = 14.0

@onready var visual_pivot: Node3D = $VisualPivot

var max_hp: float = 0.0
var hp: float = 0.0
var affix: StringName = EnemyArchetypesScript.AFFIX_NONE
var max_overshield: float = 0.0
var overshield: float = 0.0
var move_speed: float = 0.0
var contact_radius: float = 1.0
var attack_release_radius: float = 1.25
var melee_damage: int = 1
var attack_windup: float = 0.35
var attack_recovery: float = 0.65
var chase_target: Node3D = null
var brain = EnemyBrainScript.new()

var _configured := false
var _dead := false
var _current_stats: Dictionary = {}
var _spawn_windup_remaining: float = 0.0

func _enter_tree() -> void:
	add_to_group(&"enemies")
	set_physics_process(true)

func _exit_tree() -> void:
	velocity = Vector3.ZERO
	set_physics_process(false)

func _ready() -> void:
	if not _configured:
		configure(archetype, spawn_id)
	_apply_visuals()

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		velocity = Vector3.ZERO
		set_physics_process(false)
		return
	if _dead:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if _is_spawning():
		_tick_spawn_windup(delta)
		brain.tick_stagger(delta)
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if chase_target == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var result: Dictionary = tick_chase(chase_target.global_position, delta)
	move_and_slide()
	_face_direction(Vector3(result["direction"]), delta)

func configure(p_archetype: String, p_spawn_id: String) -> void:
	configure_from_stats(EnemyArchetypesScript.stats_for(p_archetype), p_spawn_id)

func configure_from_stats(stats: Dictionary, p_spawn_id: String) -> void:
	_current_stats = _stats_with_affix_deltas(stats)
	archetype = String(_current_stats["archetype"])
	spawn_id = String(p_spawn_id)
	max_hp = float(_current_stats["max_hp"])
	hp = max_hp
	affix = EnemyArchetypesScript.normalize_affix(StringName(String(_current_stats.get("affix", ""))))
	max_overshield = max_hp * SHIELDED_OVERSHIELD_FRACTION if affix == EnemyArchetypesScript.AFFIX_SHIELDED else 0.0
	overshield = max_overshield
	move_speed = float(_current_stats["move_speed"])
	contact_radius = float(_current_stats["contact_radius"])
	attack_release_radius = float(_current_stats["attack_release_radius"])
	melee_damage = int(_current_stats["damage"])
	attack_windup = float(_current_stats["attack_windup"])
	attack_recovery = float(_current_stats["attack_recovery"])
	brain.configure(_current_stats)
	# Desync orbits/pauses across a pack, deterministically per spawn.
	brain.set_behavior_seed(hash(spawn_id))
	velocity = Vector3.ZERO
	_spawn_windup_remaining = maxf(spawn_windup, 0.0)
	_dead = false
	_configured = true
	_apply_visuals()

func set_chase_target(target: Node3D) -> void:
	chase_target = target

func clear_chase_target() -> void:
	chase_target = null
	velocity = Vector3.ZERO
	brain.reset_attack()

func stagger(duration: float) -> void:
	if affix == EnemyArchetypesScript.AFFIX_SHIELDED and overshield > 0.0:
		return
	brain.stagger(duration)
	velocity = Vector3.ZERO
	CombatEffectsScript.apply_stagger_read(self, visual_pivot, duration)

## Cosmetic corpse removal (HZ-084): all gameplay bookkeeping must be done
## before calling; this only replaces an instant queue_free with a pop.
func play_death_pop_then_free() -> void:
	CombatEffectsScript.death_pop(self)

func is_staggered() -> bool:
	return brain.is_staggered()

func tick_chase(target_position: Vector3, delta: float) -> Dictionary:
	if _dead:
		velocity = Vector3.ZERO
		return {
			"velocity": velocity,
			"direction": Vector3.ZERO,
			"distance": 0.0,
			"in_contact": false,
			"attack_state": brain.attack_state(),
			"damage_event": {},
		}
	if _is_spawning():
		_tick_spawn_windup(delta)
		velocity = Vector3.ZERO
		brain.tick_stagger(delta)
		brain.reset_attack()
		var steering := EnemyBrainScript.chase_steering(global_position, target_position, 0.0, contact_radius, 0.0)
		return {
			"velocity": velocity,
			"direction": steering["direction"],
			"distance": steering["distance"],
			"in_contact": steering["in_contact"],
			"attack_state": brain.attack_state(),
			"damage_event": {},
		}

	var result: Dictionary = brain.step(global_position, target_position, delta)
	velocity = Vector3(result["velocity"])
	var raw_event: Dictionary = result["damage_event"]
	if not raw_event.is_empty():
		var event := raw_event.duplicate(true)
		event["spawn_id"] = spawn_id
		event["archetype"] = archetype
		event["source_position"] = global_position
		damage_event.emit(event)
		result["damage_event"] = event
		_spawn_damage_pop(
			Vector3(target_position.x, target_position.y + 2.1, target_position.z),
			float(event.get("damage", 0)),
			{"player_hit": true}
		)
	return result

func take_damage(amount: float, charges_spark: bool = true, opts: Dictionary = {}) -> float:
	if _dead or amount <= 0.0:
		return hp

	var incoming := _modified_incoming_damage(amount)
	if incoming <= 0.0:
		return hp
	var hp_damage := incoming
	if overshield > 0.0:
		var absorbed := minf(overshield, hp_damage)
		overshield = maxf(0.0, overshield - absorbed)
		hp_damage -= absorbed
		if absorbed > 0.0:
			_spawn_damage_pop(
				global_position + Vector3(0.0, 2.15, 0.0),
				absorbed,
				_shielded_pop_opts(opts)
			)
		if overshield <= 0.00001:
			_break_overshield()
		if hp_damage <= 0.00001:
			return hp

	var before := hp
	hp = maxf(0.0, hp - hp_damage)
	var applied := before - hp
	if applied > 0.0:
		damage_taken.emit(spawn_id, applied, charges_spark)
		CombatEffectsScript.flash_hit(visual_pivot)
		_spawn_damage_pop(
			global_position + Vector3(0.0, 1.9, 0.0),
			applied,
			opts
		)
		CombatEffectsScript.hit_stop(self)
	if hp <= 0.0 and not _dead:
		_dead = true
		velocity = Vector3.ZERO
		died.emit(spawn_id)
		_notify_audio_event(&"enemy_death")
		CombatEffectsScript.spawn_death_collapse(
			get_parent(),
			global_position,
			float(_current_stats.get("visual_scale", 1.0))
		)
		CombatEffectsScript.shake_active_camera(self)
	return hp

func is_dead() -> bool:
	return _dead

func is_spawning() -> bool:
	return _is_spawning()

func spawn_windup_remaining() -> float:
	return _spawn_windup_remaining

func _apply_visuals() -> void:
	if visual_pivot == null or _current_stats.is_empty():
		return
	var visual_scale := float(_current_stats.get("visual_scale", 1.0))
	visual_pivot.scale = Vector3.ONE * visual_scale
	_set_visual_affix(affix)

func _stats_with_affix_deltas(stats: Dictionary) -> Dictionary:
	var result := stats.duplicate(true)
	var normalized_archetype := EnemyArchetypesScript.normalize_archetype(String(result.get("archetype", archetype)))
	result["archetype"] = normalized_archetype
	var normalized_affix := EnemyArchetypesScript.normalize_affix(StringName(String(result.get("affix", ""))))
	if normalized_archetype != EnemyArchetypesScript.ARCHETYPE_ELITE:
		normalized_affix = EnemyArchetypesScript.AFFIX_NONE
	result["affix"] = String(normalized_affix)
	match normalized_affix:
		EnemyArchetypesScript.AFFIX_FRENZIED:
			result["max_hp"] = float(result.get("max_hp", 0.0)) * FRENZIED_HP_MULTIPLIER
			result["move_speed"] = float(result.get("move_speed", 0.0)) * FRENZIED_SPEED_MULTIPLIER
			result["attack_windup"] = float(result.get("attack_windup", 0.0)) * FRENZIED_WINDUP_MULTIPLIER
		_:
			pass
	return result

func _modified_incoming_damage(amount: float) -> float:
	var incoming := amount
	if affix == EnemyArchetypesScript.AFFIX_WARDED and _has_living_ward_neighbor():
		incoming *= WARDED_DAMAGE_MULTIPLIER
	return incoming

func _has_living_ward_neighbor() -> bool:
	if not is_inside_tree():
		return false
	for candidate in get_tree().get_nodes_in_group(&"enemies"):
		if candidate == self:
			continue
		if not (candidate is GreyboxEnemy):
			continue
		var enemy := candidate as GreyboxEnemy
		if not is_instance_valid(enemy) or enemy.is_dead():
			continue
		if _xz_distance(global_position, enemy.global_position) <= WARDED_RADIUS_METERS:
			return true
	return false

func _break_overshield() -> void:
	overshield = 0.0
	max_overshield = 0.0
	_set_visual_affix(EnemyArchetypesScript.AFFIX_NONE)
	CombatEffectsScript.spawn_surge_shockwave(get_parent(), global_position, 1.2)
	_notify_audio_event(&"elite_shield_break")

func _shielded_pop_opts(opts: Dictionary) -> Dictionary:
	var shield_opts := opts.duplicate(true)
	shield_opts["shielded"] = true
	return shield_opts

func _set_visual_affix(affix_id: StringName) -> void:
	if visual_pivot != null and visual_pivot.has_method(&"apply_affix_visual"):
		visual_pivot.call(&"apply_affix_visual", affix_id)

func _face_direction(direction: Vector3, delta: float) -> void:
	if visual_pivot == null:
		return
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() <= 0.000001:
		return
	flat_direction = flat_direction.normalized()
	var target_yaw := atan2(flat_direction.x, flat_direction.z)
	var turn_weight := 1.0 - exp(-turn_speed * maxf(delta, 0.0))
	visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_yaw, turn_weight)

func _is_spawning() -> bool:
	return not _dead and _spawn_windup_remaining > 0.0

func _tick_spawn_windup(delta: float) -> void:
	_spawn_windup_remaining = maxf(0.0, _spawn_windup_remaining - maxf(delta, 0.0))
	if _spawn_windup_remaining <= 0.00001:
		_spawn_windup_remaining = 0.0

func _spawn_damage_pop(origin: Vector3, amount: float, opts: Dictionary = {}) -> void:
	if is_inside_tree():
		var damage_numbers := get_tree().get_first_node_in_group("damage_numbers")
		if damage_numbers != null and damage_numbers.has_method("pop"):
			damage_numbers.call("pop", origin, amount, opts)
			return
	CombatEffectsScript.spawn_damage_number(
		get_parent(),
		origin,
		amount,
		_damage_pop_fallback_color(opts)
	)

func _damage_pop_fallback_color(opts: Dictionary) -> Color:
	if bool(opts.get("shielded", false)):
		return CombatEffectsScript.SHIELDED_NUMBER_COLOR
	if bool(opts.get("player_hit", false)):
		return CombatEffectsScript.PLAYER_HIT_NUMBER_COLOR
	if bool(opts.get("crit", false)):
		return CombatEffectsScript.FX_IDENTITY
	if bool(opts.get("boosted", false)):
		return CombatEffectsScript.FX_IDENTITY_RIM
	return CombatEffectsScript.DAMAGE_NUMBER_COLOR

func _xz_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)
