class_name GreyboxEnemy
extends CharacterBody3D

signal damage_event(event: Dictionary)
signal damage_taken(spawn_id: String, amount: float, charges_spark: bool)
signal died(spawn_id: String)

const EnemyArchetypesScript := preload("res://scripts/enemies/enemy_archetypes.gd")
const CombatEffectsScript := preload("res://scripts/room_graph/combat_effects.gd")
const EnemyBrainScript := preload("res://scripts/enemies/enemy_brain.gd")

@export var archetype: String = EnemyArchetypesScript.ARCHETYPE_CHAFF
@export var spawn_id: String = ""
@export_range(0.0, 5.0, 0.05) var spawn_windup: float = 0.8
@export var turn_speed: float = 14.0

@onready var visual_pivot: Node3D = $VisualPivot

var max_hp: float = 0.0
var hp: float = 0.0
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
	_current_stats = EnemyArchetypesScript.stats_for(p_archetype)
	archetype = String(_current_stats["archetype"])
	spawn_id = String(p_spawn_id)
	max_hp = float(_current_stats["max_hp"])
	hp = max_hp
	move_speed = float(_current_stats["move_speed"])
	contact_radius = float(_current_stats["contact_radius"])
	attack_release_radius = float(_current_stats["attack_release_radius"])
	melee_damage = int(_current_stats["damage"])
	attack_windup = float(_current_stats["attack_windup"])
	attack_recovery = float(_current_stats["attack_recovery"])
	brain.configure(_current_stats)
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
		CombatEffectsScript.spawn_damage_number(
			get_parent(),
			Vector3(target_position.x, target_position.y + 2.1, target_position.z),
			float(event.get("damage", 0)),
			CombatEffectsScript.PLAYER_HIT_NUMBER_COLOR
		)
	return result

func take_damage(amount: float, charges_spark: bool = true) -> float:
	if _dead or amount <= 0.0:
		return hp

	var before := hp
	hp = maxf(0.0, hp - amount)
	var applied := before - hp
	if applied > 0.0:
		damage_taken.emit(spawn_id, applied, charges_spark)
		CombatEffectsScript.flash_hit(visual_pivot)
		CombatEffectsScript.spawn_damage_number(
			get_parent(),
			global_position + Vector3(0.0, 1.9, 0.0),
			applied
		)
		CombatEffectsScript.hit_stop(self)
	if hp <= 0.0 and not _dead:
		_dead = true
		velocity = Vector3.ZERO
		died.emit(spawn_id)
		_notify_audio_event(&"enemy_death")
		CombatEffectsScript.spawn_burst_ring(
			get_parent(),
			global_position,
			1.1,
			Color(1.0, 0.45, 0.2, 0.85)
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

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)
