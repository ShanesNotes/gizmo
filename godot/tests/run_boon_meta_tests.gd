extends SceneTree

# Headless tests for the Hades-pivot boon draft and meta-progression slice.
# Run with:
#   godot --headless --user-data-dir /tmp/godot-user --path godot --script res://tests/run_boon_meta_tests.gd

const AbilityComponentScript := preload("res://scripts/abilities/ability_component.gd")
const AbilityModifierScript := preload("res://scripts/abilities/ability_modifier.gd")
const SpecialAbilityScript := preload("res://scripts/abilities/special_ability.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")
const BoonDef := preload("res://scripts/boons/boon_def.gd")
const BoonDraft := preload("res://scripts/boons/boon_draft.gd")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RunBonuses := preload("res://scripts/meta/run_bonuses.gd")
const RunLifecycle := preload("res://scripts/meta/run_lifecycle.gd")
const RunOrchestratorScript := preload("res://scripts/room_graph/run_orchestrator.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomGraph := preload("res://scripts/room_graph/room_graph.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running boon/meta-progression tests...")
	_test_benefactor_schema_role_id_display_defaults_and_validation()
	_test_benefactor_reassignment_refreshes_placeholder()
	_test_default_boon_pool_is_fully_tagged_with_valid_benefactors()
	_test_default_pool_every_entry_has_a_felt_effect()
	_test_default_pool_carries_tradeoffs_and_synergies()
	_test_effect_lines_surface_numbers_for_every_pool_entry()
	_test_rarity_weighted_draft_offers_unique_between_rooms()
	await _test_boon_modifiers_apply_to_target_ability_kit()
	await _test_attack_rarity_ladder_shrinks_ttk()
	await _test_tradeoff_keepsake_pays_a_real_vitals_cost()
	await _test_synergy_modifiers_activate_only_with_partner_slot()
	await _test_damage_keepsakes_compound_multiplicatively()
	await _test_cast_ammo_keepsake_grants_and_reverts()
	await _test_vitals_keepsake_reverts_on_reset()
	_test_meta_state_round_trips_through_config_file()
	_test_meta_state_migrates_old_schema_without_stat_grades()
	_test_stat_grade_caps_fit_price_table()
	_test_purchase_grade_deducts_scrap_and_persists()
	_test_purchase_grade_rejects_invalid_requests()
	_test_run_bonuses_from_meta_maps_grades()
	await _test_start_new_run_exposes_run_bonuses()
	await _test_death_resets_run_state_and_preserves_meta_state()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL — %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => boon/meta tests failed to load/compile)" if _passed == 0 else ""]
		)
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s" % desc)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	_check("%s (got %s, expected %s)" % [desc, actual, expected], actual == expected)

func _make_boon(
	boon_id: StringName,
	rarity: BoonDef.Rarity,
	domain: String = "spark",
	slot: BoonDef.Slot = BoonDef.Slot.PASSIVE,
) -> BoonDef:
	var boon: BoonDef = BoonDef.new()
	boon.boon_id = boon_id
	boon.display_name = String(boon_id).capitalize()
	boon.description = "Test boon"
	boon.rarity = rarity
	boon.domain = domain
	boon.slot = slot
	return boon

func _test_benefactor_schema_role_id_display_defaults_and_validation() -> void:
	var boon := _make_boon(&"schema_probe", BoonDef.Rarity.COMMON)
	boon.benefactor = &"hearthguard"

	_check_eq("BoonDef stores benefactor as role-id", boon.benefactor, &"hearthguard")
	_check_eq("benefactor display defaults to capitalized role-id", boon.benefactor_display_name, "Hearthguard")
	_check("known benefactor role-id validates", boon.validate_benefactor())

	var empty := _make_boon(&"empty_benefactor_probe", BoonDef.Rarity.COMMON)
	_check("empty benefactor role-id reports a warning", not empty.validate_benefactor())
	_check("empty benefactor warning names missing role-id", empty.benefactor_warning().contains("empty benefactor"))

	var unknown := _make_boon(&"unknown_benefactor_probe", BoonDef.Rarity.COMMON)
	unknown.benefactor = &"unknown_role"
	_check("unknown benefactor role-id reports a warning", not unknown.validate_benefactor())
	_check("unknown benefactor warning names invalid role-id", unknown.benefactor_warning().contains("unknown benefactor"))

