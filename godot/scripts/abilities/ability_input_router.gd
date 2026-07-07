class_name AbilityInputRouter
extends Node

## Event-driven bridge from Godot InputMap actions to the Hades-pivot ability kit.
## Tests drive handle_action_pressed() directly; _unhandled_input() is only the
## scene-facing wrapper around InputEvent action checks.

const ACTION_DASH: StringName = &"gizmo_dash"
const ACTION_ATTACK: StringName = &"gizmo_attack"
const ACTION_SPECIAL: StringName = &"gizmo_special"
const ACTION_CAST: StringName = &"gizmo_cast"
const ACTION_SURGE: StringName = &"gizmo_surge"

@export var ability_component: AbilityComponent

var direction_provider: Callable = Callable()

func _ready() -> void:
	if ability_component == null and get_parent() is AbilityComponent:
		ability_component = get_parent() as AbilityComponent

func _unhandled_input(event: InputEvent) -> void:
	for action in _action_priority():
		if event.is_action_pressed(action):
			handle_action_pressed(action, _current_direction())
			get_viewport().set_input_as_handled()
			return

func bind_component(component: AbilityComponent) -> void:
	ability_component = component

func bind_direction_provider(provider: Callable) -> void:
	direction_provider = provider

func handle_action_pressed(action: StringName, direction: Vector3 = Vector3.ZERO) -> bool:
	if ability_component == null:
		return false
	var ability_id := ability_id_for_action(action)
	if ability_id == &"":
		return false

	return ability_component.try_activate(ability_id, direction)

static func ability_id_for_action(action: StringName) -> StringName:
	match action:
		ACTION_DASH:
			return &"dash"
		ACTION_ATTACK:
			return &"attack"
		ACTION_SPECIAL:
			return &"special"
		ACTION_CAST:
			return &"cast"
		ACTION_SURGE:
			return &"surge"
		_:
			return &""

static func _action_priority() -> Array[StringName]:
	return [ACTION_DASH, ACTION_ATTACK, ACTION_SPECIAL, ACTION_CAST, ACTION_SURGE]

func _current_direction() -> Vector3:
	if not direction_provider.is_valid():
		return Vector3.ZERO
	var value: Variant = direction_provider.call()
	if value is Vector3:
		return value
	return Vector3.ZERO
