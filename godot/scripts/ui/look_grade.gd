extends ColorRect
## Look-grade driver — owns the G12 painterly toggle and the HZ-108B
## world-state tint on the gouache grade shader (GradeLayer, below UI).
##
## G12: the painterly pass ships behind the project setting
## `gizmo/look/gouache_paint_enabled` (default ON) — revert is one flag.
## HZ-108B: hub reads warm sanctuary, combat reads ember-tense, a cleared
## room reads relief; transitions tween smoothly on the state edges.
## Tints trace to gizmo-design-system tokens.state.* (gate G1):
##   sanctuary.ground #fae5cc (hub warm), pressured.accent #da383b
##   (combat ember-tense), sanctuary.frame #e0c17a (cleared relief-gold).

const SETTING_PAINT_ENABLED := "gizmo/look/gouache_paint_enabled"
const PAINT_STRENGTH_DEFAULT := 0.45
const TINT_TWEEN_SECONDS := 1.2

## Tints pre-normalized toward unit luma by _normalized() at apply time.
const TINT_HUB := Color("#fae5cc")
const TINT_COMBAT := Color("#da383b")
const TINT_CLEARED := Color("#e0c17a")
const STRENGTH_HUB := 0.12
const STRENGTH_COMBAT := 0.10
const STRENGTH_CLEARED := 0.08

var _tint_tween: Tween = null

func _ready() -> void:
	var enabled: bool = true
	if ProjectSettings.has_setting(SETTING_PAINT_ENABLED):
		enabled = bool(ProjectSettings.get_setting(SETTING_PAINT_ENABLED))
	_set_param("paint_strength", PAINT_STRENGTH_DEFAULT if enabled else 0.0)
	if not enabled:
		_set_param("edge_ink_strength", 0.0)
		_set_param("grain_strength", 0.0)
	# Seed the tint params so they exist as tweenable properties.
	var mat := material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("state_tint", Color(1, 1, 1))
		mat.set_shader_parameter("state_tint_strength", 0.0)
	_connect_world_state.call_deferred()

func _connect_world_state() -> void:
	# Hub scene carries no run controller: rest in sanctuary warmth.
	var controller := _find_run_controller()
	if controller == null:
		_tween_tint(TINT_HUB, STRENGTH_HUB)
		return
	# Feature-detect: the core lane owns these signals; never assume.
	if controller.has_signal("room_entered"):
		controller.connect("room_entered", _on_room_entered)
	if controller.has_signal("room_cleared"):
		controller.connect("room_cleared", _on_room_cleared)
	_tween_tint(TINT_COMBAT, STRENGTH_COMBAT)

func _find_run_controller() -> Node:
	var root := get_tree().get_current_scene()
	if root == null:
		return null
	return _search_for_signal(root, "room_cleared", 0)

func _search_for_signal(node: Node, signal_name: String, depth: int) -> Node:
	if depth > 4:
		return null
	if node.has_signal(signal_name) and node != self:
		return node
	for child in node.get_children():
		var found := _search_for_signal(child, signal_name, depth + 1)
		if found != null:
			return found
	return null

func _on_room_entered(_room) -> void:
	_tween_tint(TINT_COMBAT, STRENGTH_COMBAT)

func _on_room_cleared(_room = null) -> void:
	_tween_tint(TINT_CLEARED, STRENGTH_CLEARED)

func _tween_tint(tint: Color, strength: float) -> void:
	var target := _normalized(tint)
	if _tint_tween != null and _tint_tween.is_valid():
		_tint_tween.kill()
	var mat := material as ShaderMaterial
	if mat == null:
		return
	_tint_tween = create_tween().set_parallel(true)
	_tint_tween.tween_property(
		mat, "shader_parameter/state_tint", target, TINT_TWEEN_SECONDS)
	_tint_tween.tween_property(
		mat, "shader_parameter/state_tint_strength", strength, TINT_TWEEN_SECONDS)

func _normalized(tint: Color) -> Color:
	# Scale toward unit luma so the multiplicative wash shifts hue, not value.
	var luma := 0.299 * tint.r + 0.587 * tint.g + 0.114 * tint.b
	if luma <= 0.0:
		return Color(1, 1, 1)
	return Color(tint.r / luma, tint.g / luma, tint.b / luma)

func _set_param(param: String, value: float) -> void:
	var mat := material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter(param, value)
