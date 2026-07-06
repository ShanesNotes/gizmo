extends SceneTree

# Headless tests for HZ-023 RunFlowBridge.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_flow_bridge_tests.gd

const AbilityComponentScript := preload("res://scripts/abilities/ability_component.gd")
const BoonDef := preload("res://scripts/boons/boon_def.gd")
const BoonDraft := preload("res://scripts/boons/boon_draft.gd")
const BoonDraftScene := preload("res://scenes/boon_draft.tscn")
const RoomConnection := preload("res://scripts/room_graph/room_connection.gd")
const RoomGraph := preload("res://scripts/room_graph/room_graph.gd")
const RoomNode := preload("res://scripts/room_graph/room_node.gd")
const RoomTemplate := preload("res://scripts/room_graph/room_template.gd")
const RunControllerScript := preload("res://scripts/room_graph/run_controller.gd")
const RunFlowBridgeScript := preload("res://scripts/room_graph/run_flow_bridge.gd")

class StubBoonDraftUI:
	extends Node

	signal boon_chosen(boon)

	var event_log: Array[String] = []
	var presented_offers: Array = []
	var present_count := 0

	func present(offers: Array) -> void:
		present_count += 1
		presented_offers.assign(offers)
		event_log.append("present")

	func choose(index: int) -> void:
		if index < 0 or index >= presented_offers.size():
			return
		boon_chosen.emit(presented_offers[index])

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running RunFlowBridge tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	await _test_boon_exit_presents_draft_before_advance_and_advances_after_pick()
	await _test_boon_exit_with_short_pool_presents_short_draft()
	await _test_boon_exit_with_empty_pool_grants_scrap_fallback()
	await _test_non_boon_rewards_emit_payload_and_advance_immediately()
	_test_reward_type_vocabulary_includes_rest_reward()
	await _test_rest_reward_exits_emit_reward_without_draft()
	await _test_non_boon_rejected_exit_does_not_open_draft()
	await _test_boon_exit_rejected_before_draft_when_destination_locked()
	await _test_reentrant_boon_exit_request_is_rejected_until_choice()
	await _test_boon_exit_rejection_clears_draft_state()
	await _test_real_boon_draft_ui_satisfies_bridge_contract_headless()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => RunFlowBridge failed to load/compile)" if _passed == 0 else ""]
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

func _test_boon_exit_presents_draft_before_advance_and_advances_after_pick() -> void:
	var harness := _make_harness(RoomNode.RewardType.BOON)
	var bridge = harness["bridge"]
	var controller = harness["controller"]
	var draft: BoonDraft = harness["draft"]
	var ui: StubBoonDraftUI = harness["ui"]
	var graph: RoomGraph = harness["graph"]
	var connection: RoomConnection = harness["connection"]
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_01")
	var event_log: Array[String] = []
	ui.event_log = event_log
	draft.draft_offered.connect(func(_room, _next_ids, _offers) -> void:
		event_log.append("draft_offered")
	)
	draft.boon_accepted.connect(func(_boon) -> void:
		event_log.append("accepted")
	)
	controller.room_entered.connect(func(_room) -> void:
		event_log.append("entered")
	)
	var completions: Array[bool] = []
	bridge.exit_completed.connect(func(_connection, accepted: bool) -> void:
		completions.append(accepted)
	)

	bridge.request_exit(connection)
	await process_frame

	_check_eq("BOON request presents exactly one draft", ui.present_count, 1)
	_check_eq("BOON draft rolls three offers", ui.presented_offers.size(), 3)
	_check_eq("draft is presented before room advance", event_log, ["draft_offered", "present"])
	_check_eq("current room remains CLEARED while draft is open", current.state, RoomNode.State.CLEARED)
	_check_eq("destination remains AVAILABLE while draft is open", destination.state, RoomNode.State.AVAILABLE)
	_check_eq("controller has not advanced before pick", controller.current_room_id, "room_00")
	_check("bridge reports an open draft", bridge.is_draft_open())

	var chosen: BoonDef = ui.presented_offers[1]
	ui.choose(1)
	await process_frame

	_check_eq("BOON request completes successfully", completions, [true])
	_check_eq("selected boon is accepted before room_entered", event_log, ["draft_offered", "present", "accepted", "entered"])
	_check("selected boon id is tracked", draft.picked_boon_ids.has(chosen.boon_id))
	_check_eq("current room is marked REWARDED after pick", current.state, RoomNode.State.REWARDED)
	_check_eq("destination room becomes current after pick", controller.current_room_id, destination.room_id)
	_check_eq("destination room is ENTERED after pick", destination.state, RoomNode.State.ENTERED)
	_check("draft is closed after BOON completion", not bridge.is_draft_open())
	await _cleanup_harness(harness)

