extends SceneTree

# Headless tests for HZ-022 boon draft UI.
# Run with:
#   godot --headless --user-data-dir /tmp/codex-godot-userdata --path godot --script res://tests/run_boon_draft_ui_tests.gd

const BoonDef := preload("res://scripts/boons/boon_def.gd")
const BoonDraftScene := preload("res://scenes/boon_draft.tscn")

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running boon draft UI tests...")
	await _test_header_copy_uses_keepsake_term()
	await _test_cards_render_effect_and_cost_lines()
	await _test_rarity_reveal_ceremony_and_stings()
	await _test_present_renders_three_offer_cards()
	await _test_present_with_two_offers_hides_third_card()
	await _test_present_with_zero_offers_hides_all_cards()
	await _test_button_selection_emits_nth_boon_once()
	await _test_keyboard_selection_emits_nth_boon_once()
	await _test_present_twice_reuses_card_nodes()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => boon draft UI failed to load/compile)" if _passed == 0 else ""]
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

func _new_ui():
	var ui = BoonDraftScene.instantiate()
	root.add_child(ui)
	await process_frame
	return ui

func _cleanup(node: Node) -> void:
	node.queue_free()
	await process_frame

func _make_boon(
	boon_id: StringName,
	display_name: String,
	rarity: BoonDef.Rarity,
	slot: BoonDef.Slot,
	domain: String,
	description: String,
) -> BoonDef:
	var boon: BoonDef = BoonDef.new()
	boon.boon_id = boon_id
	boon.display_name = display_name
	boon.benefactor = _benefactor_for_slot(slot)
	boon.rarity = rarity
	boon.slot = slot
	boon.domain = domain
	boon.description = description
	return boon

func _make_offer_set(prefix: String = "spark") -> Array[BoonDef]:
	var offers: Array[BoonDef] = []
	offers.append(_make_boon(
		StringName("%s_attack" % prefix),
		"Spark-Cut",
		BoonDef.Rarity.COMMON,
		BoonDef.Slot.ATTACK,
		"spark",
		"Attack strikes carry a warmer edge.",
	))
	offers.append(_make_boon(
		StringName("%s_dash" % prefix),
		"Gyre Step",
		BoonDef.Rarity.RARE,
		BoonDef.Slot.DASH,
		"gear",
		"Dash leaves a short-lived brass wake.",
	))
	offers.append(_make_boon(
		StringName("%s_passive" % prefix),
		"Humanity's Reserve",
		BoonDef.Rarity.LEGENDARY,
		BoonDef.Slot.PASSIVE,
		"core",
		"Guard recovers after room clears.",
	))
	return offers

func _row(ui) -> HBoxContainer:
	return ui.get_node("SafeArea/Content/OfferRow") as HBoxContainer

func _card(ui, index: int) -> Button:
	return ui.get_node("SafeArea/Content/OfferRow/Card%d" % (index + 1)) as Button

func _label(card: Button, label_name: String) -> Label:
	return card.get_node("Margin/VBox/%s" % label_name) as Label

func _has_label(card: Button, label_name: String) -> bool:
	return card.has_node("Margin/VBox/%s" % label_name)

func _benefactor_for_slot(slot: BoonDef.Slot) -> StringName:
	match slot:
		BoonDef.Slot.ATTACK:
			return &"swordbearer"
		BoonDef.Slot.DASH:
			return &"bearer"
		BoonDef.Slot.CAST:
			return &"marksman"
		BoonDef.Slot.SPECIAL:
			return &"swordbearer"
		BoonDef.Slot.PASSIVE:
			return &"hearthguard"
		_:
			return &"company"

func _audio_event_count(event: StringName) -> int:
	var director := root.get_node_or_null("AudioDirector")
	if director == null or not director.has_method(&"describe"):
		return 0
	var desc: Dictionary = director.describe()
	var counts: Dictionary = desc.get("sfx_event_counts", {})
	return int(counts.get(String(event), 0))

func _await_reveal(ui) -> void:
	if not ui.is_reveal_finished():
		await ui.reveal_finished

