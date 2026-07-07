class_name GearGate
extends Node3D

## Wrapper state driver for retracting clockwork gates.
const CLOSED_Y := 0.0
const OPEN_Y := -4.6
const OPEN_SECONDS := 0.8

@export var open: bool = false:
	set(value):
		open = value
		_apply_state()

var _model_tween: Tween = null

func _ready() -> void:
	_apply_state()

func _apply_state() -> void:
	var body_shape := get_node_or_null("Collision/BodyShape") as CollisionShape3D
	if body_shape != null:
		body_shape.disabled = open

	var model := get_node_or_null("Model") as Node3D
	if model == null:
		return

	var target_y := OPEN_Y if open else CLOSED_Y
	if _model_tween != null and _model_tween.is_valid():
		_model_tween.kill()

	if not is_inside_tree():
		model.position.y = target_y
		return

	_model_tween = create_tween()
	_model_tween.tween_property(model, "position:y", target_y, OPEN_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
