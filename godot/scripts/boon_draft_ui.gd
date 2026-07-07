class_name BoonDraftUI
extends Control

const BoonDef := preload("res://scripts/boons/boon_def.gd")

signal boon_chosen(boon: BoonDef)
signal reveal_finished()

const CARD_PATHS: Array[NodePath] = [
	^"SafeArea/Content/OfferRow/Card1",
	^"SafeArea/Content/OfferRow/Card2",
	^"SafeArea/Content/OfferRow/Card3",
]
# Design-system tokens (gizmo-design-system/tokens): ink.deep card ground,
# ink.warm hover, metal.gilt_shadow inner frame, metal.gold_lit gain lines,
# accent.crimson trade-off cost lines, ground.parchment body text.
const CARD_BACKGROUND := Color(0.1098, 0.0902, 0.098, 0.96)
const CARD_BACKGROUND_HOVER := Color(0.2078, 0.1725, 0.1686, 0.97)
const CARD_BACKGROUND_PRESSED := Color(0.0784, 0.0627, 0.0667, 0.98)
const DISABLED_BORDER := Color(0.35, 0.29, 0.22, 0.45)
const FOCUS_BORDER := Color(0.9922, 0.9373, 0.8706, 1.0)
const BENEFACTOR_LABEL_COLOR := Color(0.7412, 0.6431, 0.498, 1.0)
const GILT_FRAME_COLOR := Color(0.5098, 0.4, 0.3059, 0.9)
const EFFECTS_LABEL_COLOR := Color(0.8784, 0.7569, 0.4784, 1.0)
const COST_LABEL_COLOR := Color(0.8549, 0.2196, 0.2314, 1.0)

const SHADE_BASE := Color(0.0353, 0.0392, 0.0549, 0.78)
const SHADE_LEGENDARY := Color(0.0196, 0.0157, 0.0235, 0.88)
const REVEAL_BEAT_EPIC := 0.45
const REVEAL_BEAT_LEGENDARY := 0.9

var _cards: Array[Button] = []
var _offers: Array[BoonDef] = []
var _selection_locked := false
var _buttons_connected := false
var _has_presented := false
var _reveal_done := true
var _reveal_serial := 0

func _ready() -> void:
	_cache_cards()
	_connect_card_buttons()
	_wire_focus_neighbors()
	if not _has_presented:
		for card in _cards:
			_clear_card(card)
		visible = false
	set_process_unhandled_input(true)

func present(offers: Array[BoonDef]) -> void:
	_cache_cards()
	_connect_card_buttons()
	_wire_focus_neighbors()
	_selection_locked = false
	_has_presented = true
	_offers.clear()

	if offers.size() > CARD_PATHS.size():
		push_warning("BoonDraftUI can render at most 3 offers; got %d." % offers.size())

	var offer_count := mini(offers.size(), _cards.size())
	for i in range(offer_count):
		_offers.append(offers[i])

	for i in range(_cards.size()):
		if i < _offers.size() and _offers[i] != null:
			_populate_card(_cards[i], _offers[i])
		else:
			_clear_card(_cards[i])

	visible = true
	if not _cards.is_empty() and _cards[0].visible and not _cards[0].disabled:
		_cards[0].grab_focus()
	_begin_reveal_ceremony()

func is_reveal_finished() -> bool:
	return _reveal_done

func choose_offer(index: int) -> bool:
	if _selection_locked or not _reveal_done:
		return false
	if index < 0 or index >= _offers.size():
		return false
	var boon := _offers[index]
	if boon == null:
		return false

	_selection_locked = true
	for card in _cards:
		card.disabled = true
	_notify_audio_event(&"boon_pickup")
	boon_chosen.emit(boon)
	visible = false
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _selection_locked:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		match key_event.keycode:
			KEY_1:
				if choose_offer(0):
					get_viewport().set_input_as_handled()
			KEY_2:
				if choose_offer(1):
					get_viewport().set_input_as_handled()
			KEY_3:
				if choose_offer(2):
					get_viewport().set_input_as_handled()
			_:
				if key_event.is_action_pressed("ui_accept"):
					var focus_owner := get_viewport().gui_get_focus_owner()
					var focused_index := _cards.find(focus_owner)
					if focused_index >= 0 and choose_offer(focused_index):
						get_viewport().set_input_as_handled()

## Rarity determines the card flare: common stays quiet, rare gleams, epic
## flashes with a brief pause-beat and sting, legendary runs the full ceremony
## (deepened world-dim, pulsing card glow, its own sting). Selection unlocks
## when the beat ends; reveal_finished is the seam tests and drivers await.
func _begin_reveal_ceremony() -> void:
	_reveal_serial += 1
	var serial := _reveal_serial
	var shade := get_node_or_null("Shade") as ColorRect
	if shade != null:
		shade.color = SHADE_BASE
	var top := _top_offer_rarity()
	_flare_offer_cards()
	if top < BoonDef.Rarity.EPIC or not is_inside_tree():
		_reveal_done = true
		reveal_finished.emit()
		return

	_reveal_done = false
	var beat := REVEAL_BEAT_EPIC
	if top >= BoonDef.Rarity.LEGENDARY:
		beat = REVEAL_BEAT_LEGENDARY
		if shade != null:
			shade.color = SHADE_LEGENDARY
		_notify_audio_event(&"boon_legendary_reveal")
	else:
		_notify_audio_event(&"boon_epic_reveal")
	await get_tree().create_timer(beat).timeout
	if serial != _reveal_serial:
		return
	_reveal_done = true
	reveal_finished.emit()

