class_name AbilityModifier
extends Resource

## Minimal boon seam: modifiers mutate a duplicated runtime copy of an Ability,
## never the shared authored Resource. Multipliers apply before deltas, so
## stacked modifiers from independent boons compound multiplicatively.

@export var modifier_id: StringName = &""
@export var target_ability_id: StringName = &""
@export_range(0.0, 10.0) var cooldown_multiplier: float = 1.0
@export_range(0.0, 10.0) var recovery_multiplier: float = 1.0
@export_range(0.0, 10.0) var damage_multiplier: float = 1.0
@export_range(0.0, 10.0) var dash_speed_multiplier: float = 1.0
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
	ability.potency = maxf(0.0, ability.potency * damage_multiplier + potency_delta)
	if ability is AttackAbility:
		var attack := ability as AttackAbility
		for i in range(attack.step_damage.size()):
			attack.step_damage[i] = maxf(0.0, attack.step_damage[i] * damage_multiplier + potency_delta)
		for i in range(attack.step_recovery.size()):
			attack.step_recovery[i] = maxf(0.0, attack.step_recovery[i] * recovery_multiplier)
	if ability is DashAbility:
		var dash := ability as DashAbility
		dash.dash_speed = maxf(0.0, dash.dash_speed * dash_speed_multiplier)