func _test_boon_exit_with_short_pool_presents_short_draft() -> void:
	var short_pool: Array[BoonDef] = [
		_make_boon(&"short_attack", BoonDef.Rarity.COMMON, BoonDef.Slot.ATTACK),
		_make_boon(&"short_dash", BoonDef.Rarity.RARE, BoonDef.Slot.DASH),
	]
	var harness := _make_harness(RoomNode.RewardType.BOON, RoomNode.State.AVAILABLE, null, short_pool)
	var bridge = harness["bridge"]
	var controller = harness["controller"]
	var draft: BoonDraft = harness["draft"]
	var ui: StubBoonDraftUI = harness["ui"]
	var graph: RoomGraph = harness["graph"]
	var connection: RoomConnection = harness["connection"]
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_01")
	var completions: Array[bool] = []
	bridge.exit_completed.connect(func(_connection, accepted: bool) -> void:
		completions.append(accepted)
	)

	bridge.request_exit(connection)
	await process_frame

	_check_eq("short BOON pool still presents one draft", ui.present_count, 1)
	_check_eq("short BOON pool presents remaining offers only", ui.presented_offers.size(), 2)
	_check("short BOON pool leaves draft open for a real choice", bridge.is_draft_open())
	ui.choose(1)
	await process_frame

	_check_eq("short BOON pool completion succeeds", completions, [true])
	_check_eq("short BOON pool applies exactly one picked boon", draft.picked_boon_ids.size(), 1)
	_check_eq("short BOON pool marks current REWARDED", current.state, RoomNode.State.REWARDED)
	_check_eq("short BOON pool enters destination", destination.state, RoomNode.State.ENTERED)
	_check_eq("short BOON pool advances current_room_id", controller.current_room_id, destination.room_id)
	_check("short BOON pool closes draft after choice", not bridge.is_draft_open())
	await _cleanup_harness(harness)

func _test_boon_exit_with_empty_pool_grants_scrap_fallback() -> void:
	var empty_pool: Array[BoonDef] = []
	var harness := _make_harness(RoomNode.RewardType.BOON, RoomNode.State.AVAILABLE, null, empty_pool)
	var bridge = harness["bridge"]
	var controller = harness["controller"]
	var ui: StubBoonDraftUI = harness["ui"]
	var graph: RoomGraph = harness["graph"]
	var connection: RoomConnection = harness["connection"]
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_01")
	var granted_types: Array[int] = []
	var completions: Array[bool] = []
	bridge.reward_granted.connect(func(granted_type: RoomNode.RewardType, _connection: RoomConnection) -> void:
		granted_types.append(granted_type)
	)
	bridge.exit_completed.connect(func(_connection, accepted: bool) -> void:
		completions.append(accepted)
	)

	var accepted: bool = bridge.request_exit(connection)
	await process_frame

	_check("empty BOON pool advances through replacement reward", accepted)
	_check_eq("empty BOON pool emits Scrap replacement reward", granted_types, [RoomNode.RewardType.SCRAP])
	_check_eq("empty BOON pool never presents a draft", ui.present_count, 0)
	_check_eq("empty BOON pool reports one accepted completion", completions, [true])
	_check_eq("empty BOON pool marks current REWARDED", current.state, RoomNode.State.REWARDED)
	_check_eq("empty BOON pool enters destination", destination.state, RoomNode.State.ENTERED)
	_check_eq("empty BOON pool advances current_room_id", controller.current_room_id, destination.room_id)
	_check("empty BOON pool leaves no open draft", not bridge.is_draft_open())
	await _cleanup_harness(harness)

