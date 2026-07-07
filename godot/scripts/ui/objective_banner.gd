class_name ObjectiveBanner
extends CanvasLayer

## Mission clarity at spawn: the first time a run surface enters the shell's
## content slot, a one-line objective banner fades in over the top of the
## screen and fades away. Copy is the canon runtime objective (NARRATIVE.md).

const OBJECTIVE_COPY := "Carry the Spark to the Beacon"
const FADE_IN_SECONDS := 0.9
const HOLD_SECONDS := 4.0
const FADE_OUT_SECONDS := 1.4

@export var content_slot_path: NodePath = ^"../ContentSlot"

var shown_count := 0

var _banner_visible := false

@onready var _root: Control = %Root
@onready var _label: Label = %ObjectiveLabel

func _ready() -> void:
	_label.text = OBJECTIVE_COPY
	_root.visible = false
	_root.modulate.a = 0.0

func _process(_delta: float) -> void:
	if shown_count > 0:
		set_process(false)
		return
	if _find_run_surface() != null:
		_show_banner()

func is_banner_visible() -> bool:
	return _banner_visible

func _find_run_surface() -> Node:
	var slot := get_node_or_null(content_slot_path)
	if slot == null:
		return null
	for child in slot.get_children():
		if child.has_signal(&"player_died") and child.has_signal(&"run_completed"):
			return child
	return null

func _show_banner() -> void:
	shown_count += 1
	_banner_visible = true
	_root.visible = true
	set_process(false)
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, FADE_IN_SECONDS)
	tween.tween_interval(HOLD_SECONDS)
	tween.tween_property(_root, "modulate:a", 0.0, FADE_OUT_SECONDS)
	tween.tween_callback(func() -> void:
		_root.visible = false
		_banner_visible = false)
