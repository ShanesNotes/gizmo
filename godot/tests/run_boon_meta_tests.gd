extends SceneTree

# Headless tests for the Hades-pivot boon draft and meta-progression slice.
# Run with:
#   godot --headless --user-data-dir /tmp/godot-user --path godot --script res://tests/run_boon_meta_tests.gd

const AbilityComponentScript := preload("res://scripts/abilities/ability_component.gd")
const AbilityModifierScript := preload("res://scripts/abilities/ability_modifier.gd")
const SpecialAbilityScript := preload("res://scripts/abilities/special_ability.gd")
const BoonDef := preload("res://scripts/boons/boon_def.gd")
const BoonDraft := preload("res://scripts/boons/boon_draft.gd")
const MetaState := preload("res://scripts/meta/meta_state.gd")
const RunLifecycle := preload("res://scripts/meta/run_lifecycle.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomGraph := preload("res://scripts/room_graph/room_graph.gd")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running boon/meta-progression tests...")
	_test_rarity_weighted_draft_offers_unique_between_rooms()
	await _test_boon_modifiers_apply_to_target_ability_kit()
	_test_meta_state_round_trips_through_config_file()
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
	_check_eq("loaded scrap bank matches saved value", loaded.scrap_banked, 37)
	_check_eq("loaded sparks bank matches saved value", loaded.sparks_banked, 5)
	_check("loaded unlocked boon id is present", loaded.is_boon_unlocked(&"spark_special_boost"))
	_check("duplicate boon unlocks are stored once", loaded.unlocked_boon_ids.size() == 2)
	DirAccess.remove_absolute(path)

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