func _top_offer_rarity() -> BoonDef.Rarity:
	var top := BoonDef.Rarity.COMMON
	for boon in _offers:
		if boon != null and boon.rarity > top:
			top = boon.rarity
	return top

func _flare_offer_cards() -> void:
	if not is_inside_tree():
		return
	for i in range(mini(_offers.size(), _cards.size())):
		var boon := _offers[i]
		var card := _cards[i]
		card.modulate = Color(1, 1, 1, 1)
		if boon == null or boon.rarity < BoonDef.Rarity.RARE:
			continue
		var tween := card.create_tween()
		match boon.rarity:
			BoonDef.Rarity.RARE:
				card.modulate = Color(1.18, 1.15, 1.08, 1.0)
				tween.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.35)
			BoonDef.Rarity.EPIC:
				card.modulate = Color(1.35, 1.25, 1.45, 1.0)
				tween.tween_property(card, "modulate", Color(1, 1, 1, 1), REVEAL_BEAT_EPIC)
			_:
				card.modulate = Color(1.55, 1.45, 1.1, 1.0)
				tween.tween_property(card, "modulate", Color(1.25, 1.18, 1.0, 1.0), REVEAL_BEAT_LEGENDARY * 0.5)
				tween.tween_property(card, "modulate", Color(1.45, 1.35, 1.05, 1.0), REVEAL_BEAT_LEGENDARY * 0.25)
				tween.tween_property(card, "modulate", Color(1, 1, 1, 1), REVEAL_BEAT_LEGENDARY * 0.25)

func _cache_cards() -> void:
	if _cards.size() == CARD_PATHS.size():
		return
	_cards.clear()
	for path in CARD_PATHS:
		var card := get_node(path) as Button
		if card == null:
			push_error("BoonDraftUI missing card node at %s." % path)
			continue
		_ensure_benefactor_label(card)
		_ensure_effect_labels(card)
		_ensure_gilt_frame(card)
		_cards.append(card)

func _connect_card_buttons() -> void:
	if _buttons_connected:
		return
	for i in range(_cards.size()):
		_cards[i].pressed.connect(_on_card_pressed.bind(i))
	_buttons_connected = true

func _wire_focus_neighbors() -> void:
	if _cards.is_empty():
		return
	for i in range(_cards.size()):
		var card := _cards[i]
		var previous := _cards[(i - 1 + _cards.size()) % _cards.size()]
		var next := _cards[(i + 1) % _cards.size()]
		card.focus_neighbor_left = previous.get_path()
		card.focus_neighbor_top = previous.get_path()
		card.focus_neighbor_right = next.get_path()
		card.focus_neighbor_bottom = next.get_path()

func _on_card_pressed(index: int) -> void:
	if _selection_locked:
		return
	_notify_audio_event(&"ui_click")
	choose_offer(index)

func _populate_card(card: Button, boon: BoonDef) -> void:
	card.visible = true
	card.disabled = false
	card.focus_mode = Control.FOCUS_ALL
	card.set_meta("boon_id", boon.boon_id)
	card.set_meta("rarity_label", boon.rarity_label())
	card.set_meta("slot_label", boon.slot_label())
	card.set_meta("domain", boon.domain)
	card.set_meta("benefactor", boon.benefactor)
	card.set_meta("benefactor_display_name", _benefactor_display_name_for(boon))
	_apply_card_style(card, _rarity_tint(boon.rarity))

	var rarity_label := _label_for(card, "RarityLabel")
	var benefactor_label := _label_for(card, "BenefactorLabel")
	var name_label := _label_for(card, "NameLabel")
	var domain_label := _label_for(card, "DomainLabel")
	var slot_label := _label_for(card, "SlotLabel")
	var description_label := _label_for(card, "DescriptionLabel")

	rarity_label.text = boon.rarity_label()
	rarity_label.add_theme_color_override("font_color", _rarity_tint(boon.rarity))
	benefactor_label.text = _benefactor_display_name_for(boon)
	name_label.text = _display_name_for(boon)
	domain_label.text = boon.domain if not boon.domain.is_empty() else "Unknown Domain"
	slot_label.text = "%s Slot" % boon.slot_label()
	description_label.text = boon.description

	# Shane's "number go up": the mechanical gains (and any trade-off costs)
	# sit on the card in plain numbers, above the flavor prose.
	var effects_label := _label_for(card, "EffectsLabel")
	var cost_label := _label_for(card, "CostLabel")
	effects_label.text = "\n".join(boon.effect_lines())
	effects_label.visible = not effects_label.text.is_empty()
	cost_label.text = "\n".join(boon.cost_lines())
	cost_label.visible = not cost_label.text.is_empty()

