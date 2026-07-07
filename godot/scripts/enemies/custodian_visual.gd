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

func _ready() -> void:
	if _model != null:
		_base_position = _model.position

func _physics_process(delta: float) -> void:
	update_motion(delta)

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

func _parent_move_amount() -> float:
	var parent_node := get_parent()
	if not (parent_node is CharacterBody3D):
		return 0.0
	var body := parent_node as CharacterBody3D
	var speed := Vector3(body.velocity.x, 0.0, body.velocity.z).length()
	return clampf(speed / 4.0, 0.0, 1.0)
