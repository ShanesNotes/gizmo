class_name BoonDraft
extends RefCounted

const BoonDef := preload("res://scripts/boons/boon_def.gd")

## Run-scoped boon draft state and weighted offer roller. This object is not
## persistent; RunLifecycle resets it after death before a new run starts.

signal draft_offered(room: RoomNode, next_room_ids: Array[String], offers: Array[BoonDef])
signal boon_accepted(boon: BoonDef)
signal draft_reset()

const DEFAULT_OFFER_COUNT: int = 3
const COMMON_WEIGHT: float = 60.0
const RARE_WEIGHT: float = 25.0
const EPIC_WEIGHT: float = 10.0
const LEGENDARY_WEIGHT: float = 3.0

var picked_boons: Array[BoonDef] = []
var picked_boon_ids: Array[StringName] = []
var picked_boons_by_slot: Dictionary = {}
var _installed_ability_kit: AbilityComponent
var _installed_runtime_modifiers: Array[AbilityModifier] = []
## Pre-draft snapshots of the exported params boons may touch, so slot
## replacement and run reset always rebuild from the true base values.
var _vitals_base: Dictionary = {}
var _cast_ammo_base: int = -1

static func rarity_weight_for(rarity: BoonDef.Rarity) -> float:
	match rarity:
		BoonDef.Rarity.COMMON:
			return COMMON_WEIGHT
		BoonDef.Rarity.RARE:
			return RARE_WEIGHT
		BoonDef.Rarity.EPIC:
			return EPIC_WEIGHT
		BoonDef.Rarity.LEGENDARY:
			return LEGENDARY_WEIGHT
		_:
			return 0.0

func offer_between_rooms(
	graph: RoomGraph,
	current_room_id: String,
	pool: Array[BoonDef],
	rng: RandomNumberGenerator,
	offer_count: int = DEFAULT_OFFER_COUNT
) -> Array[BoonDef]:
	if graph == null:
		return []
	var room := graph.get_room(current_room_id)
	if room == null or room.state != RoomNode.State.CLEARED:
		return []
	var next_room_ids := graph.get_next_room_ids(current_room_id)
	if next_room_ids.is_empty():
		return []

	var offers := roll_offer(pool, offer_count, rng, picked_boon_ids)
	draft_offered.emit(room, next_room_ids, offers)
	return offers

func roll_offer(
	pool: Array[BoonDef],
	offer_count: int,
	rng: RandomNumberGenerator,
	already_picked_ids: Array[StringName] = []
) -> Array[BoonDef]:
	var offers: Array[BoonDef] = []
	if offer_count <= 0 or pool.is_empty():
		return offers

	var active_rng := rng
	if active_rng == null:
		active_rng = RandomNumberGenerator.new()
		active_rng.randomize()

	var candidates := _eligible_unique_pool(pool, already_picked_ids)
	while offers.size() < offer_count and not candidates.is_empty():
		var selected_index := _pick_weighted_index(candidates, active_rng)
		var boon := candidates[selected_index]
		offers.append(boon)
		candidates.remove_at(selected_index)
	return offers

func accept_boon(boon: BoonDef, ability_kit: AbilityComponent) -> bool:
	if boon == null or boon.boon_id == &"":
		return false
	if ability_kit == null:
		return false
	if picked_boon_ids.has(boon.boon_id):
		return false

	var previous_boon := picked_boons_by_slot.get(boon.slot) as BoonDef
	if previous_boon != null:
		_remove_picked_boon(previous_boon)

	picked_boons_by_slot[boon.slot] = boon
	picked_boons.append(boon)
	picked_boon_ids.append(boon.boon_id)
	_reinstall_picked_boon_effects(ability_kit)
	boon_accepted.emit(boon)
	return true

func picked_boon_for_slot(slot: BoonDef.Slot) -> BoonDef:
	return picked_boons_by_slot.get(slot) as BoonDef

func reset_run() -> void:
	_remove_installed_effects()
	picked_boons.clear()
	picked_boon_ids.clear()
	picked_boons_by_slot.clear()
	draft_reset.emit()

## True while `boon` has a picked partner (a different boon) in its synergy slot.
func synergy_active_for(boon: BoonDef) -> bool:
	if boon == null or not boon.has_synergy():
		return false
	var partner := picked_boons_by_slot.get(boon.synergy_with_slot) as BoonDef
	return partner != null and partner != boon

func _remove_picked_boon(boon: BoonDef) -> void:
	var index := picked_boons.find(boon)
	if index >= 0:
		picked_boons.remove_at(index)
	picked_boon_ids.erase(boon.boon_id)
	picked_boons_by_slot.erase(boon.slot)

func _reinstall_picked_boon_effects(ability_kit: AbilityComponent) -> void:
	_remove_installed_effects()
	_installed_ability_kit = ability_kit
	_snapshot_bases(ability_kit)
	for boon in picked_boons:
		for modifier in boon.create_runtime_modifiers():
			ability_kit.ability_modifiers.append(modifier)
			_installed_runtime_modifiers.append(modifier)
		if synergy_active_for(boon):
			for modifier in boon.synergy_ability_modifiers:
				if modifier == null:
					continue
				var runtime_modifier := modifier.duplicate(true) as AbilityModifier
				if runtime_modifier != null:
					ability_kit.ability_modifiers.append(runtime_modifier)
					_installed_runtime_modifiers.append(runtime_modifier)
	_apply_vitals_effects(ability_kit)
	_apply_cast_ammo_effects(ability_kit)

