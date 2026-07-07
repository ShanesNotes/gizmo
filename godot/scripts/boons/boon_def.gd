class_name BoonDef
extends Resource

## Authored boon definition. Boons are shared content Resources; when picked,
## their AbilityModifier entries are duplicated before being installed on the
## run's AbilityComponent.

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum Slot { ATTACK, SPECIAL, CAST, DASH, PASSIVE }

const VALID_BENEFACTOR_IDS: Array[StringName] = [
	&"bearer",
	&"hearthguard",
	&"swordbearer",
	&"marksman",
	&"company",
]

@export var boon_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: Rarity = Rarity.COMMON
@export var slot: Slot = Slot.PASSIVE
@export var benefactor_display_name: String = ""
@export var benefactor: StringName = &"":
	set(value):
		var previous_placeholder := benefactor_placeholder_display_name()
		benefactor = value
		# Refresh an auto-derived placeholder on reassignment; never clobber a
		# lore-authored display name.
		if benefactor_display_name.is_empty() or benefactor_display_name == previous_placeholder:
			benefactor_display_name = benefactor_placeholder_display_name()

## Generic grouping key for draft pools. Lore/canon can later map these domains
## to named patrons without changing this data model.
@export var domain: String = ""

@export var ability_modifiers: Array[AbilityModifier] = []

## Kit-level effect: extra max cast shards, granted while this keepsake is held.
@export_range(-6, 6) var bonus_cast_ammo: int = 0

@export_group("Vitals Effects")
## Multipliers apply to the PlayerVitals exported params relative to their
## pre-draft base; values below 1.0 (or negative deltas) are trade-off costs.
@export_range(0.0, 10.0) var guard_recharge_rate_multiplier: float = 1.0
@export_range(0.0, 10.0) var guard_recharge_delay_multiplier: float = 1.0
@export_range(-99, 99) var max_guard_delta: int = 0
@export_range(0.0, 10.0) var surge_charge_rate_multiplier: float = 1.0

@export_group("Synergy")
## BoonDef.Slot value this keepsake resonates with; -1 disables the synergy.
## While a different picked keepsake occupies that slot, synergy_ability_modifiers
## install alongside ability_modifiers.
@export var synergy_with_slot: int = -1
@export var synergy_ability_modifiers: Array[AbilityModifier] = []

func has_effects() -> bool:
	return not ability_modifiers.is_empty() \
		or bonus_cast_ammo != 0 \
		or max_guard_delta != 0 \
		or not is_equal_approx(guard_recharge_rate_multiplier, 1.0) \
		or not is_equal_approx(guard_recharge_delay_multiplier, 1.0) \
		or not is_equal_approx(surge_charge_rate_multiplier, 1.0) \
		or has_synergy()

func has_cost() -> bool:
	if max_guard_delta < 0 or bonus_cast_ammo < 0:
		return true
	if guard_recharge_rate_multiplier < 1.0 or surge_charge_rate_multiplier < 1.0:
		return true
	if guard_recharge_delay_multiplier > 1.0:
		return true
	return false

func has_synergy() -> bool:
	return synergy_with_slot >= 0 and not synergy_ability_modifiers.is_empty()

## Player-facing gain lines ("+20% attack damage") for the draft card.
func effect_lines() -> Array[String]:
	var lines: Array[String] = []
	for modifier in ability_modifiers:
		for line in _modifier_lines(modifier, false):
			lines.append(line)
	if bonus_cast_ammo > 0:
		lines.append("+%d cast shard%s" % [bonus_cast_ammo, "" if bonus_cast_ammo == 1 else "s"])
	if guard_recharge_rate_multiplier > 1.0:
		lines.append("guard returns %d%% faster" % _percent_over(guard_recharge_rate_multiplier))
	if guard_recharge_delay_multiplier < 1.0:
		lines.append("guard stirs %d%% sooner" % _percent_under(guard_recharge_delay_multiplier))
	if max_guard_delta > 0:
		lines.append("+%d max guard" % max_guard_delta)
	if surge_charge_rate_multiplier > 1.0:
		lines.append("surge gathers %d%% faster" % _percent_over(surge_charge_rate_multiplier))
	if has_synergy():
		var synergy_lines: Array[String] = []
		for modifier in synergy_ability_modifiers:
			for line in _modifier_lines(modifier, false):
				synergy_lines.append(line)
		if not synergy_lines.is_empty():
			lines.append(
				"with a %s keepsake: %s" % [_slot_name(synergy_with_slot), ", ".join(synergy_lines)]
			)
	return lines

## Player-facing cost lines ("guard returns 50% slower") for trade-off tinting.
func cost_lines() -> Array[String]:
	var lines: Array[String] = []
	if guard_recharge_rate_multiplier < 1.0:
		lines.append("guard returns %d%% slower" % _percent_under(guard_recharge_rate_multiplier))
	if guard_recharge_delay_multiplier > 1.0:
		lines.append("guard stirs %d%% later" % _percent_over(guard_recharge_delay_multiplier))
	if max_guard_delta < 0:
		lines.append("%d max guard" % max_guard_delta)
	if bonus_cast_ammo < 0:
		lines.append("%d cast shards" % bonus_cast_ammo)
	if surge_charge_rate_multiplier < 1.0:
		lines.append("surge gathers %d%% slower" % _percent_under(surge_charge_rate_multiplier))
	return lines

func _modifier_lines(modifier: AbilityModifier, _as_cost: bool) -> Array[String]:
	var lines: Array[String] = []
	if modifier == null:
		return lines
	var target := _target_name(modifier.target_ability_id)
	if modifier.damage_multiplier > 1.0:
		lines.append("+%d%% %s damage" % [_percent_over(modifier.damage_multiplier), target])
	if modifier.potency_delta > 0.0:
		lines.append("+%d %s power" % [int(round(modifier.potency_delta)), target])
	if modifier.cooldown_multiplier < 1.0:
		lines.append("%s recharges %d%% faster" % [target, _percent_under(modifier.cooldown_multiplier)])
	if modifier.recovery_multiplier < 1.0:
		lines.append("+%d%% %s speed" % [int(round((1.0 / modifier.recovery_multiplier - 1.0) * 100.0)), target])
	if modifier.dash_speed_multiplier > 1.0:
		lines.append("+%d%% dash speed" % _percent_over(modifier.dash_speed_multiplier))
	return lines

func _target_name(ability_id: StringName) -> String:
	return "every" if ability_id == &"" else String(ability_id)

func _slot_name(slot_value: int) -> String:
	match slot_value:
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

static func _percent_over(multiplier: float) -> int:
	return int(round((multiplier - 1.0) * 100.0))

static func _percent_under(multiplier: float) -> int:
	return int(round((1.0 - multiplier) * 100.0))

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

func benefactor_placeholder_display_name() -> String:
	return String(benefactor).capitalize()

func benefactor_warning() -> String:
	if benefactor == &"":
		return "BoonDef %s has empty benefactor role-id." % boon_id
	if not VALID_BENEFACTOR_IDS.has(benefactor):
		return "BoonDef %s has unknown benefactor role-id '%s'." % [boon_id, benefactor]
	return ""

func validate_benefactor() -> bool:
	var warning := benefactor_warning()
	if not warning.is_empty():
		push_warning(warning)
		return false
	if benefactor_display_name.is_empty():
		benefactor_display_name = benefactor_placeholder_display_name()
	return true

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
