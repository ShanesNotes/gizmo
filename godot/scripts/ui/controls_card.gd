class_name ControlsCard
extends PanelContainer

## The brass keeping-plate: every control on one card. Shown at the end of the
## campfire opening and from the pause menu's HOW TO KEEP entry.

const TITLE := "HOW TO KEEP"
const CONTROL_ROWS: Array[Array] = [
	["WASD", "Move"],
	["LEFT CLICK", "Swing"],
	["RIGHT CLICK", "Special"],
	["Q", "Cast"],
	["SPACE", "Dash"],
	["F", "Surge"],
	["ESC", "Pause"],
]

const KEY_COLOR := Color(0.8784, 0.7569, 0.4784)
const ACTION_COLOR := Color(0.7569, 0.6667, 0.5686)

@onready var _grid: GridContainer = %ControlsGrid
@onready var _title_label: Label = %CardTitleLabel

func _ready() -> void:
	_title_label.text = TITLE
	_build_rows()

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func is_open() -> bool:
	return visible

func _build_rows() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for row in CONTROL_ROWS:
		_grid.add_child(_make_label(String(row[0]), KEY_COLOR, HORIZONTAL_ALIGNMENT_RIGHT))
		_grid.add_child(_make_label(String(row[1]), ACTION_COLOR, HORIZONTAL_ALIGNMENT_LEFT))

func _make_label(text: String, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", 18)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
