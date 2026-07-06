class_name CastAbility
extends Ability

## Hades-style cast: an ammo-based ranged/off-kit action. AbilityComponent
## owns current stones/lodged stones; this Resource only declares max ammo.

@export_range(1, 6) var max_ammo: int = 1

func _init() -> void:
	ability_id = &"cast"
	ability_name = "Cast"
	kind = AbilityKind.CAST
	cost = 0.0
	resource_key = &""
	cooldown = 0.0
	cast_time = 0.08
	recovery_time = 0.20
	potency = 45.0
