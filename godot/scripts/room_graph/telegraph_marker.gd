class_name TelegraphMarker
extends Node3D

signal committed(marker_id: String)

const SHAPE_DISC := "disc"
const SHAPE_LINE := "line"

@export var marker_id: String = ""
@export_enum("disc", "line") var shape: String = SHAPE_DISC
@export_range(0.1, 16.0, 0.05) var radius: float = 1.0
@export_range(0.1, 32.0, 0.05) var length: float = 1.0
@export_range(0.05, 8.0, 0.05) var width: float = 0.5
@export_range(0.0, 10.0, 0.05) var duration: float = 0.8
@export var marker_color: Color = Color(1.0, 0.72, 0.22, 0.72)
@export var pulse: bool = false

var _visual: MeshInstance3D = null
var _elapsed: float = 0.0
var _started: bool = false
var _committed: bool = false

func _ready() -> void:
	_ensure_visual()
	_apply_visual()

func _process(delta: float) -> void:
	if _started and not _committed:
		advance_lifecycle(delta)
	elif pulse:
		_apply_pulse()

func configure(settings: Dictionary) -> void:
	marker_id = String(settings.get("marker_id", marker_id))
	shape = String(settings.get("shape", shape))
	radius = maxf(float(settings.get("radius", radius)), 0.1)
	length = maxf(float(settings.get("length", length)), 0.1)
	width = maxf(float(settings.get("width", width)), 0.05)
	duration = maxf(float(settings.get("duration", duration)), 0.0)
	var configured_color: Variant = settings.get("color", marker_color)
	if configured_color is Color:
		marker_color = configured_color as Color
	pulse = bool(settings.get("pulse", pulse))
	_elapsed = 0.0
	_started = true
	_committed = false
	_ensure_visual()
	_apply_visual()

func describe() -> Dictionary:
	return {
		"marker_id": marker_id,
		"shape": shape,
		"radius": radius,
		"length": length,
		"width": width,
		"duration": duration,
		"color": marker_color,
		"pulse": pulse,
		"committed": _committed,
	}

func visual_mesh() -> MeshInstance3D:
	return _ensure_visual()

func advance_lifecycle(delta: float) -> void:
	if _committed:
		return
	if not _started:
		_started = true
	_elapsed += maxf(delta, 0.0)
	if pulse:
		_apply_pulse()
	if _elapsed + 0.00001 >= duration:
		commit()

func commit() -> void:
	if _committed:
		return
	_committed = true
	committed.emit(marker_id)
	queue_free()

func _ensure_visual() -> MeshInstance3D:
	if _visual != null and is_instance_valid(_visual):
		return _visual
	_visual = MeshInstance3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	return _visual

func _apply_visual() -> void:
	var visual := _ensure_visual()
	match shape:
		SHAPE_LINE:
			var box := BoxMesh.new()
			box.size = Vector3(width, 0.035, length)
			visual.mesh = box
		_:
			var disc := CylinderMesh.new()
			disc.top_radius = radius
			disc.bottom_radius = radius
			disc.height = 0.035
			disc.radial_segments = 48
			visual.mesh = disc
	visual.material_override = _marker_material()
	visual.position.y = 0.035
	_apply_pulse()

func _marker_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = marker_color
	material.emission_enabled = true
	material.emission = Color(marker_color.r, marker_color.g, marker_color.b, 1.0)
	material.emission_energy_multiplier = 0.35
	material.roughness = 0.9
	if marker_color.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _apply_pulse() -> void:
	if _visual == null or not is_instance_valid(_visual):
		return
	if not pulse:
		_visual.scale = Vector3.ONE
		return
	var alpha := 0.0 if duration <= 0.0 else clampf(_elapsed / duration, 0.0, 1.0)
	var pulse_scale := 1.0 + sin(alpha * TAU * 2.0) * 0.04
	_visual.scale = Vector3.ONE * pulse_scale