func _test_non_boon_rewards_emit_payload_and_advance_immediately() -> void:
	for reward_type in [
		RoomNode.RewardType.SCRAP,
		RoomNode.RewardType.SPARKS,
		RoomNode.RewardType.HAMMER,
		RoomNode.RewardType.HEAL,
		RoomNode.RewardType.SHOP,
	]:
		var harness := _make_harness(reward_type)
		var bridge = harness["bridge"]
		var controller = harness["controller"]
		var ui: StubBoonDraftUI = harness["ui"]
		var graph: RoomGraph = harness["graph"]
		var connection: RoomConnection = harness["connection"]
		var current := graph.get_room("room_00")
		var destination := graph.get_room("room_01")
		var granted_types: Array[int] = []
		var granted_connections: Array[RoomConnection] = []
		var event_log: Array[String] = []
		bridge.reward_granted.connect(func(granted_type: RoomNode.RewardType, granted_connection: RoomConnection) -> void:
			granted_types.append(granted_type)
			granted_connections.append(granted_connection)
			event_log.append("reward")
		)
		controller.room_entered.connect(func(_room) -> void:
			event_log.append("entered")
		)

		var accepted: bool = bridge.request_exit(connection)

		_check("%s reward exit advances" % _reward_name(reward_type), accepted)
		_check_eq("%s reward emits exactly once" % _reward_name(reward_type), granted_types, [reward_type])
		_check_eq("%s reward payload includes connection" % _reward_name(reward_type), granted_connections, [connection])
		_check_eq("%s reward event precedes room entry" % _reward_name(reward_type), event_log, ["reward", "entered"])
		_check_eq("%s reward does not present a boon draft" % _reward_name(reward_type), ui.present_count, 0)
		_check_eq("%s reward marks current REWARDED" % _reward_name(reward_type), current.state, RoomNode.State.REWARDED)
		_check_eq("%s reward enters destination" % _reward_name(reward_type), destination.state, RoomNode.State.ENTERED)
		_check_eq("%s reward advances current_room_id" % _reward_name(reward_type), controller.current_room_id, destination.room_id)
		_check("%s reward leaves no open draft" % _reward_name(reward_type), not bridge.is_draft_open())
		await _cleanup_harness(harness)

func _test_reward_type_vocabulary_includes_rest_reward() -> void:
	_check("RewardType exposes REST for draft suppression", RoomNode.RewardType.has("REST"))
	_check("RewardType exposes REWARD for draft suppression", RoomNode.RewardType.has("REWARD"))

func _test_rest_reward_exits_emit_reward_without_draft() -> void:
	for reward_type in [
		RoomNode.RewardType.REST,
		RoomNode.RewardType.REWARD,
	]:
		var harness := _make_harness(reward_type)
		var bridge = harness["bridge"]
		var controller = harness["controller"]
		var ui: StubBoonDraftUI = harness["ui"]
		var graph: RoomGraph = harness["graph"]
		var connection: RoomConnection = harness["connection"]
		var current := graph.get_room("room_00")
		var destination := graph.get_room("room_01")
		var granted_types: Array[int] = []
		var completions: Array[bool] = []
		bridge.reward_granted.connect(func(granted_type: RoomNode.RewardType, _connection: RoomConnection) -> void:
			granted_types.append(granted_type)
		)
		bridge.exit_completed.connect(func(_connection: RoomConnection, accepted: bool) -> void:
			completions.append(accepted)
		)

		var accepted: bool = bridge.request_exit(connection)

		_check("%s exit advances without a boon draft" % _reward_name(reward_type), accepted)
		_check_eq("%s emits reward payload" % _reward_name(reward_type), granted_types, [reward_type])
		_check_eq("%s emits one completion" % _reward_name(reward_type), completions, [true])
		_check_eq("%s never presents a draft" % _reward_name(reward_type), ui.present_count, 0)
		_check_eq("%s marks current REWARDED" % _reward_name(reward_type), current.state, RoomNode.State.REWARDED)
		_check_eq("%s enters destination" % _reward_name(reward_type), destination.state, RoomNode.State.ENTERED)
		_check_eq("%s advances current_room_id" % _reward_name(reward_type), controller.current_room_id, destination.room_id)
		_check("%s leaves no open draft" % _reward_name(reward_type), not bridge.is_draft_open())
		await _cleanup_harness(harness)