func _remove_installed_effects() -> void:
	if _installed_ability_kit != null and is_instance_valid(_installed_ability_kit):
		for modifier in _installed_runtime_modifiers:
			_installed_ability_kit.ability_modifiers.erase(modifier)
		_restore_vitals_base(_installed_ability_kit)
		_restore_cast_ammo_base(_installed_ability_kit)
	_installed_runtime_modifiers.clear()
	_installed_ability_kit = null
	_vitals_base.clear()
	_cast_ammo_base = -1

func _snapshot_bases(ability_kit: AbilityComponent) -> void:
	var vitals := _kit_vitals(ability_kit)
	if vitals != null and _vitals_base.is_empty():
		_vitals_base = {
			"guard_recharge_rate": vitals.guard_recharge_rate,
			"guard_recharge_delay": vitals.guard_recharge_delay,
			"max_guard": vitals.max_guard,
			"spark_damage_dealt_charge_rate": vitals.spark_damage_dealt_charge_rate,
		}
	var cast_ability := ability_kit.get_ability(&"cast") as CastAbility
	if cast_ability != null and _cast_ammo_base < 0:
		_cast_ammo_base = cast_ability.max_ammo

func _apply_vitals_effects(ability_kit: AbilityComponent) -> void:
	var vitals := _kit_vitals(ability_kit)
	if vitals == null or _vitals_base.is_empty():
		return
	var rate_multiplier := 1.0
	var delay_multiplier := 1.0
	var surge_multiplier := 1.0
	var guard_delta := 0
	for boon in picked_boons:
		rate_multiplier *= boon.guard_recharge_rate_multiplier
		delay_multiplier *= boon.guard_recharge_delay_multiplier
		surge_multiplier *= boon.surge_charge_rate_multiplier
		guard_delta += boon.max_guard_delta
	vitals.guard_recharge_rate = maxf(0.0, float(_vitals_base["guard_recharge_rate"]) * rate_multiplier)
	vitals.guard_recharge_delay = maxf(0.0, float(_vitals_base["guard_recharge_delay"]) * delay_multiplier)
	vitals.max_guard = maxi(0, int(_vitals_base["max_guard"]) + guard_delta)
	vitals.spark_damage_dealt_charge_rate = maxf(
		0.0, float(_vitals_base["spark_damage_dealt_charge_rate"]) * surge_multiplier
	)
	vitals.guard = mini(vitals.guard, vitals.max_guard)

func _apply_cast_ammo_effects(ability_kit: AbilityComponent) -> void:
	var cast_ability := ability_kit.get_ability(&"cast") as CastAbility
	if cast_ability == null or _cast_ammo_base < 0:
		return
	var ammo_delta := 0
	for boon in picked_boons:
		ammo_delta += boon.bonus_cast_ammo
	cast_ability.max_ammo = maxi(0, _cast_ammo_base + ammo_delta)

func _restore_vitals_base(ability_kit: AbilityComponent) -> void:
	var vitals := _kit_vitals(ability_kit)
	if vitals == null or _vitals_base.is_empty():
		return
	vitals.guard_recharge_rate = float(_vitals_base["guard_recharge_rate"])
	vitals.guard_recharge_delay = float(_vitals_base["guard_recharge_delay"])
	vitals.max_guard = int(_vitals_base["max_guard"])
	vitals.spark_damage_dealt_charge_rate = float(_vitals_base["spark_damage_dealt_charge_rate"])
	vitals.guard = mini(vitals.guard, vitals.max_guard)

func _restore_cast_ammo_base(ability_kit: AbilityComponent) -> void:
	if _cast_ammo_base < 0:
		return
	var cast_ability := ability_kit.get_ability(&"cast") as CastAbility
	if cast_ability != null:
		cast_ability.max_ammo = _cast_ammo_base

func _kit_vitals(ability_kit: AbilityComponent) -> PlayerVitals:
	if ability_kit == null:
		return null
	var vitals := ability_kit.player_vitals
	if vitals != null and is_instance_valid(vitals):
		return vitals
	return null

func _eligible_unique_pool(
	pool: Array[BoonDef],
	already_picked_ids: Array[StringName]
) -> Array[BoonDef]:
	var candidates: Array[BoonDef] = []
	var seen_ids: Dictionary = {}
	for picked_id in already_picked_ids:
		seen_ids[picked_id] = true
	for boon in pool:
		if boon == null or boon.boon_id == &"":
			continue
		if seen_ids.has(boon.boon_id):
			continue
		seen_ids[boon.boon_id] = true
		candidates.append(boon)
	return candidates

func _pick_weighted_index(candidates: Array[BoonDef], rng: RandomNumberGenerator) -> int:
	var total_weight := 0.0
	for boon in candidates:
		total_weight += rarity_weight_for(boon.rarity)
	if total_weight <= 0.0:
		return rng.randi_range(0, candidates.size() - 1)

	var roll := rng.randf() * total_weight
	var cursor := 0.0
	for i in range(candidates.size()):
		cursor += rarity_weight_for(candidates[i].rarity)
		if roll <= cursor:
			return i
	return candidates.size() - 1
