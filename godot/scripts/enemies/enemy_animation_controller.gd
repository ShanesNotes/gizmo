class_name EnemyAnimationController
extends Node

## Skeletal clip layer for rigged enemy archetypes (bruiser, elite). Follows
## the two-tier clip-source idiom from gizmo_animation_controller.gd: clips
## authored into the model GLB (tools/animation/author_enemy_clips.py)
## supersede; code-built poses guarantee the contract if a clip goes missing.
## Cosmetic only — reads the parent enemy's velocity/brain/death state, never
## writes gameplay. Composes with EnemyVisual: that script moves the whole
## model node (bob/bank/recoil); this one poses bones inside it.

const CLIP_IDLE := &"idle"
const CLIP_WALK := &"walk"
const CLIP_ATTACK := &"attack"
const CLIP_HIT := &"hit"
const CLIP_DEATH := &"death"
const CONTRACT: Array[StringName] = [CLIP_IDLE, CLIP_WALK, CLIP_ATTACK, CLIP_HIT, CLIP_DEATH]
const LOOPED := {CLIP_IDLE: true, CLIP_WALK: true}

## Elite never walks — it glides (EnemyVisual banking) in its poised stance.
const LOCOMOTION_CLIPS := {
	EnemyVisual.ARCHETYPE_BRUISER: CLIP_WALK,
	EnemyVisual.ARCHETYPE_ELITE: CLIP_IDLE,
}

## Meshy 24-bone rig names used by the guarantee poses.
const B_SPINE := "Spine01"
const B_HEAD := "Head"
const B_R_ARM := "RightArm"
const B_L_ARM := "LeftArm"
const B_R_THIGH := "RightUpLeg"
const B_L_THIGH := "LeftUpLeg"

const BLEND_SECONDS := 0.15
const HIT_BLEND_SECONDS := 0.05

var animation_player: AnimationPlayer = null

var _enemy: Node = null
var _skeleton: Skeleton3D = null
var _archetype: String = ""
var _current_clip: StringName = &""
var _hit_until: float = 0.0
var _time: float = 0.0

func setup(enemy: Node, model_instance: Node3D, archetype: String) -> void:
	_enemy = enemy
	_archetype = archetype
	_skeleton = model_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	animation_player = model_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation_player == null or _skeleton == null:
		return
	_ensure_contract_clips()
	if _enemy.has_signal(&"damage_taken") \
			and not _enemy.damage_taken.is_connected(_on_damage_taken):
		_enemy.damage_taken.connect(_on_damage_taken)
	_play_clip(CLIP_IDLE, BLEND_SECONDS)

func _physics_process(delta: float) -> void:
	update_animation(delta)

func update_animation(delta: float) -> void:
	if animation_player == null or _enemy == null or not is_instance_valid(_enemy):
		return
	_time += maxf(delta, 0.0)
	var desired := _desired_clip()
	if desired != _current_clip:
		_play_clip(desired, HIT_BLEND_SECONDS if desired == CLIP_HIT else BLEND_SECONDS)
	if desired == CLIP_WALK:
		animation_player.speed_scale = _walk_speed_scale()
	else:
		animation_player.speed_scale = 1.0

func _desired_clip() -> StringName:
	if _is_dead():
		return CLIP_DEATH
	if _attack_state() == "windup":
		return CLIP_ATTACK
	if _current_clip == CLIP_ATTACK and animation_player.is_playing():
		return CLIP_ATTACK  # let the strike/settle play through recovery
	if _time < _hit_until:
		return CLIP_HIT
	if _is_moving():
		return LOCOMOTION_CLIPS.get(_archetype, CLIP_WALK)
	return CLIP_IDLE

func _play_clip(clip_name: StringName, blend: float) -> void:
	var key := _library_key(clip_name)
	if key == "":
		return
	_current_clip = clip_name
	animation_player.play(key, blend)

func _library_key(clip_name: StringName) -> String:
	for library_name in animation_player.get_animation_library_list():
		var library := animation_player.get_animation_library(library_name)
		if library.has_animation(clip_name):
			return "%s/%s" % [library_name, clip_name] if String(library_name) != "" else String(clip_name)
	return ""

func _on_damage_taken(_spawn_id: String, _amount: float, _charges_spark: bool) -> void:
	if _is_dead() or _attack_state() == "windup":
		return
	_hit_until = _time + 0.25
	if _current_clip == CLIP_HIT:
		_play_clip(CLIP_HIT, HIT_BLEND_SECONDS)  # retrigger from the top

## ----------------------------------------------------------- parent reads
func _is_dead() -> bool:
	return _enemy.has_method(&"is_dead") and bool(_enemy.is_dead())

func _attack_state() -> String:
	var brain: Variant = _enemy.get("brain")
	if brain == null or not (brain as Object).has_method(&"attack_state"):
		return ""
	return String(brain.attack_state())