func _test_non_boon_rejected_exit_does_not_open_draft() -> void:
	var harness := _make_harness(RoomNode.RewardType.SCRAP, RoomNode.State.LOCKED)
	var bridge = harness["bridge"]
	var controller = harness["controller"]
	var ui: StubBoonDraftUI = harness["ui"]
	var graph: RoomGraph = harness["graph"]
	var connection: RoomConnection = harness["connection"]
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_01")
	var granted_types: Array[int] = []
	bridge.reward_granted.connect(func(granted_type: RoomNode.RewardType, _connection: RoomConnection) -> void:
		granted_types.append(granted_type)
	)

	var accepted: bool = bridge.request_exit(connection)

	_check("rejected non-BOON exit returns false", not accepted)
	_check_eq("rejected non-BOON still emits reward payload for later consumers", granted_types, [RoomNode.RewardType.SCRAP])
	_check_eq("rejected non-BOON leaves current room CLEARED", current.state, RoomNode.State.CLEARED)
	_check_eq("rejected non-BOON leaves destination LOCKED", destination.state, RoomNode.State.LOCKED)
	_check_eq("rejected non-BOON keeps current room id", controller.current_room_id, current.room_id)
	_check_eq("rejected non-BOON never presents a draft", ui.present_count, 0)
	_check("rejected non-BOON leaves no open draft", not bridge.is_draft_open())

	destination.state = RoomNode.State.AVAILABLE
	var retry_accepted: bool = bridge.request_exit(connection)
	_check("non-BOON bridge can retry after rejection", retry_accepted)
	_check_eq("non-BOON retry enters destination", destination.state, RoomNode.State.ENTERED)
	await _cleanup_harness(harness)

func _test_boon_exit_rejected_before_draft_when_destination_locked() -> void:
	var harness := _make_harness(RoomNode.RewardType.BOON, RoomNode.State.LOCKED)
	var bridge = harness["bridge"]
	var ui: StubBoonDraftUI = harness["ui"]
	var draft: BoonDraft = harness["draft"]
	var connection: RoomConnection = harness["connection"]
	var completions: Array[bool] = []
	bridge.exit_completed.connect(func(_connection, accepted: bool) -> void:
		completions.append(accepted)
	)

	bridge.request_exit(connection)
	await process_frame

	_check_eq("locked BOON destination reports false completion", completions, [false])
	_check_eq("locked BOON destination never presents a draft", ui.present_count, 0)
	_check_eq("locked BOON destination grants no picked boon", draft.picked_boon_ids.size(), 0)
	_check("locked BOON rejection leaves no open draft", not bridge.is_draft_open())
	await _cleanup_harness(harness)

func _test_reentrant_boon_exit_request_is_rejected_until_choice() -> void:
	var harness := _make_harness(RoomNode.RewardType.BOON)
	var bridge = harness["bridge"]
	var ui: StubBoonDraftUI = harness["ui"]
	var connection: RoomConnection = harness["connection"]
	var completions: Array[bool] = []
	bridge.exit_completed.connect(func(_connection, accepted: bool) -> void:
		completions.append(accepted)
	)

	bridge.request_exit(connection)
	await process_frame
	var rejected = bridge.request_exit(connection)

	_check("second BOON request during draft is rejected", rejected == false)
	_check_eq("reentrant request does not present a second draft", ui.present_count, 1)
	_check("first draft remains open after reentrant rejection", bridge.is_draft_open())

	ui.choose(0)
	await process_frame

	_check_eq("first BOON request still completes after reentrant rejection", completions, [true])
	_check("draft closes after first BOON request completes", not bridge.is_draft_open())
	await _cleanup_harness(harness)