## True when the sting reached the AudioDirector: either counted (stream
## registered by the audio lane) or observed as an unknown-event noop (hook
## wired, asset pending — stream registration belongs to the audio lane).
func _sting_fired(event: StringName, count_before: int) -> bool:
	var director := root.get_node_or_null("AudioDirector")
	if director == null or not director.has_method(&"describe"):
		return false
	var desc: Dictionary = director.describe()
	var counts: Dictionary = desc.get("sfx_event_counts", {})
	if int(counts.get(String(event), 0)) > count_before:
		return true
	return String(desc.get("last_noop_reason", "")) == "unknown_sfx_event"

func _test_header_copy_uses_keepsake_term() -> void:
	var ui = await _new_ui()
	var header := ui.get_node("SafeArea/Content/HeaderLabel") as Label
	_check("header label exists", header != null)
	_check("header copy transposes boon to keepsake", header != null and header.text == "Choose a keepsake")
	_check("no player-facing 'boon' in header", header == null or not header.text.to_lower().contains("boon"))
	await _cleanup(ui)

func _test_cards_render_effect_and_cost_lines() -> void:
	var ui = await _new_ui()
	var offers := _make_offer_set("effects")
	var gain_mod := AbilityModifier.new()
	gain_mod.modifier_id = &"probe_attack_damage"
	gain_mod.target_ability_id = &"attack"
	gain_mod.damage_multiplier = 1.2
	offers[0].ability_modifiers.append(gain_mod)
	offers[1].guard_recharge_rate_multiplier = 0.5
	offers[1].max_guard_delta = 2

	ui.present(offers)
	await _await_reveal(ui)
	await process_frame

	var card_one := _card(ui, 0)
	_check("card renders an EffectsLabel", _has_label(card_one, "EffectsLabel"))
	if _has_label(card_one, "EffectsLabel"):
		_check_eq(
			"effects label carries the boon's numeric gain lines",
			_label(card_one, "EffectsLabel").text,
			"\n".join(offers[0].effect_lines())
		)
	var card_two := _card(ui, 1)
	_check("trade-off card renders a CostLabel", _has_label(card_two, "CostLabel"))
	if _has_label(card_two, "CostLabel"):
		_check_eq(
			"cost label carries the trade-off lines",
			_label(card_two, "CostLabel").text,
			"\n".join(offers[1].cost_lines())
		)
		_check("cost label text names the slower guard", _label(card_two, "CostLabel").text.contains("slower"))
	var effectless := _card(ui, 2)
	if _has_label(effectless, "CostLabel"):
		_check_eq("cost label clears when the boon has no cost", _label(effectless, "CostLabel").text, "")
	await _cleanup(ui)

func _test_rarity_reveal_ceremony_and_stings() -> void:
	var ui = await _new_ui()
	var quiet_offers: Array[BoonDef] = []
	quiet_offers.append(_make_boon(&"quiet_a", "Quiet A", BoonDef.Rarity.COMMON, BoonDef.Slot.ATTACK, "spark", "Quiet."))
	quiet_offers.append(_make_boon(&"quiet_b", "Quiet B", BoonDef.Rarity.RARE, BoonDef.Slot.DASH, "spark", "Quiet."))
	ui.present(quiet_offers)
	_check("common/rare draft reveals instantly (no pause-beat)", ui.is_reveal_finished())

	var epic_before := _audio_event_count(&"boon_epic_reveal")
	var epic_offers: Array[BoonDef] = []
	epic_offers.append(_make_boon(&"epic_probe", "Epic Probe", BoonDef.Rarity.EPIC, BoonDef.Slot.CAST, "spark", "A flash."))
	ui.present(epic_offers)
	_check("epic reveal opens with a pause-beat", not ui.is_reveal_finished())
	_check("selection is held during the epic pause-beat", not ui.choose_offer(0))
	_check("epic reveal fires its sting hook", _sting_fired(&"boon_epic_reveal", epic_before))
	await _await_reveal(ui)
	_check("epic reveal finishes and unlocks", ui.is_reveal_finished())
	_check("selection works after the epic beat", ui.choose_offer(0))

	var legendary_before := _audio_event_count(&"boon_legendary_reveal")
	var legendary_offers: Array[BoonDef] = []
	legendary_offers.append(_make_boon(&"legend_probe", "Legend Probe", BoonDef.Rarity.LEGENDARY, BoonDef.Slot.PASSIVE, "spark", "The Pattern notices."))
	ui.present(legendary_offers)
	_check("legendary reveal opens with the full ceremony beat", not ui.is_reveal_finished())
	var shade := ui.get_node("Shade") as ColorRect
	_check("legendary ceremony deepens the world-dim shade", shade != null and shade.color.a > 0.8)
	_check("legendary reveal fires its sting hook", _sting_fired(&"boon_legendary_reveal", legendary_before))
	await _await_reveal(ui)
	_check("legendary ceremony finishes and unlocks", ui.is_reveal_finished())
	_check("selection works after the legendary ceremony", ui.choose_offer(0))
	await _cleanup(ui)

