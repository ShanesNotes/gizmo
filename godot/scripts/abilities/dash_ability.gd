class_name DashAbility
extends Ability

## Hades-style evasive movement intent. AbilityComponent owns the i-frame timer;
## a later movement controller can listen to dash_started for actual displacement.

@export_range(0.01, 3.0) var dash_duration: float = 0.18
@export_range(0.0, 3.0) var iframe_duration: float = 0.18
@export_range(0.0, 60.0) var dash_speed: float = 14.0
@export_range(1, 5) var charges: int = 1

func _init() -> void:
	ability_id = &"dash"
	ability_name = "Dash"
	kind = AbilityKind.DASH
	cost = 0.0
	resource_key = &""
	cooldown = 1.0
	cast_time = 0.0
	recovery_time = 0.0
	potency = 0.0