func _is_moving() -> bool:
	if not (_enemy is CharacterBody3D):
		return false
	var body := _enemy as CharacterBody3D
	return Vector3(body.velocity.x, 0.0, body.velocity.z).length() > 0.15

func _walk_speed_scale() -> float:
	if not (_enemy is CharacterBody3D):
		return 1.0
	var body := _enemy as CharacterBody3D
	var speed := Vector3(body.velocity.x, 0.0, body.velocity.z).length()
	var reference: float = maxf(float(_enemy.get("move_speed")), 0.001)
	return clampf(speed / reference, 0.5, 1.4)

## ------------------------------------------------- tier 2: guarantee clips
## Minimal code-built poses per contract name, added only when the authored
## GLB clip is absent. Loop modes are pinned for both tiers here (NLA import
## does not carry loop flags).
func _ensure_contract_clips() -> void:
	var fallback: AnimationLibrary = null
	for clip_name in CONTRACT:
		var key := _library_key(clip_name)
		if key != "":
			var animation := animation_player.get_animation(key)
			animation.loop_mode = Animation.LOOP_LINEAR if LOOPED.get(clip_name, false) else Animation.LOOP_NONE
			continue
		if fallback == null:
			fallback = AnimationLibrary.new()
			animation_player.add_animation_library(&"guarantee", fallback)
		fallback.add_animation(clip_name, _build_guarantee_clip(clip_name))

func _build_guarantee_clip(clip_name: StringName) -> Animation:
	var keys: Array = GUARANTEE_CLIP_DATA[clip_name]["keys"]
	var animation := Animation.new()
	animation.length = float(GUARANTEE_CLIP_DATA[clip_name]["length"])
	animation.loop_mode = Animation.LOOP_LINEAR if LOOPED.get(clip_name, false) else Animation.LOOP_NONE
	var skeleton_path := "%s:" % animation_player.get_node(animation_player.root_node).get_path_to(_skeleton)
	var clip_bones := {}
	for key: Dictionary in keys:
		for bone_name: String in key:
			if bone_name != "t":
				clip_bones[bone_name] = true
	for bone_name: String in clip_bones:
		var bone_index := _skeleton.find_bone(bone_name)
		if bone_index < 0:
			continue
		var rest_rotation := _skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, skeleton_path + bone_name)
		for key: Dictionary in keys:
			var euler_delta: Vector3 = key.get(bone_name, Vector3.ZERO)
			animation.rotation_track_insert_key(track, float(key["t"]), rest_rotation * Quaternion.from_euler(euler_delta))
	return animation

## Rotation-delta keyframes (radians on rest pose), deliberately crude — this
## tier only exists so the contract never ships empty.
const GUARANTEE_CLIP_DATA := {
	CLIP_IDLE: {"length": 2.0, "keys": [
		{"t": 0.0},
		{"t": 1.0, B_SPINE: Vector3(0.03, 0.0, 0.0), B_HEAD: Vector3(-0.03, 0.0, 0.0)},
		{"t": 2.0},
	]},
	CLIP_WALK: {"length": 0.6, "keys": [
		{"t": 0.0, B_R_THIGH: Vector3(0.4, 0.0, 0.0), B_L_THIGH: Vector3(-0.4, 0.0, 0.0)},
		{"t": 0.3, B_R_THIGH: Vector3(-0.4, 0.0, 0.0), B_L_THIGH: Vector3(0.4, 0.0, 0.0)},
		{"t": 0.6, B_R_THIGH: Vector3(0.4, 0.0, 0.0), B_L_THIGH: Vector3(-0.4, 0.0, 0.0)},
	]},
	CLIP_ATTACK: {"length": 1.2, "keys": [
		{"t": 0.0},
		{"t": 0.8, B_R_ARM: Vector3(-2.4, 0.0, 0.0), B_SPINE: Vector3(0.15, 0.0, 0.0)},
		{"t": 0.95, B_R_ARM: Vector3(0.5, 0.0, 0.0), B_SPINE: Vector3(-0.3, 0.0, 0.0)},
		{"t": 1.2},
	]},
	CLIP_HIT: {"length": 0.25, "keys": [
		{"t": 0.0},
		{"t": 0.07, B_SPINE: Vector3(0.12, 0.0, 0.0), B_HEAD: Vector3(0.1, 0.0, 0.0)},
		{"t": 0.25},
	]},
	CLIP_DEATH: {"length": 0.9, "keys": [
		{"t": 0.0},
		{"t": 0.9, B_SPINE: Vector3(-0.8, 0.0, 0.0), B_HEAD: Vector3(-0.4, 0.0, 0.0),
			B_R_THIGH: Vector3(-1.1, 0.0, 0.0), B_L_THIGH: Vector3(-1.1, 0.0, 0.0)},
	]},
}
