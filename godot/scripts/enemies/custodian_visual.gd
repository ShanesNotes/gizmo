class_name CustodianVisual
extends Node3D

## Presiding motion for the Custodian: slow levitation, a glacial surveying
## sway, and a faint forward incline while repositioning. It never walks,
## never bobs with effort, and never flinches — damage is beneath its notice.
## Cosmetic only: reads the parent body's velocity, writes nothing back.
## The boss script owns this pivot's yaw (_face_target); we animate the model.

const LEVITATION_AMPLITUDE := 0.12
const LEVITATION_FREQUENCY_HZ := 0.22
const SURVEY_YAW_RADIANS := 0.04
const SURVEY_FREQUENCY_HZ := 0.09
const REPOSITION_INCLINE_RADIANS := 0.07

@export var model_path: NodePath = NodePath("CustodianBossModel")

@onready var _model: Node3D = get_node_or_null(model_path) as Node3D

var _time_seconds: float = 0.0
var _base_position: Vector3 = Vector3.ZERO
var _current_incline: float = 0.0

func _ready() -> void:
	if _model != null:
		_base_position = _model.position

func _physics_process(delta: float) -> void:
	update_motion(delta)

func update_motion(delta: float) -> void:
	if _model == null:
		return
	var safe_delta: float = maxf(delta, 0.0)
	_time_seconds += safe_delta

	var levitation := sin(_time_seconds * TAU * LEVITATION_FREQUENCY_HZ) * LEVITATION_AMPLITUDE
	var survey := sin(_time_seconds * TAU * SURVEY_FREQUENCY_HZ) * SURVEY_YAW_RADIANS

	var incline_target := _parent_move_amount() * REPOSITION_INCLINE_RADIANS
	var incline_weight := 1.0 - exp(-4.0 * safe_delta)
	_current_incline = lerpf(_current_incline, incline_target, incline_weight)

	_model.position = _base_position + Vector3(0.0, levitation, 0.0)
	_model.rotation = Vector3(_current_incline, survey, 0.0)

func _parent_move_amount() -> float:
	var parent_node := get_parent()
	if not (parent_node is CharacterBody3D):
		return 0.0
	var body := parent_node as CharacterBody3D
	var speed := Vector3(body.velocity.x, 0.0, body.velocity.z).length()
	return clampf(speed / 4.0, 0.0, 1.0)
