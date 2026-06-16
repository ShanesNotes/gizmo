@tool
class_name LumenPanel
extends PanelContainer

## Lumen Codex Panel family: dark-glass page apparatus with gold, danger, or plain rule-line tone.
## Source: design-system/components/core/Panel.prompt.md and Panel.jsx.

enum PanelTone { GOLD, DANGER, PLAIN }

@export var tone: PanelTone = PanelTone.GOLD:
	set(value):
		tone = value
		_apply_style()
@export var dashed: bool = true:
	set(value):
		dashed = value
		queue_redraw()
@export var eyebrow_text: String = "COVENANT":
	set(value):
		eyebrow_text = value
		_sync_labels()
@export_multiline var body_text: String = "Pulse Driver · Spark Magnet · Echo Coil":
	set(value):
		body_text = value
		_sync_labels()

@onready var _eyebrow: Label = %Eyebrow
@onready var _body: Label = %Body

func _ready() -> void:
	_apply_style()
	_sync_labels()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if not dashed:
		return
	var inset := float(_theme_constant("inner_rule_inset", 4))
	var rect := Rect2(Vector2(inset, inset), size - Vector2(inset * 2.0, inset * 2.0))
	var rule_color := _theme_color("rule_inner")
	var dash_length: float = maxf(1.0, float(_theme_constant("dash_length", 7)))
	var dash_gap: float = maxf(0.0, float(_theme_constant("dash_gap", 5)))
	_draw_dashed_rect(rect, rule_color, 1.0, dash_length, dash_gap)

func _apply_style() -> void:
	if has_theme_stylebox(_style_name(), "LumenPanel"):
		var themed_style := get_theme_stylebox(_style_name(), "LumenPanel")
		add_theme_stylebox_override("panel", themed_style.duplicate())
	else:
		remove_theme_stylebox_override("panel")
		push_warning("LumenPanel theme style '%s' is missing; check godot/ui/theme.tres." % _style_name())
	queue_redraw()

func _sync_labels() -> void:
	if not is_node_ready():
		return
	_eyebrow.text = eyebrow_text.to_upper()
	_eyebrow.visible = not eyebrow_text.strip_edges().is_empty()
	_body.text = body_text
	_eyebrow.add_theme_color_override("font_color", _theme_color("eyebrow_color"))
	_eyebrow.add_theme_font_size_override("font_size", _theme_font_size("eyebrow_font_size", 13))
	_body.add_theme_color_override("font_color", _theme_color("body_color"))
	_body.add_theme_font_size_override("font_size", _theme_font_size("body_font_size", 14))

func _style_name() -> StringName:
	match tone:
		PanelTone.DANGER:
			return &"danger"
		PanelTone.PLAIN:
			return &"plain"
		_:
			return &"gold"

func _theme_color(name: StringName) -> Color:
	if has_theme_color(name, "LumenPanel"):
		return get_theme_color(name, "LumenPanel")
	push_warning("LumenPanel theme color '%s' is missing; check godot/ui/theme.tres." % name)
	return Color.TRANSPARENT

func _theme_constant(name: StringName, default_value: int) -> int:
	if has_theme_constant(name, "LumenPanel"):
		return get_theme_constant(name, "LumenPanel")
	push_warning("LumenPanel theme constant '%s' is missing; check godot/ui/theme.tres." % name)
	return default_value

func _theme_font_size(name: StringName, default_size: int) -> int:
	if has_theme_font_size(name, "LumenPanel"):
		return get_theme_font_size(name, "LumenPanel")
	push_warning("LumenPanel theme font size '%s' is missing; check godot/ui/theme.tres." % name)
	return default_size

func _draw_dashed_rect(rect: Rect2, color: Color, width: float, dash: float, gap: float) -> void:
	_draw_dashed_segment(rect.position, Vector2(rect.end.x, rect.position.y), color, width, dash, gap)
	_draw_dashed_segment(Vector2(rect.end.x, rect.position.y), rect.end, color, width, dash, gap)
	_draw_dashed_segment(rect.end, Vector2(rect.position.x, rect.end.y), color, width, dash, gap)
	_draw_dashed_segment(Vector2(rect.position.x, rect.end.y), rect.position, color, width, dash, gap)

func _draw_dashed_segment(start: Vector2, end: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var vector := end - start
	var length := vector.length()
	if length <= 0.0 or dash <= 0.0:
		return
	var direction := vector / length
	var offset := 0.0
	while offset < length:
		var next := minf(offset + dash, length)
		draw_line(start + direction * offset, start + direction * next, color, width)
		offset += dash + gap
