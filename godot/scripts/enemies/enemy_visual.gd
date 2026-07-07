class_name EnemyVisual
extends Node3D

const ARCHETYPE_CHAFF := "chaff"
const ARCHETYPE_BRUISER := "bruiser"
const ARCHETYPE_ELITE := "elite"

const MODEL_SCENES := {
	ARCHETYPE_CHAFF: preload("res://assets/enemies/chaff_drone.glb"),
	ARCHETYPE_BRUISER: preload("res://assets/enemies/bruiser_unit.glb"),
	ARCHETYPE_ELITE: preload("res://assets/enemies/elite_enforcer.glb"),
}

const MODEL_NAMES := {
	ARCHETYPE_CHAFF: "ChaffDroneModel",
	ARCHETYPE_BRUISER: "BruiserUnitModel",
	ARCHETYPE_ELITE: "EliteEnforcerModel",
}

@export var placeholder_path: NodePath = NodePath("Capsule")
@export var fallback_model_scale: float = 1.0
@export var model_scale_by_archetype: Dictionary = {
	ARCHETYPE_CHAFF: 0.9,
	ARCHETYPE_BRUISER: 1.35,
	ARCHETYPE_ELITE: 1.75,
}
@export var model_ground_offset_by_archetype: Dictionary = {
	ARCHETYPE_CHAFF: 0.53,
	ARCHETYPE_BRUISER: 1.35,
	ARCHETYPE_ELITE: 1.75,
}

## Motion identity per archetype (cosmetic only — reads parent velocity, never
## writes gameplay state). Chaff hovers busily and spins; bruiser lumbers with a
## heavy stomp roll; elite glides dead-level with cold, economical banking —
## the hollow-machine contrast against Gizmo's eager patter.
const MOTION_PROFILES := {
	ARCHETYPE_CHAFF: {
		"bob_amplitude": 0.06, "bob_frequency_hz": 2.2, "stomp": false,
		"spin_rad_per_s": 1.6, "bank_lean": 0.0, "recoil_strength": 0.28,
	},
	ARCHETYPE_BRUISER: {
		"bob_amplitude": 0.09, "bob_frequency_hz": 1.1, "stomp": true,
		"spin_rad_per_s": 0.0, "bank_lean": 0.05, "recoil_strength": 0.10,
	},
	ARCHETYPE_ELITE: {
		"bob_amplitude": 0.0, "bob_frequency_hz": 0.0, "stomp": false,
		"spin_rad_per_s": 0.0, "bank_lean": 0.16, "recoil_strength": 0.06,
	},
}
const RECOIL_DURATION := 0.22

var _model_instance: Node3D = null
var _model_base_position: Vector3 = Vector3.ZERO
var _motion_time: float = 0.0
var _spin_angle: float = 0.0
var _recoil_remaining: float = 0.0

func _ready() -> void:
	var parent_node := get_parent()
	if parent_node != null and parent_node.has_signal(&"damage_taken") \
			and not parent_node.damage_taken.is_connected(_on_parent_damage_taken):
		parent_node.damage_taken.connect(_on_parent_damage_taken)
	await get_tree().process_frame
	refresh_visual()

func _physics_process(delta: float) -> void:
	update_motion(delta)

func update_motion(delta: float) -> void:
	if _model_instance == null:
		return
	var archetype := _parent_archetype()
	var profile: Dictionary = MOTION_PROFILES.get(archetype, {})
	if profile.is_empty():
		return
	var safe_delta: float = maxf(delta, 0.0)
	var move_amount := _parent_move_amount()
	_motion_time += safe_delta * (0.6 + 0.8 * move_amount)

	var bob_amplitude := float(profile["bob_amplitude"])
	var bob_phase := _motion_time * TAU * float(profile["bob_frequency_hz"])
	var bob := 0.0
	if bob_amplitude > 0.0:
		if bool(profile["stomp"]):
			bob = bob_amplitude * absf(sin(bob_phase)) * move_amount
		else:
			bob = bob_amplitude * sin(bob_phase)

	_spin_angle = wrapf(
		_spin_angle + float(profile["spin_rad_per_s"]) * safe_delta * (0.4 + 0.6 * move_amount),
		-TAU, TAU
	)
	var bank := -_parent_local_velocity_x() * float(profile["bank_lean"])

	_recoil_remaining = maxf(0.0, _recoil_remaining - safe_delta / RECOIL_DURATION)
	var recoil_envelope := _recoil_remaining * _recoil_remaining
	var recoil_kick := float(profile["recoil_strength"]) * recoil_envelope

	_model_instance.position = _model_base_position + Vector3(0.0, bob, -recoil_kick)
	_model_instance.rotation = Vector3(-recoil_kick * 0.8, _spin_angle, bank)

func play_hit_recoil() -> void:
	_recoil_remaining = 1.0

func _on_parent_damage_taken(_spawn_id: String, _amount: float, _charges_spark: bool) -> void:
	play_hit_recoil()

func _parent_move_amount() -> float:
	var parent_node := get_parent()
	if not (parent_node is CharacterBody3D):
		return 0.0
	var body := parent_node as CharacterBody3D
	var speed := Vector3(body.velocity.x, 0.0, body.velocity.z).length()
	var reference: float = maxf(float(parent_node.get("move_speed")), 0.001)
	return clampf(speed / reference, 0.0, 1.0)

func _parent_local_velocity_x() -> float:
	var parent_node := get_parent()
	if not (parent_node is CharacterBody3D):
		return 0.0
	var body := parent_node as CharacterBody3D
	var velocity := Vector3(body.velocity.x, 0.0, body.velocity.z)
	if velocity.length_squared() <= 0.000001:
		return 0.0
	var reference: float = maxf(float(parent_node.get("move_speed")), 0.001)
	var local_velocity := global_transform.basis.inverse() * velocity
	return clampf(local_velocity.x / reference, -1.0, 1.0)

func refresh_visual() -> void:
	var archetype := _parent_archetype()
	if not MODEL_SCENES.has(archetype):
		_clear_model()
		_set_placeholder_visible(true)
		return

	_set_placeholder_visible(false)
	_instance_model(archetype)

func _parent_archetype() -> String:
	var parent_node := get_parent()
	if parent_node == null:
		return ""
	return String(parent_node.get("archetype"))

func _instance_model(archetype: String) -> void:
	_clear_model()
	var scene := MODEL_SCENES.get(archetype) as PackedScene
	if scene == null:
		_set_placeholder_visible(true)
		return
	var instance := scene.instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		_set_placeholder_visible(true)
		return

	_model_instance = instance as Node3D
	_model_instance.name = String(MODEL_NAMES.get(archetype, "EnemyModel"))
	add_child(_model_instance)
	move_child(_model_instance, 0)
	var model_scale := float(model_scale_by_archetype.get(archetype, fallback_model_scale))
	_model_instance.scale = Vector3.ONE * model_scale
	_model_instance.position = Vector3(
		0.0,
		float(model_ground_offset_by_archetype.get(archetype, 0.0)),
		0.0
	)
	_model_base_position = _model_instance.position
	_motion_time = 0.0
	_spin_angle = 0.0
	_recoil_remaining = 0.0

func _clear_model() -> void:
	var placeholder := get_node_or_null(placeholder_path)
	for child in get_children():
		if child != placeholder:
			child.queue_free()
	_model_instance = null

func _set_placeholder_visible(visible: bool) -> void:
	var placeholder := get_node_or_null(placeholder_path) as Node3D
	if placeholder != null:
		placeholder.visible = visible
