class_name BoonDef
extends Resource

## Authored boon definition. Boons are shared content Resources; when picked,
## their AbilityModifier entries are duplicated before being installed on the
## run's AbilityComponent.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum Slot { ATTACK, SPECIAL, CAST, DASH, PASSIVE }

@export var boon_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var slot: Slot = Slot.PASSIVE

## Generic grouping key for draft pools. Lore/canon can later map these domains
## to named patrons without changing this data model.
@export var domain: String = ""

@export var ability_modifiers: Array[AbilityModifier] = []

func apply_to_ability_kit(ability_kit: AbilityComponent) -> bool:
	if ability_kit == null:
		push_warning("BoonDef %s cannot apply to a null AbilityComponent." % boon_id)
		return false
	for modifier in create_runtime_modifiers():
		ability_kit.ability_modifiers.append(modifier)
	return true

func create_runtime_modifiers() -> Array[AbilityModifier]:
	var runtime_modifiers: Array[AbilityModifier] = []
	for modifier in ability_modifiers:
		if modifier == null:
			continue
		var runtime_modifier := modifier.duplicate(true) as AbilityModifier
		if runtime_modifier != null:
			runtime_modifiers.append(runtime_modifier)
	return runtime_modifiers

func rarity_label() -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

func slot_label() -> String:
	match slot:
		Slot.ATTACK:
			return "Attack"
		Slot.SPECIAL:
			return "Special"
		Slot.CAST:
			return "Cast"
		Slot.DASH:
			return "Dash"
		Slot.PASSIVE:
			return "Passive"
		_:
			return "Unknown"
