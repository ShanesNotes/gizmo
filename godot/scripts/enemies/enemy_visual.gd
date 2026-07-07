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

var _model_instance: Node3D = null

func _ready() -> void:
	await get_tree().process_frame
	refresh_visual()

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
