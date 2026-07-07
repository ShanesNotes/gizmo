class_name EnemyVisual
extends Node3D

const ARCHETYPE_CHAFF := "chaff"
const ARCHETYPE_BRUISER := "bruiser"
const ARCHETYPE_ELITE := "elite"

## Bruiser/elite load the Meshy-rigged GLBs (mesh + 24-bone rig + authored
## clips; see *.provenance.json) so EnemyAnimationController can pose bones.
## Chaff stays the unrigged drone — its identity is procedural.
const MODEL_SCENES := {
	ARCHETYPE_CHAFF: preload("res://assets/enemies/chaff_drone.glb"),
	ARCHETYPE_BRUISER: preload("res://assets/enemies/bruiser_unit_rigged.glb"),
	ARCHETYPE_ELITE: preload("res://assets/enemies/elite_enforcer_rigged.glb"),
}

const MODEL_NAMES := {
	ARCHETYPE_CHAFF: "ChaffDroneModel",
	ARCHETYPE_BRUISER: "BruiserUnitModel",
	ARCHETYPE_ELITE: "EliteEnforcerModel",
}

@export var placeholder_path: NodePath = NodePath("Capsule")
@export var fallback_model_scale: float = 1.0
## Rigged bruiser (2.4m) / elite (3.2m) meshes stand feet-at-origin, so their
## ground offset is 0; the scales keep the silhouette heights the unrigged
## center-origin meshes established (2.7m / 3.5m before the pivot scale).
@export var model_scale_by_archetype: Dictionary = {
	ARCHETYPE_CHAFF: 0.9,
	ARCHETYPE_BRUISER: 1.125,
	ARCHETYPE_ELITE: 1.09,
}
@export var model_ground_offset_by_archetype: Dictionary = {
	ARCHETYPE_CHAFF: 0.53,
	ARCHETYPE_BRUISER: 0.0,
	ARCHETYPE_ELITE: 0.0,
}

## Motion identity per archetype (cosmetic only — reads parent velocity, never
## writes gameplay state). Chaff hovers busily and spins; bruiser lumbers with a
## heavy stomp roll; elite glides dead-level with cold, economical banking —
## the hollow-machine contrast against Gizmo's eager patter.
## windup_wobble: aggression shiver (roll radians) while the brain winds up an
## attack — chaff-only; bruiser/elite telegraph skeletally via their attack
## clips. death: "tumble" spins the chaff drone out of the air; "freeze" holds
## the model level so the rigged death clips own the fall.
const MOTION_PROFILES := {
	ARCHETYPE_CHAFF: {
		"bob_amplitude": 0.06, "bob_frequency_hz": 2.2, "stomp": false,
		"spin_rad_per_s": 1.6, "bank_lean": 0.10, "recoil_strength": 0.28,
		"windup_wobble": 0.14, "death": "tumble",
	},
	ARCHETYPE_BRUISER: {
		"bob_amplitude": 0.09, "bob_frequency_hz": 1.1, "stomp": true,
		"spin_rad_per_s": 0.0, "bank_lean": 0.05, "recoil_strength": 0.10,
		"windup_wobble": 0.0, "death": "freeze",
	},
	ARCHETYPE_ELITE: {
		"bob_amplitude": 0.0, "bob_frequency_hz": 0.0, "stomp": false,
		"spin_rad_per_s": 0.0, "bank_lean": 0.16, "recoil_strength": 0.06,
		"windup_wobble": 0.0, "death": "freeze",
	},
}
const RECOIL_DURATION := 0.22
const WINDUP_WOBBLE_HZ := 9.0
const CHAFF_TUMBLE_SINK := 0.45
const AFFIX_FRENZIED: StringName = &"frenzied"
const AFFIX_SHIELDED: StringName = &"shielded"
const AFFIX_WARDED: StringName = &"warded"

var _model_instance: Node3D = null
var _model_base_position: Vector3 = Vector3.ZERO
var _motion_time: float = 0.0
var _affix_time: float = 0.0
var _affix_id: StringName = &""
var _affix_material: StandardMaterial3D = null
var _spin_angle: float = 0.0
var _recoil_remaining: float = 0.0
var _windup_amount: float = 0.0
var _death_time: float = 0.0

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
	if _parent_is_dead():
		_death_time += safe_delta
		_apply_death_motion(profile, safe_delta)
		return
	_tick_affix_pulse(safe_delta)
	_death_time = 0.0
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

	# Aggression shiver while the brain winds up (chaff): the drone vibrates
	# with intent before it bites — the telegraph for an archetype with no rig.
	var wobble := 0.0
	var wobble_strength := float(profile.get("windup_wobble", 0.0))
	if wobble_strength > 0.0:
		var windup_target := 1.0 if _parent_attack_state() == "windup" else 0.0
		var windup_weight := 1.0 - exp(-10.0 * safe_delta)
		_windup_amount = lerpf(_windup_amount, windup_target, windup_weight)
		wobble = wobble_strength * _windup_amount * sin(_motion_time * TAU * WINDUP_WOBBLE_HZ)

	_model_instance.position = _model_base_position + Vector3(0.0, bob, -recoil_kick)
	_model_instance.rotation = Vector3(-recoil_kick * 0.8, _spin_angle, bank + wobble)

