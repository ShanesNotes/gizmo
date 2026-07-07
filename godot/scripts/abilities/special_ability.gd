class_name SpecialAbility
extends Ability

## A stronger move gated by the player's run resource and its own cooldown.

func _init() -> void:
	ability_id = &"special"
	ability_name = "Special"
	kind = AbilityKind.SPECIAL
	cost = 30.0
	resource_key = &"spark_charge"
	cooldown = 1.20
	cast_time = 0.05
	recovery_time = 0.30
	potency = 70.0
