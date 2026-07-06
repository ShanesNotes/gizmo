class_name AbilityModifier
extends Resource

## Minimal boon seam: modifiers mutate a duplicated runtime copy of an Ability,
## never the shared authored Resource.

@export var modifier_id: StringName = &""
@export var target_ability_id: StringName = &""
@export_range(0.0, 10.0) var cooldown_multiplier: float = 1.0
@export_range(0.0, 10.0) var recovery_multiplier: float = 1.0
@export var cost_delta: float = 0.0
@export var potency_delta: float = 0.0

func applies_to(ability: Ability) -> bool:
	return target_ability_id == &"" or ability.ability_id == target_ability_id

func modify_ability(ability: Ability, _caster: Node) -> void:
	if not applies_to(ability):
		return
	ability.cooldown = maxf(0.0, ability.cooldown * cooldown_multiplier)
	ability.recovery_time = maxf(0.0, ability.recovery_time * recovery_multiplier)
	ability.cost = maxf(0.0, ability.cost + cost_delta)
	ability.potency = maxf(0.0, ability.potency + potency_delta)
