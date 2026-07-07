class_name CustodianVisual
extends Node3D

## Presiding motion for the Custodian: slow levitation, a glacial surveying
## sway, and a faint forward incline while repositioning. It never walks,
## never bobs with effort, and never flinches — damage is beneath its notice.
## What it does register is its own intent: during an attack windup the survey
## stops, the monolith rises and leans in — a presence shift read alongside
## the ground telegraphs. Death is a power-cut at its scale: the levitation
## dies and it settles, slowly, like a verdict. Cosmetic only: reads the
## parent body's velocity/brain state, writes nothing back. The boss script
## owns this pivot's yaw (_face_target); we animate the model.

const LEVITATION_AMPLITUDE := 0.12
const LEVITATION_FREQUENCY_HZ := 0.22
const SURVEY_YAW_RADIANS := 0.04
const SURVEY_FREQUENCY_HZ := 0.09
const REPOSITION_INCLINE_RADIANS := 0.07
const WINDUP_RISE := 0.24
const WINDUP_INCLINE_RADIANS := 0.09
const DEATH_SINK := 0.9
const DEATH_SINK_SECONDS := 2.5
const DEATH_PITCH_RADIANS := 0.12

@export var model_path: NodePath = NodePath("CustodianBossModel")

@onready var _model: Node3D = get_node_or_null(model_path) as Node3D

var _time_seconds: float = 0.0
var _base_position: Vector3 = Vector3.ZERO
var _current_incline: float = 0.0
var _windup_presence: float = 0.0
var _death_time: float = 0.0

## --- skeletal clip layer (night pass 2026-07-07) -------------------------
## The boss GLB carries a 9-bone rig + authored clips (idle loop, phase_shift
## flourish, attack [overreach strike 1.20s], attack_sweep [audit strike
## 0.90s], death = halo guttering out; tools/animation/rig_custodian_boss.py).
## This layer plays them from the same parent reads the procedural motion
## uses; the two compose — this node moves the model, clips pose bones.
const CLIP_LOOPED := {&"idle": true}

var _anim: AnimationPlayer = null
var _clip: StringName = &""
var _windup_clip: StringName = &"attack"
var _last_phase: int = 0
var _phase_flourish_pending := false
var _brain_connected := false

func _ready() -> void:
	if _model != null:
		_base_position = _model.position
		_anim = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if _anim != null:
			_pin_clip_loops()
			_play_clip(&"idle")

func _physics_process(delta: float) -> void:
	update_motion(delta)
	_update_clip_layer()

func update_motion(delta: float) -> void:
	if _model == null:
		return
	var safe_delta: float = maxf(delta, 0.0)
	if _parent_is_dead():
		_apply_death_motion(safe_delta)
		return
	_death_time = 0.0
	_time_seconds += safe_delta

	# Presence shift: rise + lean-in while the brain winds up; the survey sway
	# freezes with it (locked attention is the tell).
	var presence_target := 1.0 if _parent_execution_state() == "windup" else 0.0
	var presence_weight := 1.0 - exp(-3.0 * safe_delta)
	_windup_presence = lerpf(_windup_presence, presence_target, presence_weight)

	var levitation := sin(_time_seconds * TAU * LEVITATION_FREQUENCY_HZ) * LEVITATION_AMPLITUDE
	var survey := sin(_time_seconds * TAU * SURVEY_FREQUENCY_HZ) * SURVEY_YAW_RADIANS \
			* (1.0 - _windup_presence)

	var incline_target := _parent_move_amount() * REPOSITION_INCLINE_RADIANS \
			+ _windup_presence * WINDUP_INCLINE_RADIANS
	var incline_weight := 1.0 - exp(-4.0 * safe_delta)
	_current_incline = lerpf(_current_incline, incline_target, incline_weight)

	_model.position = _base_position \
			+ Vector3(0.0, levitation + _windup_presence * WINDUP_RISE, 0.0)
	_model.rotation = Vector3(_current_incline, survey, 0.0)