func _test_boon_exit_rejection_clears_draft_state() -> void:
	var harness := _make_harness(RoomNode.RewardType.BOON, RoomNode.State.AVAILABLE)
	var bridge = harness["bridge"]
	var controller = harness["controller"]
	var draft: BoonDraft = harness["draft"]
	var ui: StubBoonDraftUI = harness["ui"]
	var graph: RoomGraph = harness["graph"]
	var connection: RoomConnection = harness["connection"]
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_01")
	var completions: Array[bool] = []
	bridge.exit_completed.connect(func(_connection, accepted: bool) -> void:
		completions.append(accepted)
	)

	bridge.request_exit(connection)
	await process_frame
	_check_eq("BOON post-pick rejection starts with one presented draft", ui.present_count, 1)
	destination.state = RoomNode.State.LOCKED
	ui.choose(0)
	await process_frame

	_check_eq("BOON rejected exit reports false completion", completions, [false])
	_check_eq("BOON rejected exit leaves current room CLEARED", current.state, RoomNode.State.CLEARED)
	_check_eq("BOON rejected exit leaves destination LOCKED", destination.state, RoomNode.State.LOCKED)
	_check_eq("BOON rejected exit keeps current room id", controller.current_room_id, current.room_id)
	_check("BOON rejected exit clears draft state", not bridge.is_draft_open())
	_check_eq("BOON rejected exit still consumes exactly one picked boon", draft.picked_boon_ids.size(), 1)

	destination.state = RoomNode.State.AVAILABLE
	bridge.request_exit(connection)
	await process_frame

	_check_eq("BOON consumed-draft retry does not present a second draft", ui.present_count, 1)
	_check_eq("BOON consumed-draft retry keeps picked-boon count at one", draft.picked_boon_ids.size(), 1)
	_check_eq("BOON retry reports success", completions, [false, true])
	_check_eq("BOON retry marks current REWARDED", current.state, RoomNode.State.REWARDED)
	_check_eq("BOON retry enters destination", destination.state, RoomNode.State.ENTERED)
	_check("BOON retry leaves no open draft", not bridge.is_draft_open())
	await _cleanup_harness(harness)

func _test_real_boon_draft_ui_satisfies_bridge_contract_headless() -> void:
	var ui = BoonDraftScene.instantiate()
	root.add_child(ui)
	await process_frame
	var harness := _make_harness(RoomNode.RewardType.BOON, RoomNode.State.AVAILABLE, ui)
	var bridge = harness["bridge"]
	var draft: BoonDraft = harness["draft"]
	var graph: RoomGraph = harness["graph"]
	var connection: RoomConnection = harness["connection"]
	var current := graph.get_room("room_00")
	var destination := graph.get_room("room_01")
	var completions: Array[bool] = []
	bridge.exit_completed.connect(func(_connection, accepted: bool) -> void:
		completions.append(accepted)
	)

	bridge.request_exit(connection)
	await process_frame

	_check("real BoonDraftUI becomes visible when presented by the bridge", ui.visible)
	_check("real BoonDraftUI accepts the third offer", ui.choose_offer(2))
	await process_frame

	_check_eq("real BoonDraftUI bridge completion succeeds", completions, [true])
	_check_eq("real BoonDraftUI pick is applied", draft.picked_boon_ids.size(), 1)
	_check_eq("real BoonDraftUI exit marks current REWARDED", current.state, RoomNode.State.REWARDED)
	_check_eq("real BoonDraftUI exit enters destination", destination.state, RoomNode.State.ENTERED)
	_check("real BoonDraftUI hides after choosing", not ui.visible)
	_check("real BoonDraftUI bridge leaves no open draft", not bridge.is_draft_open())
	await _cleanup_harness(harness)

func _make_harness(
	reward_type: RoomNode.RewardType,
	destination_state: RoomNode.State = RoomNode.State.AVAILABLE,
	initial_ui_surface: Object = null,
	initial_boon_pool: Variant = null,
) -> Dictionary:
	var graph := _make_graph(reward_type, destination_state)
	var controller = RunControllerScript.new()
	controller.name = "RunControllerHarness"
	root.add_child(controller)
	controller.graph = graph
	controller.current_room_id = graph.entry_room_id

	var draft: BoonDraft = BoonDraft.new()
	var ui_surface: Object = initial_ui_surface
	if ui_surface == null:
		ui_surface = StubBoonDraftUI.new()
	if ui_surface is Node and (ui_surface as Node).get_parent() == null:
		root.add_child(ui_surface as Node)

	var active_boon_pool: Array[BoonDef] = _make_boon_pool()
	if initial_boon_pool != null:
		active_boon_pool.clear()
		for boon in initial_boon_pool:
			if boon is BoonDef:
				active_boon_pool.append(boon as BoonDef)

	var bridge = RunFlowBridgeScript.new()
	bridge.name = "RunFlowBridgeHarness"
	root.add_child(bridge)
	bridge.configure(
		controller,
		draft,
		ui_surface,
		active_boon_pool,
		_seeded_rng(23),
		AbilityComponentScript.new()
	)

	return {
		"graph": graph,
		"controller": controller,
		"draft": draft,
		"ui": ui_surface,
		"bridge": bridge,
		"connection": graph.connections[0],
	}

