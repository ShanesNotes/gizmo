class_name OpeningSequence
extends Node3D

## The campfire opening: Gizmo small beside a warm fire in the dark, Margin
## introduced, the mission spoken (voice-scripts register), controls taught on
## a brass plate at the end. Skippable at any time; AppShell owns the
## first-boot flag and replays on request from the title screen.

signal finished

const DEFAULT_SEEN_PATH := "user://saves/opening_seen.cfg"
const GROUP_NAME: StringName = &"opening_sequence"
const SILENCE_LINE: StringName = &"margin_opening_silence"
const CAPTION_FADE_SECONDS := 0.8
const PORTRAIT_FADE_SECONDS := 2.0

## The four movements: the world went quiet -> the Spark you carry -> keep it
## safe, keep it alive -> Margin named, the Vigil begins. Captions mirror the
## spoken lines (voice-scripts-v1 register; new lines ledgered in the audio
## canon 2026-07-07-opening-lines batch).
const BEATS: Array[Dictionary] = [
	{
		"caption": "The world went quiet. Long ago, and all at once.",
		"voice": &"margin_opening_1",
		"min_seconds": 4.5,
	},
	{
		"caption": "What glows in your keeping is the Spark — humanity, still warm.",
		"voice": &"margin_opening_2",
		"min_seconds": 5.0,
	},
	{
		"caption": "You woke to two words, little keeper: keep it safe.",
		"voice": &"margin_opening_keep_safe",
		"min_seconds": 4.5,
	},
	{
		"caption": "Keep it alive. That is the whole of it.",
		"voice": &"margin_opening_keep_alive",
		"min_seconds": 4.0,
	},
	{
		"caption": "I am Marginalia — Margin, by this fire. The Vigil begins.",
		"voice": &"margin_opening_3",
		"min_seconds": 5.0,
		"reveal_portrait": true,
	},
]

## Runtime drop-ins over the director's public register_voice_line seam; the
## two "keep" beats replay Margin's recast hub-intro takes in fixed order.
const VOICE_SOURCES := {
	&"margin_opening_1": "res://audio/voice/margin_opening_1.ogg",
	&"margin_opening_2": "res://audio/voice/margin_opening_2.ogg",
	&"margin_opening_keep_safe": "res://audio/voice/margin_intro_1.ogg",
	&"margin_opening_keep_alive": "res://audio/voice/margin_intro_2.ogg",
	&"margin_opening_3": "res://audio/voice/margin_opening_3.ogg",
}

var audio_director: Node = null

var _beat_index := -1
var _beat_elapsed := 0.0
var _controls_shown := false
var _finished := false
var _fire_time := 0.0
var _fire_base_energy := 1.0

@onready var _caption_label: Label = %CaptionLabel
@onready var _portrait_texture: TextureRect = %PortraitReveal
@onready var _controls_block: Control = %ControlsBlock
@onready var _skip_hint: Label = %SkipHintLabel
@onready var _fire_light: OmniLight3D = %FireLight

static var replay_requested := false

static func has_seen(path: String = DEFAULT_SEEN_PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	return bool(config.get_value("opening", "seen", false))

static func mark_seen(path: String = DEFAULT_SEEN_PATH) -> Error:
	var base_dir := path.get_base_dir()
	if base_dir != "" and base_dir != ".":
		var absolute_dir := base_dir
		if not absolute_dir.is_absolute_path():
			absolute_dir = ProjectSettings.globalize_path(base_dir)
		var dir_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
		if dir_error != OK:
			return dir_error
	var config := ConfigFile.new()
	config.set_value("opening", "seen", true)
	return config.save(path)

func _ready() -> void:
	add_to_group(GROUP_NAME)
	if audio_director == null:
		audio_director = get_node_or_null("/root/AudioDirector")
	if _fire_light != null:
		_fire_base_energy = _fire_light.light_energy
	_portrait_texture.modulate.a = 0.0
	_load_portrait()
	_controls_block.visible = false
	_register_voice_lines()
	_advance_beat()

func _process(delta: float) -> void:
	_flicker_fire(delta)
	if _finished or _controls_shown:
		return
	_beat_elapsed += delta
	if _beat_ready_to_advance():
		_advance_beat()

## Test hook: fast-forward the current beat clock without waiting real time.
func advance_time(seconds: float) -> void:
	_beat_elapsed += seconds
	if not _finished and not _controls_shown and _beat_ready_to_advance():
		_advance_beat()

func _unhandled_input(event: InputEvent) -> void:
	if _finished:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_skip_and_consume_input()
		return
	if not _controls_shown:
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) \
			or (event is InputEventMouseButton and event.pressed)
	if pressed:
		_skip_and_consume_input()

