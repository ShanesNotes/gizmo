class_name SpeakerPanel
extends CanvasLayer

## Corner speaker vignette: while a Margin voice line plays (AudioDirector's
## public describe() seam), her portrait and name fade in bottom-left. The
## Custodian's Pattern stays faceless by canon; the opening sequence carries
## its own full-scene reveal, so the panel yields while one is active.

const POLL_INTERVAL_SECONDS := 0.1
const GUIDE_LINE_PREFIX := "margin_"
const GUIDE_NAME := "MARGIN"
const PORTRAIT_PATH := "res://assets/portraits/margin_portrait.png"
const FADE_SECONDS := 0.4

var audio_director: Node = null

var _poll_accumulator := 0.0
var _shown := false
var _fade_tween: Tween = null

@onready var _root: Control = %Root
@onready var _name_label: Label = %SpeakerNameLabel
@onready var _portrait: TextureRect = %PortraitTexture

func _ready() -> void:
	if audio_director == null:
		audio_director = get_node_or_null("/root/AudioDirector")
	if _portrait.texture == null and ResourceLoader.exists(PORTRAIT_PATH):
		_portrait.texture = load(PORTRAIT_PATH)
	_name_label.text = GUIDE_NAME
	_root.visible = false
	_root.modulate.a = 0.0

func _process(delta: float) -> void:
	_poll_accumulator += delta
	if _poll_accumulator < POLL_INTERVAL_SECONDS:
		return
	_poll_accumulator = 0.0
	refresh_from_director()

func is_panel_visible() -> bool:
	return _shown

func refresh_from_director() -> void:
	_set_shown(_guide_is_speaking())

func _guide_is_speaking() -> bool:
	if audio_director == null or not audio_director.has_method(&"describe"):
		return false
	if not get_tree().get_nodes_in_group(OpeningSequence.GROUP_NAME).is_empty():
		return false
	var description: Dictionary = audio_director.call(&"describe")
	if not bool(description.get("voice_speaking", false)):
		return false
	return String(description.get("last_voice_line", "")).begins_with(GUIDE_LINE_PREFIX)

func _set_shown(shown: bool) -> void:
	if shown == _shown:
		return
	_shown = shown
	if _fade_tween != null:
		_fade_tween.kill()
	_fade_tween = create_tween()
	if shown:
		_root.visible = true
		_fade_tween.tween_property(_root, "modulate:a", 1.0, FADE_SECONDS)
	else:
		_fade_tween.tween_property(_root, "modulate:a", 0.0, FADE_SECONDS)
		_fade_tween.tween_callback(func() -> void: _root.visible = false)
