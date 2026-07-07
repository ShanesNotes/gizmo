class_name PlayerActionStateMachine
extends Node

## Small action-state gate for the player combat kit. It intentionally owns only
## temporal state and transition rules; ability-specific resources/cooldowns live
## on AbilityComponent.

enum ActionState { IDLE, DASH, ATTACK, SPECIAL, CAST, HITSTUN, SURGE }

signal state_changed(previous_state: int, new_state: int)
signal state_finished(finished_state: int)

var current_state: ActionState = ActionState.IDLE
var state_time_remaining: float = 0.0
var current_ability_id: StringName = &""

func can_start_ability(ability: Ability) -> bool:
	if ability == null:
		return false
	if current_state == ActionState.IDLE:
		return true
	return ability.kind == Ability.AbilityKind.DASH \
		and (
			current_state == ActionState.ATTACK
			or current_state == ActionState.SPECIAL
			or current_state == ActionState.CAST
		)

func start_ability(ability: Ability, duration: float) -> void:
	if ability == null:
		return
	var next_state := _state_for_ability(ability)
	_transition_to(next_state, duration, ability.ability_id)

func enter_hitstun(duration: float) -> void:
	_transition_to(ActionState.HITSTUN, maxf(duration, 0.0), &"")

func tick(delta: float) -> void:
	if current_state == ActionState.IDLE:
		return
	state_time_remaining = maxf(0.0, state_time_remaining - delta)
	if state_time_remaining <= 0.0:
		var finished := current_state
		_transition_to(ActionState.IDLE, 0.0, &"")
		state_finished.emit(finished)

func state_name() -> String:
	return state_name_for(current_state)

static func state_name_for(state: ActionState) -> String:
	match state:
		ActionState.IDLE:
			return "idle"
		ActionState.DASH:
			return "dash"
		ActionState.ATTACK:
			return "attack"
		ActionState.SPECIAL:
			return "special"
		ActionState.CAST:
			return "cast"
		ActionState.HITSTUN:
			return "hitstun"
		ActionState.SURGE:
			return "surge"
		_:
			return "unknown"

func _state_for_ability(ability: Ability) -> ActionState:
	match ability.kind:
		Ability.AbilityKind.DASH:
			return ActionState.DASH
		Ability.AbilityKind.ATTACK:
			return ActionState.ATTACK
		Ability.AbilityKind.SPECIAL:
			return ActionState.SPECIAL
		Ability.AbilityKind.CAST:
			return ActionState.CAST
		Ability.AbilityKind.SURGE:
			return ActionState.SURGE
		_:
			return ActionState.IDLE

func _transition_to(next_state: ActionState, duration: float, ability_id: StringName) -> void:
	var previous := current_state
	current_state = next_state
	state_time_remaining = maxf(duration, 0.0)
	current_ability_id = ability_id
	if previous != current_state:
		state_changed.emit(previous, current_state)