func _make_graph(
	reward_type: RoomNode.RewardType,
	destination_state: RoomNode.State,
) -> RoomGraph:
	var graph := RoomGraph.new()
	graph.biome_id = "test_biome"
	graph.entry_room_id = "room_00"
	var current := _make_room("room_00", RoomTemplate.RoomType.COMBAT, RoomNode.RewardType.BOON)
	var destination := _make_room("room_01", RoomTemplate.RoomType.COMBAT, reward_type)
	current.state = RoomNode.State.CLEARED
	destination.state = destination_state
	graph.rooms.append(current)
	graph.rooms.append(destination)
	graph.connections.append(_make_connection(current.room_id, destination.room_id, "RoomExit"))
	return graph

func _make_room(
	room_id: String,
	room_type: RoomTemplate.RoomType,
	reward_type: RoomNode.RewardType,
) -> RoomNode:
	var room := RoomNode.new()
	room.room_id = room_id
	room.template = _make_template("%s_template" % room_id, room_type)
	room.reward_type = reward_type
	room.state = RoomNode.State.LOCKED
	return room

func _make_template(template_id: String, room_type: RoomTemplate.RoomType) -> RoomTemplate:
	var template := RoomTemplate.new()
	template.template_id = template_id
	template.biome_id = "test_biome"
	template.room_type = room_type
	return template

func _make_connection(from_room_id: String, to_room_id: String, door_name: String) -> RoomConnection:
	var connection := RoomConnection.new()
	connection.from_room_id = from_room_id
	connection.to_room_id = to_room_id
	connection.door_name = door_name
	return connection

func _make_boon_pool() -> Array[BoonDef]:
	var pool: Array[BoonDef] = []
	pool.append(_make_boon(&"spark_attack", BoonDef.Rarity.COMMON, BoonDef.Slot.ATTACK))
	pool.append(_make_boon(&"spark_dash", BoonDef.Rarity.RARE, BoonDef.Slot.DASH))
	pool.append(_make_boon(&"spark_special", BoonDef.Rarity.EPIC, BoonDef.Slot.SPECIAL))
	pool.append(_make_boon(&"spark_cast", BoonDef.Rarity.COMMON, BoonDef.Slot.CAST))
	pool.append(_make_boon(&"spark_passive", BoonDef.Rarity.LEGENDARY, BoonDef.Slot.PASSIVE))
	return pool

func _make_boon(
	boon_id: StringName,
	rarity: BoonDef.Rarity,
	slot: BoonDef.Slot,
) -> BoonDef:
	var boon: BoonDef = BoonDef.new()
	boon.boon_id = boon_id
	boon.display_name = String(boon_id).capitalize()
	boon.description = "Test boon for the run-flow bridge."
	boon.rarity = rarity
	boon.slot = slot
	boon.domain = "spark"
	return boon

func _seeded_rng(seed: int) -> RandomNumberGenerator:
	var seeded := RandomNumberGenerator.new()
	seeded.seed = seed
	return seeded

func _reward_name(reward_type: RoomNode.RewardType) -> String:
	match reward_type:
		RoomNode.RewardType.BOON:
			return "BOON"
		RoomNode.RewardType.SCRAP:
			return "SCRAP"
		RoomNode.RewardType.SPARKS:
			return "SPARKS"
		RoomNode.RewardType.HAMMER:
			return "HAMMER"
		RoomNode.RewardType.HEAL:
			return "HEAL"
		RoomNode.RewardType.SHOP:
			return "SHOP"
		RoomNode.RewardType.REST:
			return "REST"
		RoomNode.RewardType.REWARD:
			return "REWARD"
		_:
			return "UNKNOWN"

func _cleanup_harness(harness: Dictionary) -> void:
	for key in ["bridge", "controller", "ui"]:
		var value = harness.get(key)
		if value is Node and is_instance_valid(value):
			(value as Node).queue_free()
	await process_frame