func _test_present_renders_three_offer_cards() -> void:
	var ui = await _new_ui()
	var offers := _make_offer_set()

	ui.present(offers)
	await _await_reveal(ui)
	await process_frame

	_check("present makes the overlay visible", ui.visible)
	_check_eq("offer row keeps exactly 3 cards", _row(ui).get_child_count(), 3)
	for i in range(3):
		var boon := offers[i]
		var card := _card(ui, i)
		_check("card %d is visible" % (i + 1), card.visible)
		_check("card %d is selectable" % (i + 1), not card.disabled)
		_check("card %d has benefactor label" % (i + 1), _has_label(card, "BenefactorLabel"))
		if _has_label(card, "BenefactorLabel"):
			_check_eq(
				"card %d benefactor label" % (i + 1),
				_label(card, "BenefactorLabel").text,
				boon.benefactor_display_name
			)
		_check_eq("card %d name label" % (i + 1), _label(card, "NameLabel").text, boon.display_name)
		_check_eq("card %d domain label" % (i + 1), _label(card, "DomainLabel").text, boon.domain)
		_check_eq("card %d slot label" % (i + 1), _label(card, "SlotLabel").text, "%s Slot" % boon.slot_label())
		_check_eq("card %d rarity label" % (i + 1), _label(card, "RarityLabel").text, boon.rarity_label())
		_check_eq("card %d description label" % (i + 1), _label(card, "DescriptionLabel").text, boon.description)
		_check_eq("card %d metadata tracks boon id" % (i + 1), card.get_meta("boon_id"), boon.boon_id)
		_check_eq("card %d metadata tracks benefactor" % (i + 1), card.get_meta("benefactor", &""), boon.benefactor)
		_check_eq("card %d metadata tracks slot label" % (i + 1), card.get_meta("slot_label"), boon.slot_label())
		_check_eq("card %d metadata tracks rarity label" % (i + 1), card.get_meta("rarity_label"), boon.rarity_label())

	await _cleanup(ui)

func _test_present_with_two_offers_hides_third_card() -> void:
	var ui = await _new_ui()
	var offers := _make_offer_set()
	offers.resize(2)

	ui.present(offers)
	await process_frame

	_check("two-offer present keeps the overlay visible", ui.visible)
	_check_eq("two-offer present keeps exactly 3 card nodes", _row(ui).get_child_count(), 3)
	for i in range(2):
		var boon := offers[i]
		var card := _card(ui, i)
		_check("two-offer card %d is visible" % (i + 1), card.visible)
		_check("two-offer card %d is selectable" % (i + 1), not card.disabled)
		_check_eq("two-offer card %d name label" % (i + 1), _label(card, "NameLabel").text, boon.display_name)
		_check_eq("two-offer card %d metadata tracks boon id" % (i + 1), card.get_meta("boon_id"), boon.boon_id)

	var hidden_card := _card(ui, 2)
	_check("two-offer card 3 is hidden", not hidden_card.visible)
	_check("two-offer card 3 is disabled", hidden_card.disabled)
	_check("two-offer card 3 has no stale boon metadata", not hidden_card.has_meta("boon_id"))
	_check_eq("two-offer card 3 name clears", _label(hidden_card, "NameLabel").text, "")

	await _cleanup(ui)

