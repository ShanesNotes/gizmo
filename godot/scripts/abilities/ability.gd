class_name Ability
extends Resource

## Shared authored data for one player ability. Runtime state such as cooldowns,
## combo counters, resources, and i-frames lives on AbilityComponent.

enum AbilityKind { DASH, ATTACK, SPECIAL, CAST, SURGE }

@export var ability_id: StringName = &""
@export var ability_name: String = ""
@export var kind: AbilityKind = AbilityKind.ATTACK
@export_range(0.0, 999.0) var cost: float = 0.0
@export var resource_key: StringName = &""
@export_range(0.0, 60.0) var cooldown: float = 0.0
@export_range(0.0, 3.0) var cast_time: float = 0.0
@export_range(0.0, 3.0) var recovery_time: float = 0.0
@export_range(0.0, 999.0) var potency: float = 0.0

func can_activate(_caster: Node) -> bool:
	return true

func runtime_copy() -> Ability:
	return duplicate(true) as Ability