func _clear_card(card: Button) -> void:
	card.visible = false
	card.disabled = true
	card.focus_mode = Control.FOCUS_NONE
	card.remove_theme_stylebox_override("normal")
	card.remove_theme_stylebox_override("hover")
	card.remove_theme_stylebox_override("pressed")
	card.remove_theme_stylebox_override("focus")
	_apply_card_style(card, DISABLED_BORDER)
	for key in ["boon_id", "rarity_label", "slot_label", "domain", "benefactor", "benefactor_display_name"]:
		if card.has_meta(key):
			card.remove_meta(key)
	for label_name in ["RarityLabel", "BenefactorLabel", "NameLabel", "DomainLabel", "SlotLabel", "DescriptionLabel", "EffectsLabel", "CostLabel"]:
		_label_for(card, label_name).text = ""

func _label_for(card: Button, label_name: String) -> Label:
	if label_name == "BenefactorLabel":
		_ensure_benefactor_label(card)
	elif label_name == "EffectsLabel" or label_name == "CostLabel":
		_ensure_effect_labels(card)
	return card.get_node("Margin/VBox/%s" % label_name) as Label

func _ensure_benefactor_label(card: Button) -> void:
	var vbox := card.get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox == null or vbox.has_node("BenefactorLabel"):
		return

	var label := Label.new()
	label.name = "BenefactorLabel"
	label.theme_type_variation = &"CapsLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", BENEFACTOR_LABEL_COLOR)
	label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(label)

	var name_label := vbox.get_node_or_null("NameLabel") as Label
	if name_label != null:
		vbox.move_child(label, name_label.get_index())

func _ensure_effect_labels(card: Button) -> void:
	var vbox := card.get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox == null or vbox.has_node("EffectsLabel"):
		return

	var effects_label := Label.new()
	effects_label.name = "EffectsLabel"
	effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effects_label.add_theme_color_override("font_color", EFFECTS_LABEL_COLOR)
	effects_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(effects_label)

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cost_label.add_theme_color_override("font_color", COST_LABEL_COLOR)
	cost_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(cost_label)

	var description_label := vbox.get_node_or_null("DescriptionLabel") as Label
	if description_label != null:
		vbox.move_child(effects_label, description_label.get_index())
		vbox.move_child(cost_label, description_label.get_index())

## Manuscript double-rule: a hairline gilt frame inset inside the rarity border
## (design-canon filigree idiom, silhouette-safe for the card panel).
func _ensure_gilt_frame(card: Button) -> void:
	if card.has_node("GiltFrame"):
		return
	var frame := Panel.new()
	frame.name = "GiltFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 7.0
	frame.offset_top = 7.0
	frame.offset_right = -7.0
	frame.offset_bottom = -7.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = GILT_FRAME_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	frame.add_theme_stylebox_override("panel", style)
	card.add_child(frame)
	card.move_child(frame, 0)

func _display_name_for(boon: BoonDef) -> String:
	if not boon.display_name.is_empty():
		return boon.display_name
	return String(boon.boon_id).capitalize()

func _benefactor_display_name_for(boon: BoonDef) -> String:
	var warning := boon.benefactor_warning()
	if not warning.is_empty():
		push_warning("BoonDraftUI rendering invalid benefactor: %s" % warning)
	if not boon.benefactor_display_name.is_empty():
		return boon.benefactor_display_name
	var placeholder := boon.benefactor_placeholder_display_name()
	return placeholder if not placeholder.is_empty() else "Unknown Benefactor"

func _rarity_tint(rarity: BoonDef.Rarity) -> Color:
	match rarity:
		BoonDef.Rarity.COMMON:
			return Color(0.7412, 0.6431, 0.4980, 1.0)
		BoonDef.Rarity.RARE:
			return Color(0.4078, 0.7608, 0.8000, 1.0)
		BoonDef.Rarity.EPIC:
			return Color(0.6078, 0.4353, 0.8118, 1.0)
		BoonDef.Rarity.LEGENDARY:
			return Color(0.9059, 0.7176, 0.2824, 1.0)
		_:
			return Color(0.7412, 0.5176, 0.4078, 1.0)

func _apply_card_style(card: Button, border_color: Color) -> void:
	card.add_theme_stylebox_override("normal", _make_card_style(CARD_BACKGROUND, border_color, 3))
	card.add_theme_stylebox_override("hover", _make_card_style(CARD_BACKGROUND_HOVER, border_color.lightened(0.12), 4))
	card.add_theme_stylebox_override("pressed", _make_card_style(CARD_BACKGROUND_PRESSED, border_color.darkened(0.14), 4))
	card.add_theme_stylebox_override("focus", _make_card_style(Color(0, 0, 0, 0), FOCUS_BORDER, 4))

func _make_card_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 8
	return style

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)
