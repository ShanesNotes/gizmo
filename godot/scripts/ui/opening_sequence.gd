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
const PRE_BEAT_FIRE_SCALE := 0.15
const TITLE_FADE_SECONDS := 1.2
const TITLE_STING_PATH := "res://audio/music/sting_opening_title.ogg"

const CAMERA_POSES := {
	&"ember_close": {
		"position": Vector3(0.08, 0.54, 0.92),
		"look_at": Vector3(0.0, 0.18, 0.0),
		"push": 0.0,
	},
	&"fire_gizmo_reveal": {
		"position": Vector3(-0.35, 1.12, 2.4),
		"look_at": Vector3(-0.45, 0.34, 0.08),
		"push": -0.2,
	},
	&"dark_horizon": {
		"position": Vector3(-0.15, 2.2, 4.05),
		"look_at": Vector3(-0.25, 0.85, -2.2),
		"push": -0.3,
	},
	&"fire_portrait_side": {
		"position": Vector3(0.75, 1.45, 3.1),
		"look_at": Vector3(-0.32, 0.5, 0.04),
		"push": 0.1,
	},
}

## The movements: ember-dark -> the world went quiet -> the Spark you carry ->
## keep it safe, keep it alive -> title downbeat -> Margin named, the Vigil
## begins. Captions mirror the spoken lines (voice-scripts-v1 register; new
## lines ledgered in the audio canon 2026-07-07-opening-lines batch).
const BEATS: Array[Dictionary] = [
	{
		"min_seconds": 2.5,
		"camera_pose": &"ember_close",
	},
	{
		"caption": "The world went quiet. Long ago, and all at once.",
		"voice": &"margin_opening_1",
		"min_seconds": 4.5,
		"camera_pose": &"ember_close",
	},
	{
		"caption": "What glows in your keeping is the Spark — humanity, still warm.",
		"voice": &"margin_opening_2",
		"min_seconds": 5.0,
		"camera_pose": &"fire_gizmo_reveal",
	},
	{
		"caption": "You woke to two words, little keeper: keep it safe.",
		"voice": &"margin_opening_keep_safe",
		"min_seconds": 4.5,
		"camera_pose": &"dark_horizon",
	},
	{
		"caption": "Keep it alive. That is the whole of it.",
		"voice": &"margin_opening_keep_alive",
		"min_seconds": 4.0,
		"camera_pose": &"dark_horizon",
	},
	{
		"title_card": true,
		"min_seconds": 4.5,
		"camera_pose": &"fire_portrait_side",
	},
	{
		"caption": "I am Marginalia — Margin, by this fire. The Vigil begins.",
		"voice": &"margin_opening_3",
		"min_seconds": 5.0,
		"reveal_portrait": true,
		"camera_pose": &"fire_portrait_side",
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
var _fire_energy_scale := 1.0
var _fire_ramp_started := false
var _camera_from_pose: Dictionary = {}
var _camera_to_pose: Dictionary = {}
var _camera_current_pose: Dictionary = {}
var _caption_tween: Tween = null
var _portrait_tween: Tween = null
var _controls_tween: Tween = null
var _camera_tween: Tween = null
var _fire_ramp_tween: Tween = null
var _title_tween: Tween = null
var _margin_tween: Tween = null
var _margin_base_y := 0.0
var title_sting_path := TITLE_STING_PATH

@onready var _caption_label: Label = %CaptionLabel
@onready var _portrait_texture: TextureRect = %PortraitReveal
@onready var _controls_block: Control = %ControlsBlock
@onready var _skip_hint: Label = %SkipHintLabel
@onready var _fire_light: OmniLight3D = %FireLight
@onready var _camera: Camera3D = $Camera3D
@onready var _title_card: Control = %TitleCard
@onready var _title_sting_player: AudioStreamPlayer = %TitleStingPlayer
@onready var _margin_figure: Node3D = get_node_or_null("MarginFigure")
@onready var _gizmo_animator: Node = get_node_or_null("GizmoAnimator")

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
		_fire_energy_scale = PRE_BEAT_FIRE_SCALE
		_apply_fire_energy(0.0)
	if _camera != null and CAMERA_POSES.has(&"ember_close"):
		_apply_camera_pose(CAMERA_POSES[&"ember_close"])
	_portrait_texture.modulate.a = 0.0
	if _margin_figure != null:
		_margin_base_y = _margin_figure.position.y
		_margin_figure.visible = false
	_title_card.visible = false
	_title_card.modulate.a = 0.0
	_load_portrait()
	_controls_block.visible = false
	_seat_gizmo_at_fire()
	_register_voice_lines()
	_advance_beat()

## Gizmo is discovered small beside the fire — seat him with the campfire_sit
## pose and hold it for the whole cinematic (the shipped animation controller's
## lore seam; no-op if its authored clip is absent). The scene tears down into
## the hub afterward, so no resume is needed.
func _seat_gizmo_at_fire() -> void:
	if _gizmo_animator != null and _gizmo_animator.has_method(&"play_campfire_sit"):
		_gizmo_animator.call(&"play_campfire_sit")

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
	_advance_active_tweens(seconds)
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
	_kill_beat_tweens()
	_beat_index += 1
	_beat_elapsed = 0.0
	if _beat_index >= BEATS.size():
		_show_controls()
		return
	var beat := BEATS[_beat_index]
	_start_camera_pose(StringName(beat.get("camera_pose", &"")), float(beat.get("min_seconds", 4.0)))
	if bool(beat.get("title_card", false)):
		_clear_caption()
		_show_title_card(float(beat.get("min_seconds", 4.5)))
		return
	_hide_title_card()
	if beat.has("caption"):
		_show_caption(String(beat.get("caption", "")))
	else:
		_clear_caption()
	if bool(beat.get("reveal_portrait", false)):
		_reveal_portrait()
		_reveal_margin()
	if beat.has("voice"):
		if not _fire_ramp_started:
			_start_fire_ramp()
		_speak(StringName(beat.get("voice", &"")))

func _show_caption(text: String) -> void:
	_kill_tween(_caption_tween)
	_caption_label.text = text
	_caption_label.modulate.a = 0.0
	_caption_tween = create_tween()
	_caption_tween.tween_property(_caption_label, "modulate:a", 1.0, CAPTION_FADE_SECONDS)

func _clear_caption() -> void:
	_kill_tween(_caption_tween)
	_caption_label.text = ""
	_caption_label.modulate.a = 0.0

func _reveal_portrait() -> void:
	_kill_tween(_portrait_tween)
	_portrait_tween = create_tween()
	_portrait_tween.tween_property(_portrait_texture, "modulate:a", 1.0, PORTRAIT_FADE_SECONDS)

## Margin's body resolves out of the mist across the fire on her reveal beat —
## voice before image, then the lady herself rising into her own candlelight.
func _reveal_margin() -> void:
	if _margin_figure == null:
		return
	_kill_tween(_margin_tween)
	_margin_figure.visible = true
	_margin_figure.position.y = _margin_base_y - 0.25
	_margin_tween = create_tween()
	_margin_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_margin_tween.tween_property(_margin_figure, "position:y", _margin_base_y, PORTRAIT_FADE_SECONDS)

func _show_controls() -> void:
	_controls_shown = true
	_caption_label.text = ""
	_hide_title_card()
	_controls_block.visible = true
	_controls_block.modulate.a = 0.0
	_skip_hint.text = "press any key to keep"
	_controls_tween = create_tween()
	_controls_tween.tween_property(_controls_block, "modulate:a", 1.0, CAPTION_FADE_SECONDS)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_kill_all_tweens()
	if _title_sting_player.playing:
		_title_sting_player.stop()
	_hide_title_card()
	_interrupt_voice()
	finished.emit()

func _show_title_card(duration: float) -> void:
	_kill_tween(_title_tween)
	_title_card.visible = true
	_title_card.modulate.a = 0.0
	_play_title_sting()
	var hold_seconds := maxf(0.0, duration - TITLE_FADE_SECONDS * 2.0)
	_title_tween = create_tween()
	_title_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_title_tween.tween_property(_title_card, "modulate:a", 1.0, TITLE_FADE_SECONDS)
	_title_tween.tween_interval(hold_seconds)
	_title_tween.tween_property(_title_card, "modulate:a", 0.0, TITLE_FADE_SECONDS)
	_title_tween.tween_callback(_hide_title_card)

func _hide_title_card() -> void:
	_title_card.visible = false
	_title_card.modulate.a = 0.0

func _play_title_sting() -> void:
	if _title_sting_player == null or not ResourceLoader.exists(title_sting_path):
		return
	_title_sting_player.stream = load(title_sting_path)
	_title_sting_player.play()

func _start_fire_ramp() -> void:
	if _fire_ramp_started:
		return
	_fire_ramp_started = true
	_kill_tween(_fire_ramp_tween)
	_fire_ramp_tween = create_tween()
	_fire_ramp_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fire_ramp_tween.tween_property(self, "_fire_energy_scale", 1.0, _first_spoken_beats_duration(2))

func _first_spoken_beats_duration(count: int) -> float:
	var total := 0.0
	var found := 0
	for beat in BEATS:
		if not beat.has("voice"):
			continue
		total += float(beat.get("min_seconds", 4.0))
		found += 1
		if found >= count:
			break
	return maxf(total, 0.1)

func _start_camera_pose(pose_name: StringName, duration: float) -> void:
	if _camera == null or not CAMERA_POSES.has(pose_name):
		return
	_kill_tween(_camera_tween)
	_camera_from_pose = _camera_current_pose.duplicate()
	_camera_to_pose = CAMERA_POSES[pose_name].duplicate()
	_camera_tween = create_tween()
	_camera_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_tween.tween_method(_apply_camera_pose_weight, 0.0, 1.0, maxf(duration, 0.1))

func _apply_camera_pose_weight(weight: float) -> void:
	if _camera_from_pose.is_empty() or _camera_to_pose.is_empty():
		return
	var pose := {
		"position": (_camera_from_pose["position"] as Vector3).lerp(_camera_to_pose["position"] as Vector3, weight),
		"look_at": (_camera_from_pose["look_at"] as Vector3).lerp(_camera_to_pose["look_at"] as Vector3, weight),
		"push": lerpf(float(_camera_from_pose.get("push", 0.0)), float(_camera_to_pose.get("push", 0.0)), weight),
	}
	_apply_camera_pose(pose)

func _apply_camera_pose(pose: Dictionary) -> void:
	if _camera == null:
		return
	var position := pose["position"] as Vector3
	var look_at := pose["look_at"] as Vector3
	var push := float(pose.get("push", 0.0))
	var direction := (look_at - position).normalized()
	if direction.length_squared() > 0.0:
		position += direction * push
	_camera.global_position = position
	_camera.look_at(look_at, Vector3.UP)
	_camera_current_pose = {
		"position": pose["position"],
		"look_at": pose["look_at"],
		"push": push,
	}

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
	_apply_fire_energy(flicker)

func _apply_fire_energy(flicker: float) -> void:
	if _fire_light == null:
		return
	_fire_light.light_energy = maxf(0.0, _fire_base_energy * _fire_energy_scale + flicker)

func _advance_active_tweens(seconds: float) -> void:
	_custom_step_tween(_caption_tween, seconds)
	_custom_step_tween(_portrait_tween, seconds)
	_custom_step_tween(_controls_tween, seconds)
	_custom_step_tween(_camera_tween, seconds)
	_custom_step_tween(_fire_ramp_tween, seconds)
	_custom_step_tween(_title_tween, seconds)
	_custom_step_tween(_margin_tween, seconds)
	_apply_fire_energy(0.0)

func _custom_step_tween(tween: Tween, seconds: float) -> void:
	if tween != null and tween.is_valid():
		tween.custom_step(seconds)

func _kill_beat_tweens() -> void:
	_kill_tween(_caption_tween)
	_kill_tween(_camera_tween)
	_kill_tween(_title_tween)

func _kill_all_tweens() -> void:
	_kill_tween(_caption_tween)
	_kill_tween(_portrait_tween)
	_kill_tween(_controls_tween)
	_kill_tween(_camera_tween)
	_kill_tween(_fire_ramp_tween)
	_kill_tween(_title_tween)
	_kill_tween(_margin_tween)

func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