func _apply_death_motion(profile: Dictionary, safe_delta: float) -> void:
	if String(profile.get("death", "freeze")) == "tumble":
		# Chaff death: the hover fails — it spins out and drops. Cosmetic
		# motion under the death_pop squash; gameplay was booked before this.
		_model_instance.rotation.x += 5.2 * safe_delta
		_model_instance.rotation.z += 3.4 * safe_delta
		var sink := minf(_death_time * 1.6, CHAFF_TUMBLE_SINK)
		_model_instance.position = _model_base_position + Vector3(0.0, -sink, 0.0)
		return
	# Rigged archetypes: level the whole-model layer fast so the skeletal
	# death clip owns the fall without a residual bob/bank underneath it.
	var settle := 1.0 - exp(-8.0 * safe_delta)
	_model_instance.position = _model_instance.position.lerp(_model_base_position, settle)
	_model_instance.rotation.x = lerpf(_model_instance.rotation.x, 0.0, settle)
	_model_instance.rotation.z = lerpf(_model_instance.rotation.z, 0.0, settle)

func play_hit_recoil() -> void:
	_recoil_remaining = 1.0

func apply_affix_visual(affix_id: StringName) -> void:
	_affix_id = affix_id
	_affix_time = 0.0
	_apply_affix_material()

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

func _parent_is_dead() -> bool:
	var parent_node := get_parent()
	return parent_node != null and parent_node.has_method(&"is_dead") \
			and bool(parent_node.is_dead())

func _parent_attack_state() -> String:
	var parent_node := get_parent()
	if parent_node == null:
		return ""
	var brain: Variant = parent_node.get("brain")
	if brain == null or not (brain as Object).has_method(&"attack_state"):
		return ""
	return String(brain.attack_state())

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
	_windup_amount = 0.0
	_death_time = 0.0
	_attach_animation_controller(archetype)
	_apply_affix_material()

## Rigged models carry a Skeleton3D + clip AnimationPlayer; give them the
## two-tier controller so authored clips drive locomotion/telegraph/hit/death.
func _attach_animation_controller(archetype: String) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	if _model_instance.find_child("Skeleton3D", true, false) == null:
		return
	var controller := EnemyAnimationController.new()
	controller.name = "EnemyAnimationController"
	add_child(controller)
	controller.setup(parent_node, _model_instance, archetype)

func _clear_model() -> void:
	var placeholder := get_node_or_null(placeholder_path)
	for child in get_children():
		if child != placeholder:
			child.queue_free()
	_model_instance = null
	_affix_material = null

func _set_placeholder_visible(visible: bool) -> void:
	var placeholder := get_node_or_null(placeholder_path) as Node3D
	if placeholder != null:
		placeholder.visible = visible

func _apply_affix_material() -> void:
	var mesh := _affix_mesh()
	if mesh == null:
		return
	if _affix_id == &"":
		if mesh.material_override == _affix_material:
			mesh.material_override = null
		_affix_material = null
		return
	_affix_material = _new_affix_material(_affix_color(), _affix_energy())
	mesh.material_override = _affix_material

func _tick_affix_pulse(delta: float) -> void:
	if _affix_id == &"":
		return
	var mesh := _affix_mesh()
	if mesh != null and _affix_material != null and mesh.material_override == null:
		mesh.material_override = _affix_material
	if _affix_material == null:
		_apply_affix_material()
		return
	_affix_time += maxf(delta, 0.0)
	var speed := 8.0 if _affix_id == AFFIX_FRENZIED else 3.0
	var base_energy := _affix_energy()
	var pulse := 0.72 + 0.28 * sin(_affix_time * TAU * speed)
	_affix_material.emission_energy_multiplier = base_energy * pulse

func _affix_mesh() -> MeshInstance3D:
	if _model_instance != null and is_instance_valid(_model_instance):
		return _first_mesh_under(_model_instance)
	var placeholder := get_node_or_null(placeholder_path)
	if placeholder is MeshInstance3D:
		return placeholder as MeshInstance3D
	if placeholder != null:
		return _first_mesh_under(placeholder)
	return null

func _first_mesh_under(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _first_mesh_under(child)
		if found != null:
			return found
	return null

func _new_affix_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = energy
	material.roughness = 0.82
	return material

func _affix_color() -> Color:
	match _affix_id:
		AFFIX_FRENZIED:
			return Color(1.0, 0.34, 0.12, 1.0)
		AFFIX_WARDED:
			return Color(0.58, 0.34, 1.0, 1.0)
		AFFIX_SHIELDED:
			return Color(0.44, 0.62, 0.82, 1.0)
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

func _affix_energy() -> float:
	match _affix_id:
		AFFIX_FRENZIED:
			return 1.35
		AFFIX_WARDED:
			return 1.05
		AFFIX_SHIELDED:
			return 0.95
		_:
			return 0.0
