class_name AbilityInputRouter
extends Node

## Event-driven bridge from Godot InputMap actions to the Hades-pivot ability kit.
## Tests drive handle_action_pressed() directly; _unhandled_input() is only the
## scene-facing wrapper around InputEvent action checks.

const ACTION_DASH: StringName = &"gizmo_dash"
const ACTION_ATTACK: StringName = &"gizmo_attack"
const ACTION_SPECIAL: StringName = &"gizmo_special"
const ACTION_CAST: StringName = &"gizmo_cast"
const DEFAULT_BUFFER_SECONDS: float = 0.15

@export var ability_component: AbilityComponent
@export_range(0.0, 0.50, 0.01) var buffer_seconds: float = DEFAULT_BUFFER_SECONDS

var _buffered_action: StringName = &""
var _buffered_direction: Vector3 = Vector3.ZERO
var _buffer_time_remaining: float = 0.0
var _is_replaying_buffer := false

func _ready() -> void:
	if ability_component == null and get_parent() is AbilityComponent:
		ability_component = get_parent() as AbilityComponent

func _process(delta: float) -> void:
	tick(delta)

func _unhandled_input(event: InputEvent) -> void:
	for action in _action_priority():
		if event.is_action_pressed(action):
			handle_action_pressed(action)
			get_viewport().set_input_as_handled()
			return

func bind_component(component: AbilityComponent) -> void:
	ability_component = component
	clear_buffer()

func handle_action_pressed(action: StringName, direction: Vector3 = Vector3.ZERO) -> bool:
	if ability_component == null:
		return false
	var ability_id := ability_id_for_action(action)
	if ability_id == &"":
		return false

	var activated := ability_component.try_activate(ability_id, direction)
	if activated:
		if _buffered_action == action:
			clear_buffer()
		return true

	if _should_buffer(action):
		# Latest press wins: the newest non-dash action owns the buffer window.
		_buffered_action = action
		_buffered_direction = direction
		if not _is_replaying_buffer:
			_buffer_time_remaining = buffer_seconds
	return false

func tick(delta: float) -> bool:
	if not has_buffered_action():
		return false

	_buffer_time_remaining = maxf(0.0, _buffer_time_remaining - maxf(delta, 0.0))
	if _buffer_time_remaining <= 0.0:
		clear_buffer()
		return false

	if ability_component == null:
		clear_buffer()
		return false
	if ability_component.current_action_state() != PlayerActionStateMachine.ActionState.IDLE:
		return false

	var action := _buffered_action
	var direction := _buffered_direction
	_is_replaying_buffer = true
	var activated := handle_action_pressed(action, direction)
	_is_replaying_buffer = false
	return activated

func clear_buffer() -> void:
	_buffered_action = &""
	_buffered_direction = Vector3.ZERO
	_buffer_time_remaining = 0.0
	_is_replaying_buffer = false

func has_buffered_action() -> bool:
	return _buffered_action != &"" and _buffer_time_remaining > 0.0

func buffered_action() -> StringName:
	return _buffered_action

func buffer_time_remaining() -> float:
	return _buffer_time_remaining

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
		_:
			return &""

static func _action_priority() -> Array[StringName]:
	return [ACTION_DASH, ACTION_ATTACK, ACTION_SPECIAL, ACTION_CAST]

func _should_buffer(action: StringName) -> bool:
	if buffer_seconds <= 0.0 or action == ACTION_DASH:
		return false
	return ability_component.current_action_state() != PlayerActionStateMachine.ActionState.IDLE
