class_name CodexBook
extends Area3D

## The Codex made physical: a book prop at Margin's desk. Interacting cycles
## through unlocked entries; Margin reads each aloud (margin_codex_entry
## variants are indexed by codex_entries.gd variant_index, so the book
## registers the exact reading stream per entry instead of letting the
## director roll a random variant).

const CodexEntries := preload("res://scripts/codex/codex_entries.gd")
const CodexLogScript := preload("res://scripts/codex/codex_log.gd")
const READING_LINE_PREFIX := "margin_codex_read_"
const VOICE_DIR := "res://audio/voice/"

@export var prompt_text: String = "read"

var codex_log: Node = null
var audio_director: Node = null

var _player_inside := false
var _cycle_index := 0

@onready var _prompt_label: Label3D = %PromptLabel

func _ready() -> void:
	if codex_log == null:
		codex_log = CodexLogScript.new()
		add_child(codex_log)
	if audio_director == null:
		audio_director = get_node_or_null("/root/AudioDirector")
	_prompt_label.text = prompt_text
	_prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_register_readings()

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed(&"ui_accept"):
		read_next_entry()

## Reads the next unlocked entry in table order; wraps around. Returns the
## entry id read, or &"" when nothing is unlocked yet.
func read_next_entry() -> StringName:
	if codex_log == null or not codex_log.has_method(&"unlocked_entries"):
		return &""
	var unlocked: Array = codex_log.call(&"unlocked_entries")
	if unlocked.is_empty():
		return &""
	_cycle_index = _cycle_index % unlocked.size()
	var entry_id: StringName = unlocked[_cycle_index]
	_cycle_index += 1
	_speak_reading(entry_id)
	return entry_id

func _speak_reading(entry_id: StringName) -> void:
	if audio_director == null or not audio_director.has_method(&"play_voice_line"):
		return
	audio_director.call(&"play_voice_line", StringName(READING_LINE_PREFIX + String(entry_id)))

## One registered line per entry, bound to its exact variant file, so a
## reading always matches the page being read.
func _register_readings() -> void:
	if audio_director == null or not audio_director.has_method(&"register_voice_line"):
		return
	for raw_entry_id in CodexEntries.TABLE.keys():
		var entry := CodexEntries.TABLE[raw_entry_id] as Dictionary
		var variant := int(entry.get("variant_index", 0)) + 1
		var path := "%smargin_codex_entry_%d.ogg" % [VOICE_DIR, variant]
		if ResourceLoader.exists(path):
			audio_director.call(&"register_voice_line",
					StringName(READING_LINE_PREFIX + String(raw_entry_id)), [load(path)])

func _on_body_entered(body: Node3D) -> void:
	if _body_is_player(body):
		_player_inside = true
		_prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if _body_is_player(body):
		_player_inside = false
		_prompt_label.visible = false

func _body_is_player(body: Node3D) -> bool:
	return body != null and (body.is_in_group(&"player") or body is CharacterBody3D)
