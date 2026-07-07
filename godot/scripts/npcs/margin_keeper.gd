class_name MarginKeeper
extends Area3D

## Margin's body at the campfire — the priority hub presence. Interacting is
## conversation: the director rotates her hub-intro takes (speaker panel picks
## her up automatically via the margin_ line prefix). The placeholder figure
## under "Placeholder" yields to the asset lab's model at "ModelSocket"
## (briefs/character/margin_codex_keeper.brief.yaml).

@export var prompt_text: String = "speak"

var audio_director: Node = null

var _player_inside := false

@onready var _prompt_label: Label3D = %PromptLabel

func _ready() -> void:
	if audio_director == null:
		audio_director = get_node_or_null("/root/AudioDirector")
	_prompt_label.text = prompt_text
	_prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed(&"ui_accept"):
		speak()

func speak() -> void:
	if audio_director == null or not audio_director.has_method(&"play_voice_line"):
		return
	if _is_margin_speaking():
		return
	audio_director.call(&"play_voice_line", &"margin_intro")

func _is_margin_speaking() -> bool:
	if audio_director == null or not audio_director.has_method(&"describe"):
		return false
	var description: Dictionary = audio_director.call(&"describe")
	if not bool(description.get("voice_speaking", false)):
		return false
	return String(description.get("last_voice_line", "")).begins_with("margin_")

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