func _test_default_boon_pool_is_fully_tagged_with_valid_benefactors() -> void:
	var orchestrator: RunOrchestrator = RunOrchestratorScript.new()
	var pool: Array[BoonDef] = orchestrator._default_boon_pool()
	var expected: Dictionary = {
		&"spark_attack": &"swordbearer",
		&"gear_dash": &"bearer",
		&"core_special": &"swordbearer",
		&"codex_cast": &"marksman",
		&"humanity_guard": &"company",
		&"ember_attack": &"swordbearer",
		&"brass_dash": &"bearer",
		&"gear_special": &"swordbearer",
		&"spark_cast": &"marksman",
		&"codex_passive": &"hearthguard",
		&"flame_attack": &"swordbearer",
		&"spring_special": &"swordbearer",
		&"volley_cast": &"marksman",
		&"company_passive": &"company",
		&"maker_attack": &"swordbearer",
		&"light_passive": &"hearthguard",
	}
	var expected_display: Dictionary = {
		&"bearer": "the Bearer",
		&"hearthguard": "the Hearthguard",
		&"swordbearer": "the Swordbearer",
		&"marksman": "the Marksman",
		&"company": "the Company",
	}
	var seen: Dictionary = {}

	_check_eq("default boon pool keeps sixteen keepsakes", pool.size(), 16)
	for boon in pool:
		seen[boon.boon_id] = boon.benefactor
		_check("%s has a benefactor role-id" % boon.boon_id, boon.benefactor != &"")
		_check("%s benefactor role-id is valid" % boon.boon_id, BoonDef.VALID_BENEFACTOR_IDS.has(boon.benefactor))
		_check_eq(
			"%s benefactor display uses the lore role-title" % boon.boon_id,
			boon.benefactor_display_name,
			String(expected_display.get(boon.benefactor, ""))
		)
		_check(
			"%s description is authored, not placeholder" % boon.boon_id,
			not boon.description.is_empty()
				and boon.description != "A run-scoped upgrade for this chamber chain."
		)
	for boon_id in expected.keys():
		_check_eq("default pool tags %s" % boon_id, seen.get(boon_id, &""), expected[boon_id])
	orchestrator.free()

func _make_rng(seed: int = 42) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng

func _make_between_room_graph() -> RoomGraph:
	var graph: RoomGraph = RoomGraph.new()
	var current_room: RoomNode = RoomNode.new()
	current_room.room_id = "room_00"
	current_room.state = RoomNode.State.CLEARED
	var next_room: RoomNode = RoomNode.new()
	next_room.room_id = "room_01"
	next_room.state = RoomNode.State.AVAILABLE
	var connection: RoomConnection = RoomConnection.new()
	connection.from_room_id = current_room.room_id
	connection.to_room_id = next_room.room_id
	connection.door_name = "RoomExit"
	graph.rooms.append(current_room)
	graph.rooms.append(next_room)
	graph.connections.append(connection)
	graph.entry_room_id = current_room.room_id
	return graph

func _make_boon_pool() -> Array[BoonDef]:
	var pool: Array[BoonDef] = []
	pool.append(_make_boon(&"spark_common_a", BoonDef.Rarity.COMMON))
	pool.append(_make_boon(&"spark_common_b", BoonDef.Rarity.COMMON))
	pool.append(_make_boon(&"scrap_rare", BoonDef.Rarity.RARE, "scrap"))
	pool.append(_make_boon(&"guard_epic", BoonDef.Rarity.EPIC, "guard"))
	pool.append(_make_boon(&"spark_legendary", BoonDef.Rarity.LEGENDARY))
	return pool