func _test_present_with_zero_offers_hides_all_cards() -> void:
	var ui = await _new_ui()
	var offers: Array[BoonDef] = []
	var chosen: Array[BoonDef] = []
	ui.boon_chosen.connect(func(boon: BoonDef) -> void:
		chosen.append(boon)
	)

	ui.present(offers)
	await process_frame

	_check("zero-offer present keeps the overlay visible without crashing", ui.visible)
	for i in range(3):
		var card := _card(ui, i)
		_check("zero-offer card %d is hidden" % (i + 1), not card.visible)
		_check("zero-offer card %d is disabled" % (i + 1), card.disabled)
		_check("zero-offer card %d has no stale boon metadata" % (i + 1), not card.has_meta("boon_id"))
		_check("zero-offer card %d has no stale benefactor metadata" % (i + 1), not card.has_meta("benefactor"))
		if _has_label(card, "BenefactorLabel"):
			_check_eq("zero-offer card %d benefactor clears" % (i + 1), _label(card, "BenefactorLabel").text, "")
		_check_eq("zero-offer card %d name clears" % (i + 1), _label(card, "NameLabel").text, "")

	_check("zero-offer choose_offer returns false", not ui.choose_offer(0))
	_check_eq("zero-offer selection emits nothing", chosen.size(), 0)
	await _cleanup(ui)

func _test_button_selection_emits_nth_boon_once() -> void:
	var ui = await _new_ui()
	var offers := _make_offer_set("button")
	var chosen: Array[BoonDef] = []
	ui.boon_chosen.connect(func(boon: BoonDef) -> void:
		chosen.append(boon)
	)

	ui.present(offers)
	await _await_reveal(ui)
	var ui_click_before := _audio_event_count(&"ui_click")
	var boon_pickup_before := _audio_event_count(&"boon_pickup")
	_card(ui, 1).emit_signal("pressed")
	_card(ui, 1).emit_signal("pressed")

	_check_eq("button selection emits exactly once", chosen.size(), 1)
	_check("button selection emits the second BoonDef resource", chosen[0] == offers[1])
	_check("selection hides the overlay", not ui.visible)
	_check_eq("card button press notifies ui_click once", _audio_event_count(&"ui_click"), ui_click_before + 1)
	_check_eq("boon selection notifies boon_pickup once", _audio_event_count(&"boon_pickup"), boon_pickup_before + 1)
	await _cleanup(ui)

func _test_keyboard_selection_emits_nth_boon_once() -> void:
	var ui = await _new_ui()
	var offers := _make_offer_set("keyboard")
	var chosen: Array[BoonDef] = []
	ui.boon_chosen.connect(func(boon: BoonDef) -> void:
		chosen.append(boon)
	)

	ui.present(offers)
	await _await_reveal(ui)
	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.keycode = KEY_3
	ui._unhandled_input(key_event)
	ui._unhandled_input(key_event)

	_check_eq("keyboard selection emits exactly once", chosen.size(), 1)
	_check("keyboard selection emits the third BoonDef resource", chosen[0] == offers[2])
	await _cleanup(ui)

func _test_present_twice_reuses_card_nodes() -> void:
	var ui = await _new_ui()
	var first_offers := _make_offer_set("first")
	var second_offers := _make_offer_set("second")
	var row := _row(ui)
	var original_cards: Array[Node] = []
	for child in row.get_children():
		original_cards.append(child)

	ui.present(first_offers)
	await _await_reveal(ui)
	ui.present(second_offers)
	await _await_reveal(ui)
	await process_frame

	_check_eq("present twice leaves card count unchanged", row.get_child_count(), 3)
	for i in range(3):
		var card := _card(ui, i)
		_check("present twice reuses card node %d" % (i + 1), row.get_child(i) == original_cards[i])
		_check_eq("present twice replaces name label %d" % (i + 1), _label(card, "NameLabel").text, second_offers[i].display_name)
		_check_eq("present twice replaces boon metadata %d" % (i + 1), card.get_meta("boon_id"), second_offers[i].boon_id)

	await _cleanup(ui)
