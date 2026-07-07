class_name BoonDraftUI
extends Control

const BoonDef := preload("res://scripts/boons/boon_def.gd")

signal boon_chosen(boon: BoonDef)

const CARD_PATHS: Array[NodePath] = [
	^"SafeArea/Content/OfferRow/Card1",
	^"SafeArea/Content/OfferRow/Card2",
	^"SafeArea/Content/OfferRow/Card3",
]
const CARD_BACKGROUND := Color(0.1098, 0.1216, 0.1373, 0.94)
const CARD_BACKGROUND_HOVER := Color(0.1451, 0.1451, 0.1647, 0.97)
const CARD_BACKGROUND_PRESSED := Color(0.0824, 0.0784, 0.0902, 0.98)
const DISABLED_BORDER := Color(0.35, 0.29, 0.22, 0.45)
const FOCUS_BORDER := Color(0.9922, 0.9373, 0.8706, 1.0)
const BENEFACTOR_LABEL_COLOR := Color(0.7412, 0.6431, 0.498, 1.0)

var _cards: Array[Button] = []
var _offers: Array[BoonDef] = []
var _selection_locked := false
var _buttons_connected := false
var _has_presented := false

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

func choose_offer(index: int) -> bool:
	if _selection_locked:
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
	for label_name in ["RarityLabel", "BenefactorLabel", "NameLabel", "DomainLabel", "SlotLabel", "DescriptionLabel"]:
		_label_for(card, label_name).text = ""

func _label_for(card: Button, label_name: String) -> Label:
	if label_name == "BenefactorLabel":
		_ensure_benefactor_label(card)
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