func _apply_death_motion(safe_delta: float) -> void:
	_death_time += safe_delta
	var progress := clampf(_death_time / DEATH_SINK_SECONDS, 0.0, 1.0)
	var eased := 1.0 - (1.0 - progress) * (1.0 - progress)
	_model.position = _model.position.lerp(
		_base_position + Vector3(0.0, -DEATH_SINK * eased, 0.0),
		1.0 - exp(-2.0 * safe_delta)
	)
	_model.rotation = Vector3(DEATH_PITCH_RADIANS * eased, _model.rotation.y, 0.0)

func _parent_is_dead() -> bool:
	var parent_node := get_parent()
	return parent_node != null and parent_node.has_method(&"is_dead") \
			and bool(parent_node.is_dead())

func _parent_execution_state() -> String:
	var parent_node := get_parent()
	if parent_node == null:
		return ""
	var brain: Variant = parent_node.get("boss_brain")
	if brain == null or not (brain as Object).has_method(&"execution_state"):
		return ""
	return String(brain.execution_state())

## ------------------------------------------------------ clip layer internals
func _update_clip_layer() -> void:
	if _anim == null:
		return
	_try_connect_brain()
	_track_phase()
	var desired := _desired_clip()
	if desired != _clip:
		_play_clip(desired)

func _desired_clip() -> StringName:
	if _parent_is_dead():
		return &"death"
	if (_clip == &"attack" or _clip == &"attack_sweep") and _anim.is_playing():
		return _clip  # strike/settle plays through
	if _parent_execution_state() == "windup":
		return _windup_clip
	if _clip == &"phase_shift" and _anim.is_playing():
		return _clip
	if _phase_flourish_pending:
		_phase_flourish_pending = false
		return &"phase_shift"
	return &"idle"

func _track_phase() -> void:
	var brain: Variant = _parent_brain()
	if brain == null or not (brain as Object).has_method(&"current_phase"):
		return
	var phase := int(brain.current_phase())
	if phase != _last_phase:
		if _last_phase > 0 and not _parent_is_dead():
			_phase_flourish_pending = true
		_last_phase = phase

func _try_connect_brain() -> void:
	if _brain_connected:
		return
	var brain: Variant = _parent_brain()
	if brain == null or not (brain as Object).has_signal(&"attack_windup_started"):
		return
	brain.attack_windup_started.connect(_on_attack_windup_started)
	_brain_connected = true

func _on_attack_windup_started(attack: Dictionary) -> void:
	_windup_clip = &"attack_sweep" if String(attack.get("id", "")) == "audit_sweep" else &"attack"

func _play_clip(clip_name: StringName) -> void:
	var key := _library_key(clip_name)
	if key == "":
		return
	_clip = clip_name
	_anim.play(key, 0.25)

func _pin_clip_loops() -> void:
	for clip_name: StringName in [&"idle", &"phase_shift", &"attack", &"attack_sweep", &"death"]:
		var key := _library_key(clip_name)
		if key == "":
			continue
		var animation := _anim.get_animation(key)
		animation.loop_mode = Animation.LOOP_LINEAR if CLIP_LOOPED.get(clip_name, false) else Animation.LOOP_NONE

func _library_key(clip_name: StringName) -> String:
	for library_name in _anim.get_animation_library_list():
		var library := _anim.get_animation_library(library_name)
		if library.has_animation(clip_name):
			return "%s/%s" % [library_name, clip_name] if String(library_name) != "" else String(clip_name)
	return ""

func _parent_brain() -> Variant:
	var parent_node := get_parent()
	if parent_node == null:
		return null
	return parent_node.get("boss_brain")

func _parent_move_amount() -> float:
	var parent_node := get_parent()
	if not (parent_node is CharacterBody3D):
		return 0.0
	var body := parent_node as CharacterBody3D
	var speed := Vector3(body.velocity.x, 0.0, body.velocity.z).length()
	return clampf(speed / 4.0, 0.0, 1.0)