func _boon_ids(boons: Array[BoonDef]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for boon in boons:
		ids.append(boon.boon_id)
	return ids

func _test_rarity_weighted_draft_offers_unique_between_rooms() -> void:
	var draft: BoonDraft = BoonDraft.new()
	draft.picked_boon_ids.append(&"spark_common_a")
	var graph := _make_between_room_graph()
	var pool := _make_boon_pool()
	var signal_state := {
		"seen": false,
		"offer_count": 0,
	}
	var signal_next_ids: Array[String] = []
	draft.draft_offered.connect(func(_room, next_ids, offers) -> void:
		signal_state["seen"] = true
		signal_next_ids.assign(next_ids)
		signal_state["offer_count"] = offers.size()
	)

	var offers := draft.offer_between_rooms(graph, "room_00", pool, _make_rng(17), 3)
	var offer_ids := _boon_ids(offers)
	var unique_ids: Dictionary = {}
	for id in offer_ids:
		unique_ids[id] = true

	_check_eq("between-room draft offers requested count", offers.size(), 3)
	_check_eq("between-room draft offers are unique", unique_ids.size(), offers.size())
	_check("already-picked boon is excluded from offers", not offer_ids.has(&"spark_common_a"))
	_check("draft_offered signal fires at cleared-room seam", bool(signal_state["seen"]))
	_check_eq("draft signal exposes outgoing room id", signal_next_ids, ["room_01"])
	_check_eq("draft signal exposes the same offer count", int(signal_state["offer_count"]), offers.size())
	_check(
		"rarity weights favor lower Hades tiers",
		BoonDraft.rarity_weight_for(BoonDef.Rarity.COMMON)
			> BoonDraft.rarity_weight_for(BoonDef.Rarity.RARE)
			and BoonDraft.rarity_weight_for(BoonDef.Rarity.RARE)
			> BoonDraft.rarity_weight_for(BoonDef.Rarity.EPIC)
			and BoonDraft.rarity_weight_for(BoonDef.Rarity.EPIC)
			> BoonDraft.rarity_weight_for(BoonDef.Rarity.LEGENDARY)
	)

	var occupied_slot_pool: Array[BoonDef] = [
		_make_boon(&"old_special_slot", BoonDef.Rarity.COMMON, "spark", BoonDef.Slot.SPECIAL),
		_make_boon(&"new_special_slot", BoonDef.Rarity.COMMON, "spark", BoonDef.Slot.SPECIAL),
	]
	var replacement_offers := draft.roll_offer(occupied_slot_pool, 2, _make_rng(21), [&"old_special_slot"])
	_check_eq("occupied-slot replacement boon remains eligible", _boon_ids(replacement_offers), [&"new_special_slot"])

func _new_ability_kit() -> Dictionary:
	var body := CharacterBody3D.new()
	body.name = "BoonMetaHarnessBody"
	root.add_child(body)
	var kit: AbilityComponent = AbilityComponentScript.new()
	body.add_child(kit)
	await process_frame
	return {"body": body, "kit": kit}

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _test_boon_modifiers_apply_to_target_ability_kit() -> void:
	var harness := await _new_ability_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var special := kit.get_ability(&"special") as SpecialAbility
	special.cost = 0.0
	special.cooldown = 0.0
	special.cast_time = 0.0
	special.recovery_time = 0.01
	var base_potency := special.potency

	var modifier: AbilityModifier = AbilityModifierScript.new()
	modifier.modifier_id = &"special_potency_plus_25"
	modifier.target_ability_id = &"special"
	modifier.potency_delta = 25.0
	var boon := _make_boon(&"spark_special_boost", BoonDef.Rarity.RARE, "spark", BoonDef.Slot.SPECIAL)
	boon.ability_modifiers.append(modifier)
	var replacement_modifier: AbilityModifier = AbilityModifierScript.new()
	replacement_modifier.modifier_id = &"special_potency_plus_5"
	replacement_modifier.target_ability_id = &"special"
	replacement_modifier.potency_delta = 5.0
	var replacement_boon := _make_boon(&"spark_special_swap", BoonDef.Rarity.COMMON, "spark", BoonDef.Slot.SPECIAL)
	replacement_boon.ability_modifiers.append(replacement_modifier)

	var draft: BoonDraft = BoonDraft.new()
	var emitted_potencies: Array[float] = []
	kit.special_started.connect(func(potency: float) -> void:
		emitted_potencies.append(potency)
	)

	_check("accepting a boon applies it to the ability kit", draft.accept_boon(boon, kit))
	_check_eq("picked boon is tracked for this run only", draft.picked_boon_ids, [&"spark_special_boost"])
	_check_eq("one runtime modifier is installed on the kit", kit.ability_modifiers.size(), 1)
	_check("runtime modifier is duplicated, not shared authored data", kit.ability_modifiers[0] != modifier)
	var first_runtime_modifier := kit.ability_modifiers[0]
	_check("modified special activates", kit.try_activate(&"special"))
	_check_eq("runtime special potency includes boon modifier", emitted_potencies[0], base_potency + 25.0)
	_check_eq("granted base special potency remains unchanged", special.potency, base_potency)
	kit.tick(0.02)

	_check("accepting a boon in an occupied slot replaces the old boon", draft.accept_boon(replacement_boon, kit))
	_check_eq("replacement boon becomes the only picked special slot boon", draft.picked_boon_ids, [&"spark_special_swap"])
	_check_eq("picked_boon_for_slot returns the replacement", draft.picked_boon_for_slot(BoonDef.Slot.SPECIAL), replacement_boon)
	_check_eq("replacement keeps exactly one runtime modifier installed", kit.ability_modifiers.size(), 1)
	_check("old runtime modifier was removed from the kit", not kit.ability_modifiers.has(first_runtime_modifier))
	_check("replacement runtime modifier is duplicated, not shared authored data", kit.ability_modifiers[0] != replacement_modifier)
	_check("replacement-modified special activates", kit.try_activate(&"special"))
	_check_eq("replacement special potency swaps old modifier out", emitted_potencies[1], base_potency + 5.0)
	await _cleanup(body)

func _pool_boon(pool: Array[BoonDef], boon_id: StringName) -> BoonDef:
	for boon in pool:
		if boon.boon_id == boon_id:
			return boon
	return null

func _default_pool_with_orchestrator() -> Array:
	var orchestrator: RunOrchestrator = RunOrchestratorScript.new()
	return [orchestrator, orchestrator._default_boon_pool()]

func _new_vitals_kit() -> Dictionary:
	var harness := await _new_ability_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var vitals: PlayerVitals = PlayerVitalsScript.new()
	vitals.name = "PlayerVitals"
	body.add_child(vitals)
	kit.bind_player_vitals(vitals)
	await process_frame
	harness["vitals"] = vitals
	return harness

## Every draft pick must land as a real mechanical change — no flavor-only entries.
func _test_default_pool_every_entry_has_a_felt_effect() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	for boon in pool:
		_check("%s carries at least one mechanical effect" % boon.boon_id, boon.has_effects())
	orchestrator.free()

func _test_default_pool_carries_tradeoffs_and_synergies() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var tradeoffs := 0
	var synergies := 0
	for boon in pool:
		if boon.has_cost():
			tradeoffs += 1
		if boon.has_synergy():
			synergies += 1
	_check("pool holds at least two trade-off keepsakes (got %d)" % tradeoffs, tradeoffs >= 2)
	_check("pool holds at least two synergy keepsakes (got %d)" % synergies, synergies >= 2)
	orchestrator.free()

func _test_effect_lines_surface_numbers_for_every_pool_entry() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var digit_pattern := RegEx.create_from_string("\\d")
	for boon in pool:
		var lines := boon.effect_lines()
		_check("%s surfaces at least one effect line" % boon.boon_id, not lines.is_empty())
		var has_number := false
		for line in lines:
			if digit_pattern.search(line) != null:
				has_number = true
		_check("%s effect lines carry a number" % boon.boon_id, has_number)
		if boon.has_cost():
			_check("%s trade-off surfaces its cost line" % boon.boon_id, not boon.cost_lines().is_empty())
	orchestrator.free()

func _attack_damage_with_boon(kit: AbilityComponent, draft: BoonDraft, boon: BoonDef) -> float:
	if boon != null:
		draft.accept_boon(boon, kit)
	var damages: Array[float] = []
	var handler := func(_step: int, damage: float) -> void:
		damages.append(damage)
	kit.attack_started.connect(handler)
	kit.try_activate(&"attack")
	kit.attack_started.disconnect(handler)
	draft.reset_run()
	return damages[0] if not damages.is_empty() else -1.0

## Red-first probe for Shane's "number go up": the attack-slot rarity ladder must
## shrink time-to-kill measurably at every rarity step.
func _test_attack_rarity_ladder_shrinks_ttk() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var harness := await _new_ability_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var draft: BoonDraft = BoonDraft.new()

	const NOMINAL_ENEMY_HP := 120.0
	var ladder: Array[StringName] = [&"", &"spark_attack", &"ember_attack", &"flame_attack", &"maker_attack"]
	var labels := ["baseline", "common", "rare", "epic", "legendary"]
	var damages: Array[float] = []
	var hits: Array[int] = []
	for i in range(ladder.size()):
		kit.tick(5.0)
		var boon: BoonDef = null if ladder[i] == &"" else _pool_boon(pool, ladder[i])
		if ladder[i] != &"":
			_check("attack ladder finds %s in the pool" % ladder[i], boon != null)
			if boon == null:
				continue
		var damage := _attack_damage_with_boon(kit, draft, boon)
		damages.append(damage)
		hits.append(int(ceil(NOMINAL_ENEMY_HP / maxf(damage, 0.001))))

	for i in range(1, damages.size()):
		_check(
			"%s attack damage beats %s (%.1f > %.1f)" % [labels[i], labels[i - 1], damages[i], damages[i - 1]],
			damages[i] > damages[i - 1]
		)
	_check(
		"legendary TTK probe beats baseline hits-to-kill (%d < %d)" % [hits[hits.size() - 1], hits[0]],
		hits[hits.size() - 1] < hits[0]
	)
	_check(
		"epic TTK probe beats common hits-to-kill (%d < %d)" % [hits[3], hits[1]],
		hits[3] < hits[1]
	)
	orchestrator.free()
	await _cleanup(body)

## Trade-off contract: big power must carry a real, measurable cost.
func _test_tradeoff_keepsake_pays_a_real_vitals_cost() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var harness := await _new_vitals_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var vitals: PlayerVitals = harness["vitals"]
	var draft: BoonDraft = BoonDraft.new()

	var base_guard_rate := vitals.guard_recharge_rate
	var base_max_guard := vitals.max_guard
	var flame := _pool_boon(pool, &"flame_attack")
	_check("trade-off probe finds flame_attack", flame != null)
	if flame != null:
		_check("flame_attack applies", draft.accept_boon(flame, kit))
		_check(
			"flame_attack slows guard recovery (%.2f < %.2f)" % [vitals.guard_recharge_rate, base_guard_rate],
			vitals.guard_recharge_rate < base_guard_rate
		)
	draft.reset_run()
	_check_eq("reset restores guard recovery rate", vitals.guard_recharge_rate, base_guard_rate)

	var spring := _pool_boon(pool, &"spring_special")
	_check("trade-off probe finds spring_special", spring != null)
	if spring != null:
		_check("spring_special applies", draft.accept_boon(spring, kit))
		_check(
			"spring_special trims max guard (%d < %d)" % [vitals.max_guard, base_max_guard],
			vitals.max_guard < base_max_guard
		)
	draft.reset_run()
	_check_eq("reset restores max guard", vitals.max_guard, base_max_guard)
	orchestrator.free()
	await _cleanup(body)

func _cast_potency(kit: AbilityComponent) -> float:
	var potencies: Array[float] = []
	var handler := func(potency: float) -> void:
		potencies.append(potency)
	kit.cast_started.connect(handler)
	kit.try_activate(&"cast")
	kit.cast_started.disconnect(handler)
	kit.tick(5.0)
	kit.reclaim_cast_ammo(99)
	return potencies[0] if not potencies.is_empty() else -1.0

## Synergy contract: the bonus block sleeps until the partner slot is occupied.
func _test_synergy_modifiers_activate_only_with_partner_slot() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var harness := await _new_ability_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var draft: BoonDraft = BoonDraft.new()

	var base_cast := _cast_potency(kit)
	var volley := _pool_boon(pool, &"volley_cast")
	_check("synergy probe finds volley_cast", volley != null)
	_check("volley_cast targets the attack slot for synergy", volley != null and volley.synergy_with_slot == BoonDef.Slot.ATTACK)

	draft.accept_boon(volley, kit)
	var solo_cast := _cast_potency(kit)
	_check("volley_cast alone still buffs the cast (%.1f > %.1f)" % [solo_cast, base_cast], solo_cast > base_cast)

	draft.accept_boon(_pool_boon(pool, &"spark_attack"), kit)
	var paired_cast := _cast_potency(kit)
	_check(
		"attack-slot partner wakes the synergy block (%.1f > %.1f)" % [paired_cast, solo_cast],
		paired_cast > solo_cast + 0.001
	)
	draft.reset_run()
	orchestrator.free()
	await _cleanup(body)

## Multiplicative contract: damage sources stack as products, not sums.
func _test_damage_keepsakes_compound_multiplicatively() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var harness := await _new_ability_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var draft: BoonDraft = BoonDraft.new()

	var base_damage := _attack_damage_with_boon(kit, draft, null)
	kit.tick(5.0)
	draft.accept_boon(_pool_boon(pool, &"brass_dash"), kit)
	draft.accept_boon(_pool_boon(pool, &"company_passive"), kit)
	draft.accept_boon(_pool_boon(pool, &"spark_attack"), kit)
	var damages: Array[float] = []
	var handler := func(_step: int, damage: float) -> void:
		damages.append(damage)
	kit.attack_started.connect(handler)
	kit.try_activate(&"attack")
	kit.attack_started.disconnect(handler)
	var stacked := damages[0] if not damages.is_empty() else -1.0
	var additive_ceiling := base_damage * (1.0 + 0.10 + 0.20)
	_check(
		"dash+company+attack stack compounds multiplicatively (%.2f > %.2f additive ceiling would allow %.2f)"
		% [stacked, base_damage, additive_ceiling],
		stacked > additive_ceiling - 0.001
	)
	draft.reset_run()
	orchestrator.free()
	await _cleanup(body)

func _test_cast_ammo_keepsake_grants_and_reverts() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var harness := await _new_ability_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var draft: BoonDraft = BoonDraft.new()

	var base_max := kit.cast_max_ammo()
	var codex := _pool_boon(pool, &"codex_cast")
	_check("cast probe finds codex_cast", codex != null)
	_check("codex_cast declares bonus cast ammo", codex != null and codex.bonus_cast_ammo >= 1)
	draft.accept_boon(codex, kit)
	_check_eq("codex_cast raises max cast ammo immediately", kit.cast_max_ammo(), base_max + codex.bonus_cast_ammo)
	_check_eq("codex_cast grants the new shard as usable ammo", kit.cast_ammo(), base_max + codex.bonus_cast_ammo)
	draft.reset_run()
	_check_eq("reset returns max cast ammo to base", kit.cast_max_ammo(), base_max)
	orchestrator.free()
	await _cleanup(body)

func _test_vitals_keepsake_reverts_on_reset() -> void:
	var bundle := _default_pool_with_orchestrator()
	var orchestrator: RunOrchestrator = bundle[0]
	var pool: Array[BoonDef] = bundle[1]
	var harness := await _new_vitals_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var vitals: PlayerVitals = harness["vitals"]
	var draft: BoonDraft = BoonDraft.new()

	var base_rate := vitals.guard_recharge_rate
	var base_surge_rate := vitals.spark_damage_dealt_charge_rate
	draft.accept_boon(_pool_boon(pool, &"codex_passive"), kit)
	_check(
		"codex_passive speeds guard recovery (%.2f > %.2f)" % [vitals.guard_recharge_rate, base_rate],
		vitals.guard_recharge_rate > base_rate
	)
	draft.accept_boon(_pool_boon(pool, &"light_passive"), kit)
	_check(
		"light_passive speeds surge charging (%.2f > %.2f)" % [vitals.spark_damage_dealt_charge_rate, base_surge_rate],
		vitals.spark_damage_dealt_charge_rate > base_surge_rate
	)
	_check_eq(
		"passive slot replacement drops the earlier vitals effect",
		vitals.guard_recharge_rate,
		base_rate
	)
	draft.reset_run()
	_check_eq("reset restores guard rate", vitals.guard_recharge_rate, base_rate)
	_check_eq("reset restores surge charge rate", vitals.spark_damage_dealt_charge_rate, base_surge_rate)
	orchestrator.free()
	await _cleanup(body)

func _test_meta_state_round_trips_through_config_file() -> void:
	var path := "/tmp/gizmo_hades_meta_state_test.cfg"
	DirAccess.remove_absolute(path)

	var state: MetaState = MetaState.new()
	state.bank_currency(37, 5)
	state.unlock_boon(&"spark_special_boost")
	state.unlock_boon(&"guard_dash")
	state.unlock_boon(&"guard_dash")
	var save_error := state.save_to_path(path)
	var loaded = MetaState.load_from_path(path)

	_check_eq("meta save returns OK", save_error, OK)
	_check_eq("loaded meta schema migrates to current version", loaded.schema_version, MetaState.CURRENT_SCHEMA_VERSION)
	_check_eq("loaded meta migrates missing stat grades to zero", loaded.get_stat_grade("dash_charges"), 0)
	_check_eq("loaded scrap bank matches saved value", loaded.scrap_banked, 37)
	_check_eq("loaded sparks bank matches saved value", loaded.sparks_banked, 5)
	_check("loaded unlocked boon id is present", loaded.is_boon_unlocked(&"spark_special_boost"))
	_check("duplicate boon unlocks are stored once", loaded.unlocked_boon_ids.size() == 2)
	DirAccess.remove_absolute(path)

func _test_meta_state_migrates_old_schema_without_stat_grades() -> void:
	var path := "/tmp/gizmo_hades_meta_state_v1_migration_test.cfg"
	DirAccess.remove_absolute(path)

	var old_cfg := (
		"[meta]\n"
		+ "schema_version=1\n"
		+ "\n"
		+ "[currency]\n"
		+ "scrap_banked=42\n"
		+ "sparks_banked=3\n"
	)
	var write_error := FileAccess.open(path, FileAccess.WRITE)
	_check("old-schema cfg can be written to temp path", write_error != null)
	if write_error != null:
		write_error.store_string(old_cfg)
		write_error.close()

	var loaded: MetaState = MetaState.load_from_path(path)
	_check_eq("v1 migration defaults dash_charges grade to zero", loaded.get_stat_grade("dash_charges"), 0)
	_check_eq("v1 migration defaults guard_max grade to zero", loaded.get_stat_grade("guard_max"), 0)
	_check_eq("v1 migration defaults draft_rerolls grade to zero", loaded.get_stat_grade("draft_rerolls"), 0)
	_check_eq("v1 migration preserves scrap_banked", loaded.scrap_banked, 42)
	_check_eq("v1 migration preserves sparks_banked", loaded.sparks_banked, 3)

	var save_error: Error = loaded.save_to_path(path)
	var reloaded: MetaState = MetaState.load_from_path(path)
	_check_eq("v1 migration save returns OK", save_error, OK)
	_check_eq(
		"v1 migration re-save writes current schema version",
		reloaded.schema_version,
		MetaState.CURRENT_SCHEMA_VERSION
	)
	DirAccess.remove_absolute(path)

func _test_stat_grade_caps_fit_price_table() -> void:
	for stat in MetaState.STAT_GRADE_CAPS.keys():
		var cap := int(MetaState.STAT_GRADE_CAPS[stat])
		_check(
			"stat grade cap for %s fits price table (cap=%d, prices=%d)"
			% [stat, cap, MetaState.STAT_GRADE_PRICES.size()],
			cap <= MetaState.STAT_GRADE_PRICES.size()
		)

func _test_purchase_grade_deducts_scrap_and_persists() -> void:
	var path := "/tmp/gizmo_hades_meta_grade_test.cfg"
	DirAccess.remove_absolute(path)

	var state: MetaState = MetaState.new()
	state.scrap_banked = 150
	_check("first grade purchase succeeds", state.purchase_grade("dash_charges"))
	_check_eq("rank-1 purchase costs 50 scrap", state.scrap_banked, 100)
	_check_eq("rank-1 increments grade", state.get_stat_grade("dash_charges"), 1)
	_check("second grade purchase succeeds", state.purchase_grade("dash_charges"))
	_check_eq("rank-2 purchase costs 100 scrap", state.scrap_banked, 0)
	_check_eq("rank-2 increments grade", state.get_stat_grade("dash_charges"), 2)

	var save_error := state.save_to_path(path)
	var loaded = MetaState.load_from_path(path)
	_check_eq("grade save returns OK", save_error, OK)
	_check_eq("loaded dash grade persists", loaded.get_stat_grade("dash_charges"), 2)
	_check_eq("loaded guard grade migrates to zero when absent", loaded.get_stat_grade("guard_max"), 0)
	_check_eq("loaded scrap persists after purchases", loaded.scrap_banked, 0)
	DirAccess.remove_absolute(path)

func _test_purchase_grade_rejects_invalid_requests() -> void:
	var state: MetaState = MetaState.new()
	state.scrap_banked = 200
	state.stat_grades["dash_charges"] = 2

	_check("unknown stat purchase is rejected", not state.purchase_grade("unknown_stat"))
	_check_eq("unknown stat leaves scrap unchanged", state.scrap_banked, 200)
	_check_eq("unknown stat leaves grades unchanged", state.get_stat_grade("dash_charges"), 2)

	_check("capped stat purchase is rejected", not state.purchase_grade("dash_charges"))
	_check_eq("capped stat leaves scrap unchanged", state.scrap_banked, 200)

	state.scrap_banked = 25
	_check("unaffordable purchase is rejected", not state.purchase_grade("draft_rerolls"))
	_check_eq("unaffordable purchase leaves scrap unchanged", state.scrap_banked, 25)
	_check_eq("unaffordable purchase leaves rank at zero", state.get_stat_grade("draft_rerolls"), 0)

func _test_run_bonuses_from_meta_maps_grades() -> void:
	var empty_meta: MetaState = MetaState.new()
	var zero_bonuses := RunBonuses.from_meta(empty_meta)
	_check_eq("zero grades map to zero dash charges", zero_bonuses.get("extra_dash_charges", -1), 0)
	_check_eq("zero grades map to zero guard", zero_bonuses.get("extra_guard", -1), 0)
	_check_eq("zero grades map to zero draft rerolls", zero_bonuses.get("draft_rerolls", -1), 0)

	var upgraded: MetaState = MetaState.new()
	upgraded.stat_grades["dash_charges"] = 1
	upgraded.stat_grades["guard_max"] = 2
	upgraded.stat_grades["draft_rerolls"] = 1
	var bonuses := RunBonuses.from_meta(upgraded)
	_check_eq("dash grade maps to extra dash charges", bonuses.get("extra_dash_charges", -1), 1)
	_check_eq("guard grade maps to extra guard", bonuses.get("extra_guard", -1), 2)
	_check_eq("draft reroll grade maps to draft rerolls", bonuses.get("draft_rerolls", -1), 1)

func _test_start_new_run_exposes_run_bonuses() -> void:
	var meta: MetaState = MetaState.new()
	meta.scrap_banked = 150
	meta.purchase_grade("dash_charges")
	meta.purchase_grade("draft_rerolls")
	var lifecycle: RunLifecycle = RunLifecycle.new(meta, BoonDraft.new())

	lifecycle.start_new_run("room_00")
	_check_eq("start_new_run exposes dash bonus from meta grades", lifecycle.run_bonuses.get("extra_dash_charges", -1), 1)
	_check_eq("start_new_run exposes draft reroll bonus", lifecycle.run_bonuses.get("draft_rerolls", -1), 1)
	_check_eq("start_new_run exposes zero guard when unpurchased", lifecycle.run_bonuses.get("extra_guard", -1), 0)
	_check_eq("start_new_run keeps banked scrap after purchases", meta.scrap_banked, 50)

func _test_death_resets_run_state_and_preserves_meta_state() -> void:
	var harness := await _new_ability_kit()
	var body: Node = harness["body"]
	var kit: AbilityComponent = harness["kit"]
	var meta: MetaState = MetaState.new()
	meta.scrap_banked = 10
	meta.unlock_boon(&"spark_special_boost")
	var draft: BoonDraft = BoonDraft.new()
	var lifecycle: RunLifecycle = RunLifecycle.new(meta, draft)

	lifecycle.start_new_run("room_00")
	lifecycle.add_run_currency(7, 2)
	var boon := _make_boon(&"run_only_boon", BoonDef.Rarity.COMMON)
	_check("run boon can be accepted before death", draft.accept_boon(boon, kit))
	_check_eq("run phase starts as RUNNING", lifecycle.phase, RunLifecycle.Phase.RUNNING)
	_check_eq("run-scoped boon is tracked before death", draft.picked_boon_ids.size(), 1)

	var death_error := lifecycle.handle_player_death()
	_check_eq("death flow does not require a save path", death_error, OK)
	_check_eq("death banks remaining run scrap into meta", meta.scrap_banked, 17)
	_check_eq("death banks remaining run sparks into meta", meta.sparks_banked, 2)
	_check("meta unlocks survive death", meta.is_boon_unlocked(&"spark_special_boost"))
	_check_eq("death returns lifecycle to hub phase", lifecycle.phase, RunLifecycle.Phase.HUB)
	_check_eq("death clears run scrap", lifecycle.run_scrap, 0)
	_check_eq("death clears run-scoped boon picks", draft.picked_boon_ids.size(), 0)

	lifecycle.start_new_run("room_00")
	_check_eq("new run returns to RUNNING phase", lifecycle.phase, RunLifecycle.Phase.RUNNING)
	_check_eq("new run starts without old boon picks", draft.picked_boon_ids.size(), 0)
	_check_eq("new run keeps banked meta scrap", meta.scrap_banked, 17)
	await _cleanup(body)

func _test_benefactor_reassignment_refreshes_placeholder() -> void:
	var boon := BoonDef.new()
	boon.boon_id = &"reassign_probe"
	boon.benefactor = &"bearer"
	_check_eq("first assignment derives placeholder", boon.benefactor_display_name, "Bearer")
	boon.benefactor = &"marksman"
	_check_eq("reassignment refreshes auto placeholder", boon.benefactor_display_name, "Marksman")
	boon.benefactor_display_name = "Saint Placeholder"
	boon.benefactor = &"company"
	_check_eq("lore-authored display name survives reassignment", boon.benefactor_display_name, "Saint Placeholder")
