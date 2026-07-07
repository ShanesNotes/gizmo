class_name SurgeAbility
extends Ability

## Full-gauge Spark of Humanity release. Runtime targeting stays with the
## room orchestrator because it owns the current living enemy set.

@export_range(1.0, 999.0, 1.0) var damage: float = 25.0
@export_range(1.0, 128.0, 1.0) var radius: float = 64.0
@export_range(0.05, 5.0, 0.05) var stagger_seconds: float = 0.75

func _init() -> void:
	ability_id = &"surge"
	ability_name = "Spark Surge"
	kind = AbilityKind.SURGE
	cost = 0.0
	resource_key = &""
	cooldown = 0.0
	cast_time = 0.0
	recovery_time = 0.20
	potency = damage