## finished can tear this node out of the tree mid-event (AppShell swaps
## content), after which get_viewport() is null — capture it first.
func _skip_and_consume_input() -> void:
	var viewport := get_viewport()
	skip()
	if viewport != null:
		viewport.set_input_as_handled()

func skip() -> void:
	_finish()

func _beat_ready_to_advance() -> bool:
	if _beat_index < 0 or _beat_index >= BEATS.size():
		return false
	var min_seconds := float(BEATS[_beat_index].get("min_seconds", 4.0))
	return _beat_elapsed >= min_seconds and not _voice_speaking()

func _advance_beat() -> void:
	_beat_index += 1
	_beat_elapsed = 0.0
	if _beat_index >= BEATS.size():
		_show_controls()
		return
	var beat := BEATS[_beat_index]
	_show_caption(String(beat.get("caption", "")))
	if bool(beat.get("reveal_portrait", false)):
		_reveal_portrait()
	_speak(StringName(beat.get("voice", &"")))

func _show_caption(text: String) -> void:
	_caption_label.text = text
	_caption_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_caption_label, "modulate:a", 1.0, CAPTION_FADE_SECONDS)

func _reveal_portrait() -> void:
	var tween := create_tween()
	tween.tween_property(_portrait_texture, "modulate:a", 1.0, PORTRAIT_FADE_SECONDS)

func _show_controls() -> void:
	_controls_shown = true
	_caption_label.text = ""
	_controls_block.visible = true
	_controls_block.modulate.a = 0.0
	_skip_hint.text = "press any key to keep"
	var tween := create_tween()
	tween.tween_property(_controls_block, "modulate:a", 1.0, CAPTION_FADE_SECONDS)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_interrupt_voice()
	finished.emit()

func _load_portrait() -> void:
	if _portrait_texture.texture != null:
		return
	const PORTRAIT_PATH := "res://assets/portraits/margin_portrait.png"
	if ResourceLoader.exists(PORTRAIT_PATH):
		_portrait_texture.texture = load(PORTRAIT_PATH)

func _register_voice_lines() -> void:
	if audio_director == null or not audio_director.has_method(&"register_voice_line"):
		return
	for line_id in VOICE_SOURCES:
		var path := String(VOICE_SOURCES[line_id])
		if ResourceLoader.exists(path):
			audio_director.call(&"register_voice_line", line_id, [load(path)])
	audio_director.call(&"register_voice_line", SILENCE_LINE, [_make_silence_stream()])

func _speak(line_id: StringName) -> void:
	if line_id == &"" or audio_director == null:
		return
	if audio_director.has_method(&"play_voice_line"):
		audio_director.call(&"play_voice_line", line_id)

## The director has no public stop; a beat of registered silence interrupts a
## line mid-air on skip so speech never trails into the hub.
func _interrupt_voice() -> void:
	if _voice_speaking():
		_speak(SILENCE_LINE)

func _make_silence_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	var data := PackedByteArray()
	data.resize(4410)
	stream.data = data
	return stream

func _voice_speaking() -> bool:
	if audio_director == null or not audio_director.has_method(&"describe"):
		return false
	var description: Dictionary = audio_director.call(&"describe")
	return bool(description.get("voice_speaking", false))

func _flicker_fire(delta: float) -> void:
	if _fire_light == null:
		return
	_fire_time += delta
	var flicker := sin(_fire_time * 9.0) * 0.08 + sin(_fire_time * 23.0 + 1.7) * 0.06
	_fire_light.light_energy = _fire_base_energy + flicker
