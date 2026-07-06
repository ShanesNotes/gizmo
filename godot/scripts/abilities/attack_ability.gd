class_name AttackAbility
extends Ability

## Light attack chain data. The component tracks which step is active and resets
## it when combo_window expires.

@export_range(1, 6) var combo_steps: int = 3
@export_range(0.01, 3.0) var combo_window: float = 0.45
@export var step_damage: Array[float] = [18.0, 20.0, 26.0]
@export var step_recovery: Array[float] = [0.16, 0.18, 0.24]

func _init() -> void:
	ability_id = &"attack"
	ability_name = "Attack"
	kind = AbilityKind.ATTACK
	cost = 0.0
	resource_key = &""
	cooldown = 0.0
	cast_time = 0.0
	recovery_time = 0.16
	potency = 18.0

func damage_for_step(step: int) -> float:
	return _value_for_step(step_damage, step, potency)

func recovery_for_step(step: int) -> float:
	return _value_for_step(step_recovery, step, recovery_time)

func _value_for_step(values: Array[float], step: int, fallback: float) -> float:
	if values.is_empty():
		return fallback
	var index := clampi(step - 1, 0, values.size() - 1)
	return values[index]
