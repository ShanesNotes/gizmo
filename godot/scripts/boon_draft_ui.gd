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
# Manuscript page colors. D7 in the design canon lets UI/codex surfaces read as
# parchment pages held against the violet world, while rarity stays illumination.
const CARD_MINIMUM_SIZE := Vector2(300.0, 440.0)
const CARD_BACKGROUND := Color(0.9804, 0.8980, 0.8000, 1.0) # #fae5cc
const CARD_BACKGROUND_HOVER := Color(1.0000, 0.9451, 0.8392, 1.0)
const CARD_BACKGROUND_PRESSED := Color(0.9333, 0.8157, 0.6667, 1.0)
const INK_TEXT := Color(0.2078, 0.1725, 0.1686, 1.0) # #352c2b
const INK_MUTED := Color(0.3216, 0.2667, 0.2471, 1.0)
const BRASS_FRAME := Color(0.6902, 0.5529, 0.3412, 1.0) # #b08d57
const GOLD_FRAME := Color(0.8784, 0.7569, 0.4784, 1.0) # #e0c17a
const RARE_FRAME := Color(0.3216, 0.7098, 0.6863, 1.0) # #52b5af
const EPIC_FRAME := Color(0.5412, 0.3569, 0.6902, 1.0) # #8a5bb0
const THORN_BORDER := Color(0.1098, 0.0902, 0.0980, 1.0) # #1c1719
const THORN_ACCENT := Color(0.4941, 0.1059, 0.0863, 1.0) # #7e1b16
const DISABLED_BORDER := Color(0.43, 0.35, 0.25, 0.42)
const FOCUS_BORDER := Color(0.9922, 0.9373, 0.7608, 1.0)
const EFFECTS_LABEL_COLOR := Color(0.3569, 0.3294, 0.1765, 1.0)
const COST_LABEL_COLOR := THORN_ACCENT

const SHADE_BASE := Color(0.1059, 0.0706, 0.1804, 0.82)
const SHADE_LEGENDARY := Color(0.0471, 0.0314, 0.0784, 0.90)
const REVEAL_BEAT_EPIC := 0.45
const REVEAL_BEAT_LEGENDARY := 0.9
const REVEAL_SCALE_TIME := 0.25
const REVEAL_START_SCALE := Vector2(0.92, 0.92)
const LIFT_SCALE := Vector2(1.03, 1.03)

var _cards: Array[Button] = []
var _offers: Array[BoonDef] = []
var _selection_locked := false
var _buttons_connected := false
var _has_presented := false
var _reveal_done := true
var _reveal_serial := 0
var _lift_tweens: Dictionary = {}
var _reveal_tweens: Dictionary = {}

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
	_begin_reveal_ceremony()
	if not _cards.is_empty() and _cards[0].visible and not _cards[0].disabled:
		_cards[0].grab_focus()

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

func _top_offer_rarity() -> int:
	var top := BoonDef.Rarity.COMMON
	for boon in _offers:
		var rarity := _rarity_for(boon)
		if rarity > top:
			top = rarity
	return top

func _flare_offer_cards() -> void:
	if not is_inside_tree():
		return
	for i in range(mini(_offers.size(), _cards.size())):
		var boon := _offers[i]
		var card := _cards[i]
		card.modulate = Color(1, 1, 1, 1)
		var rarity := _rarity_for(boon)
		if boon == null or rarity < BoonDef.Rarity.EPIC:
			continue
		_play_reveal_scale(card)
		_flash_card_border(card, _flash_color_for(rarity, _is_thorned_offer(boon)))
		var tint_tween := card.create_tween()
		match rarity:
			BoonDef.Rarity.EPIC:
				card.modulate = Color(1.35, 1.25, 1.45, 1.0)
				tint_tween.tween_property(card, "modulate", Color(1, 1, 1, 1), REVEAL_BEAT_EPIC)
			_:
				card.modulate = Color(1.55, 1.45, 1.1, 1.0)
				tint_tween.tween_property(card, "modulate", Color(1.25, 1.18, 1.0, 1.0), REVEAL_BEAT_LEGENDARY * 0.5)
				tint_tween.tween_property(card, "modulate", Color(1.45, 1.35, 1.05, 1.0), REVEAL_BEAT_LEGENDARY * 0.25)
				tint_tween.tween_property(card, "modulate", Color(1, 1, 1, 1), REVEAL_BEAT_LEGENDARY * 0.25)

func _cache_cards() -> void:
	if _cards.size() == CARD_PATHS.size():
		return
	_cards.clear()
	for path in CARD_PATHS:
		var card := get_node(path) as Button
		if card == null:
			push_error("BoonDraftUI missing card node at %s." % path)
			continue
		_prepare_card_layout(card)
		_ensure_benefactor_label(card)
		_ensure_effect_labels(card)
		_ensure_title_flourish(card)
		_ensure_gilt_frame(card)
		_ensure_outer_frame(card)
		_ensure_flash_frame(card)
		_cards.append(card)

func _connect_card_buttons() -> void:
	if _buttons_connected:
		return
	for i in range(_cards.size()):
		var card := _cards[i]
		card.pressed.connect(_on_card_pressed.bind(i))
		card.mouse_entered.connect(_on_card_mouse_entered.bind(card))
		card.mouse_exited.connect(_on_card_mouse_exited.bind(card))
		card.focus_entered.connect(_on_card_focus_entered.bind(card))
		card.focus_exited.connect(_on_card_focus_exited.bind(card))
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
	var rarity := _rarity_for(boon)
	var thorned := _is_thorned_offer(boon)
	var rarity_label_text := _rarity_label_for(boon)
	var slot_label_text := _slot_label_for(boon)
	var benefactor_display_name := _benefactor_display_name_for(boon)

	card.visible = true
	card.disabled = false
	card.focus_mode = Control.FOCUS_ALL
	card.scale = Vector2.ONE
	card.modulate = Color(1, 1, 1, 1)
	_set_card_pivot(card)
	card.set_meta("boon_id", _boon_id_for(boon))
	card.set_meta("rarity_label", rarity_label_text)
	card.set_meta("slot_label", slot_label_text)
	card.set_meta("domain", _domain_for(boon))
	card.set_meta("benefactor", _benefactor_for(boon))
	card.set_meta("benefactor_display_name", benefactor_display_name)
	card.set_meta("rarity_value", rarity)
	card.set_meta("thorned", thorned)
	_apply_card_style(card, _rarity_tint(rarity), thorned, rarity)
	_apply_auxiliary_frames(card, _rarity_tint(rarity), thorned, rarity)

	var rarity_label := _label_for(card, "RarityLabel")
	var benefactor_label := _label_for(card, "BenefactorLabel")
	var name_label := _label_for(card, "NameLabel")
	var domain_label := _label_for(card, "DomainLabel")
	var slot_label := _label_for(card, "SlotLabel")
	var description_label := _label_for(card, "DescriptionLabel")

	_apply_label_style(rarity_label, benefactor_label, name_label, domain_label, slot_label, description_label, rarity, thorned)
	rarity_label.text = rarity_label_text
	benefactor_label.text = benefactor_display_name
	name_label.text = _display_name_for(boon)
	domain_label.text = _domain_for(boon)
	slot_label.text = "%s Slot" % slot_label_text
	description_label.text = _description_for(boon)

	# Shane's "number go up": the mechanical gains (and any trade-off costs)
	# sit on the card in plain numbers, above the flavor prose.
	var effects_label := _label_for(card, "EffectsLabel")
	var cost_label := _label_for(card, "CostLabel")
	_apply_effect_label_style(effects_label, cost_label)
	effects_label.text = "\n".join(_effect_lines_for(boon))
	effects_label.visible = not effects_label.text.is_empty()
	cost_label.text = "\n".join(_cost_lines_for(boon))
	cost_label.visible = not cost_label.text.is_empty()

func _clear_card(card: Button) -> void:
	card.visible = false
	card.disabled = true
	card.focus_mode = Control.FOCUS_NONE
	card.scale = Vector2.ONE
	card.modulate = Color(1, 1, 1, 1)
	card.remove_theme_stylebox_override("normal")
	card.remove_theme_stylebox_override("hover")
	card.remove_theme_stylebox_override("pressed")
	card.remove_theme_stylebox_override("focus")
	_apply_card_style(card, DISABLED_BORDER, false, BoonDef.Rarity.COMMON)
	_apply_auxiliary_frames(card, DISABLED_BORDER, false, BoonDef.Rarity.COMMON, false)
	for key in ["boon_id", "rarity_label", "slot_label", "domain", "benefactor", "benefactor_display_name", "rarity_value", "thorned", "hovered", "focused", "reveal_active"]:
		if card.has_meta(key):
			card.remove_meta(key)
	for label_name in ["RarityLabel", "BenefactorLabel", "NameLabel", "DomainLabel", "SlotLabel", "DescriptionLabel", "EffectsLabel", "CostLabel"]:
		var label := _label_for(card, label_name)
		label.text = ""
		if label_name == "EffectsLabel" or label_name == "CostLabel":
			label.visible = false

func _label_for(card: Button, label_name: String) -> Label:
	if label_name == "BenefactorLabel":
		_ensure_benefactor_label(card)
	elif label_name == "EffectsLabel" or label_name == "CostLabel":
		_ensure_effect_labels(card)
	return card.get_node("Margin/VBox/%s" % label_name) as Label

func _prepare_card_layout(card: Button) -> void:
	card.custom_minimum_size = CARD_MINIMUM_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.clip_contents = false
	_set_card_pivot(card)
	var margin := card.get_node_or_null("Margin") as MarginContainer
	if margin != null:
		margin.add_theme_constant_override("margin_left", 28)
		margin.add_theme_constant_override("margin_top", 24)
		margin.add_theme_constant_override("margin_right", 28)
		margin.add_theme_constant_override("margin_bottom", 24)
	var vbox := card.get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", 12)

func _ensure_benefactor_label(card: Button) -> void:
	var vbox := card.get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox == null or vbox.has_node("BenefactorLabel"):
		return

	var label := Label.new()
	label.name = "BenefactorLabel"
	label.theme_type_variation = &"CapsLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", INK_MUTED)
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
	cost_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(cost_label)

	var description_label := vbox.get_node_or_null("DescriptionLabel") as Label
	if description_label != null:
		vbox.move_child(effects_label, description_label.get_index())
		vbox.move_child(cost_label, description_label.get_index())

func _ensure_title_flourish(card: Button) -> void:
	var vbox := card.get_node_or_null("Margin/VBox") as VBoxContainer
	if vbox == null or vbox.has_node("TitleFlourish"):
		return
	var flourish := ColorRect.new()
	flourish.name = "TitleFlourish"
	flourish.custom_minimum_size = Vector2(0.0, 3.0)
	flourish.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flourish.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flourish.color = BRASS_FRAME
	vbox.add_child(flourish)
	var name_label := vbox.get_node_or_null("NameLabel") as Label
	if name_label != null:
		vbox.move_child(flourish, name_label.get_index() + 1)

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
	style.border_color = GOLD_FRAME
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

func _ensure_outer_frame(card: Button) -> void:
	if card.has_node("OuterFrame"):
		return
	var frame := Panel.new()
	frame.name = "OuterFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 3.0
	frame.offset_top = 3.0
	frame.offset_right = -3.0
	frame.offset_bottom = -3.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.focus_mode = Control.FOCUS_NONE
	frame.visible = false
	frame.add_theme_stylebox_override("panel", _make_frame_style(GOLD_FRAME, 2, 7))
	card.add_child(frame)

func _ensure_flash_frame(card: Button) -> void:
	if card.has_node("FlashFrame"):
		return
	var frame := Panel.new()
	frame.name = "FlashFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 1.0
	frame.offset_top = 1.0
	frame.offset_right = -1.0
	frame.offset_bottom = -1.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.focus_mode = Control.FOCUS_NONE
	frame.visible = false
	frame.modulate = Color(1, 1, 1, 0)
	frame.add_theme_stylebox_override("panel", _make_frame_style(GOLD_FRAME, 4, 8))
	card.add_child(frame)

func _apply_auxiliary_frames(
	card: Button,
	border_color: Color,
	thorned: bool,
	rarity: int,
	show_flourish: bool = true
) -> void:
	var flourish := card.get_node_or_null("Margin/VBox/TitleFlourish") as ColorRect
	if flourish != null:
		flourish.visible = show_flourish
		flourish.color = _flash_color_for(rarity, thorned)

	var gilt_frame := card.get_node_or_null("GiltFrame") as Panel
	if gilt_frame != null:
		var gilt_color := THORN_ACCENT if thorned else GOLD_FRAME
		gilt_frame.visible = show_flourish
		gilt_frame.add_theme_stylebox_override("panel", _make_frame_style(gilt_color, 1, 5))

	var outer_frame := card.get_node_or_null("OuterFrame") as Panel
	if outer_frame != null:
		outer_frame.visible = show_flourish and (thorned or rarity >= BoonDef.Rarity.LEGENDARY)
		var outer_color := THORN_ACCENT if thorned else GOLD_FRAME
		outer_frame.add_theme_stylebox_override("panel", _make_frame_style(outer_color, 2, 7))

	var flash_frame := card.get_node_or_null("FlashFrame") as Panel
	if flash_frame != null:
		flash_frame.visible = false
		flash_frame.modulate = Color(1, 1, 1, 0)
		flash_frame.add_theme_stylebox_override("panel", _make_frame_style(_flash_color_for(rarity, thorned), 4, 8))

func _apply_label_style(
	rarity_label: Label,
	benefactor_label: Label,
	name_label: Label,
	domain_label: Label,
	slot_label: Label,
	description_label: Label,
	rarity: int,
	thorned: bool
) -> void:
	var accent := _flash_color_for(rarity, thorned)
	rarity_label.add_theme_color_override("font_color", accent)
	rarity_label.add_theme_font_size_override("font_size", 14)
	benefactor_label.add_theme_color_override("font_color", INK_MUTED)
	benefactor_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", INK_TEXT)
	name_label.add_theme_font_size_override("font_size", 30)
	domain_label.add_theme_color_override("font_color", INK_MUTED)
	domain_label.add_theme_font_size_override("font_size", 15)
	slot_label.add_theme_color_override("font_color", BRASS_FRAME if not thorned else THORN_ACCENT)
	slot_label.add_theme_font_size_override("font_size", 20)
	description_label.add_theme_color_override("font_color", INK_TEXT)
	description_label.add_theme_font_size_override("font_size", 18)

func _apply_effect_label_style(effects_label: Label, cost_label: Label) -> void:
	effects_label.add_theme_color_override("font_color", EFFECTS_LABEL_COLOR)
	effects_label.add_theme_font_size_override("font_size", 17)
	cost_label.add_theme_color_override("font_color", COST_LABEL_COLOR)
	cost_label.add_theme_font_size_override("font_size", 17)

func _display_name_for(boon: Variant) -> String:
	var display_name := String(_offer_get(boon, "display_name", ""))
	if not display_name.is_empty():
		return display_name
	return String(_boon_id_for(boon)).capitalize()

func _boon_id_for(boon: Variant) -> StringName:
	var value: Variant = _offer_get(boon, "boon_id", &"")
	return StringName(value)

func _domain_for(boon: Variant) -> String:
	var domain := String(_offer_get(boon, "domain", ""))
	return domain if not domain.is_empty() else "Unknown Domain"

func _description_for(boon: Variant) -> String:
	return String(_offer_get(boon, "description", ""))

func _benefactor_for(boon: Variant) -> StringName:
	return StringName(_offer_get(boon, "benefactor", &""))

func _benefactor_display_name_for(boon: Variant) -> String:
	if boon is Object:
		var object := boon as Object
		if object.has_method(&"benefactor_warning"):
			var warning := String(object.call(&"benefactor_warning"))
			if not warning.is_empty():
				push_warning("BoonDraftUI rendering invalid benefactor: %s" % warning)
	var display_name := String(_offer_get(boon, "benefactor_display_name", ""))
	if not display_name.is_empty():
		return display_name
	if boon is Object:
		var object := boon as Object
		if object.has_method(&"benefactor_placeholder_display_name"):
			var placeholder := String(object.call(&"benefactor_placeholder_display_name"))
			if not placeholder.is_empty():
				return placeholder
	var benefactor := String(_benefactor_for(boon))
	return benefactor.capitalize() if not benefactor.is_empty() else "Unknown Benefactor"

func _rarity_for(boon: Variant) -> int:
	var value: Variant = _offer_get(boon, "rarity", BoonDef.Rarity.COMMON)
	match typeof(value):
		TYPE_INT:
			return mini(maxi(int(value), BoonDef.Rarity.COMMON), BoonDef.Rarity.LEGENDARY)
		TYPE_FLOAT:
			return mini(maxi(int(value), BoonDef.Rarity.COMMON), BoonDef.Rarity.LEGENDARY)
		TYPE_STRING, TYPE_STRING_NAME:
			match String(value).to_lower():
				"rare":
					return BoonDef.Rarity.RARE
				"epic":
					return BoonDef.Rarity.EPIC
				"legendary":
					return BoonDef.Rarity.LEGENDARY
				_:
					return BoonDef.Rarity.COMMON
		_:
			return BoonDef.Rarity.COMMON

func _rarity_label_for(boon: Variant) -> String:
	if boon is Object:
		var object := boon as Object
		if object.has_method(&"rarity_label"):
			return String(object.call(&"rarity_label"))
	var label := String(_offer_get(boon, "rarity_label", ""))
	if not label.is_empty():
		return label
	match _rarity_for(boon):
		BoonDef.Rarity.RARE:
			return "Rare"
		BoonDef.Rarity.EPIC:
			return "Epic"
		BoonDef.Rarity.LEGENDARY:
			return "Legendary"
		_:
			return "Common"

func _slot_label_for(boon: Variant) -> String:
	if boon is Object:
		var object := boon as Object
		if object.has_method(&"slot_label"):
			return String(object.call(&"slot_label"))
	var label := String(_offer_get(boon, "slot_label", ""))
	return label if not label.is_empty() else "Passive"

func _effect_lines_for(boon: Variant) -> Array[String]:
	if boon is Object:
		var object := boon as Object
		if object.has_method(&"effect_lines"):
			return _as_string_array(object.call(&"effect_lines"))
	return _as_string_array(_offer_get(boon, "effect_lines", []))

func _cost_lines_for(boon: Variant) -> Array[String]:
	if boon is Object:
		var object := boon as Object
		if object.has_method(&"cost_lines"):
			return _as_string_array(object.call(&"cost_lines"))
	return _as_string_array(_offer_get(boon, "cost_lines", []))

func _is_thorned_offer(boon: Variant) -> bool:
	if boon == null:
		return false
	if _truthy_marker(_offer_get(boon, "tradeoff", false)):
		return true
	if _truthy_marker(_offer_get(boon, "curse", false)):
		return true
	if _truthy_marker(_offer_get(boon, "cost", false)):
		return true
	if boon is Object:
		var object := boon as Object
		if object.has_method(&"has_cost") and bool(object.call(&"has_cost")):
			return true
	return not _cost_lines_for(boon).is_empty()

func _offer_get(offer: Variant, key: String, default_value: Variant) -> Variant:
	if offer == null:
		return default_value
	if offer is Dictionary:
		var data := offer as Dictionary
		return data.get(key, default_value)
	if offer is Object:
		var object := offer as Object
		if _object_has_property(object, key):
			return object.get(key)
	return default_value

func _object_has_property(object: Object, key: String) -> bool:
	for property in object.get_property_list():
		if String(property.get("name", "")) == key:
			return true
	return false

func _truthy_marker(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return bool(value)
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return not is_zero_approx(float(value))
		TYPE_STRING, TYPE_STRING_NAME:
			var text := String(value).strip_edges().to_lower()
			return not text.is_empty() and text != "false" and text != "0" and text != "none"
		TYPE_ARRAY:
			return not (value as Array).is_empty()
		TYPE_DICTIONARY:
			return not (value as Dictionary).is_empty()
		_:
			return true

func _as_string_array(value: Variant) -> Array[String]:
	var lines: Array[String] = []
	if value is Array:
		for item in value:
			lines.append(String(item))
	elif typeof(value) == TYPE_STRING or typeof(value) == TYPE_STRING_NAME:
		var text := String(value)
		if not text.is_empty():
			lines.append(text)
	return lines

func _rarity_tint(rarity: int) -> Color:
	match rarity:
		BoonDef.Rarity.RARE:
			return RARE_FRAME
		BoonDef.Rarity.EPIC:
			return EPIC_FRAME
		BoonDef.Rarity.LEGENDARY:
			return GOLD_FRAME
		_:
			return BRASS_FRAME

func _flash_color_for(rarity: int, thorned: bool) -> Color:
	if thorned:
		return THORN_ACCENT
	match rarity:
		BoonDef.Rarity.RARE:
			return RARE_FRAME
		BoonDef.Rarity.EPIC:
			return EPIC_FRAME.lightened(0.16)
		BoonDef.Rarity.LEGENDARY:
			return GOLD_FRAME.lightened(0.16)
		_:
			return BRASS_FRAME

func _apply_card_style(card: Button, border_color: Color, thorned: bool, rarity: int) -> void:
	var normal_border := THORN_BORDER if thorned else border_color
	var hover_border := _flash_color_for(rarity, thorned).lightened(0.14)
	var pressed_border := normal_border.darkened(0.16)
	var shadow_color := _glow_color_for(rarity, thorned)
	var shadow_size := _glow_size_for(rarity, thorned)
	var normal_width := 4 if thorned else 3
	if rarity >= BoonDef.Rarity.LEGENDARY:
		normal_width = 4
	card.add_theme_stylebox_override("normal", _make_card_style(CARD_BACKGROUND, normal_border, normal_width, shadow_color, shadow_size))
	card.add_theme_stylebox_override("hover", _make_card_style(CARD_BACKGROUND_HOVER, hover_border, normal_width + 1, shadow_color.lightened(0.08), shadow_size + 2))
	card.add_theme_stylebox_override("pressed", _make_card_style(CARD_BACKGROUND_PRESSED, pressed_border, normal_width + 1, shadow_color.darkened(0.12), shadow_size))
	card.add_theme_stylebox_override("focus", _make_card_style(Color(0, 0, 0, 0), FOCUS_BORDER if not thorned else THORN_ACCENT.lightened(0.28), 5, FOCUS_BORDER.darkened(0.15), 12))

func _glow_color_for(rarity: int, thorned: bool) -> Color:
	if thorned:
		return Color(0.4941, 0.1059, 0.0863, 0.24)
	match rarity:
		BoonDef.Rarity.EPIC:
			return Color(0.5412, 0.3569, 0.6902, 0.36)
		BoonDef.Rarity.LEGENDARY:
			return Color(0.8784, 0.7569, 0.4784, 0.42)
		BoonDef.Rarity.RARE:
			return Color(0.3216, 0.7098, 0.6863, 0.20)
		_:
			return Color(0, 0, 0, 0.30)

func _glow_size_for(rarity: int, thorned: bool) -> int:
	if thorned:
		return 11
	match rarity:
		BoonDef.Rarity.EPIC:
			return 15
		BoonDef.Rarity.LEGENDARY:
			return 18
		BoonDef.Rarity.RARE:
			return 10
		_:
			return 8

func _make_card_style(background: Color, border: Color, border_width: int, shadow: Color, shadow_size: int) -> StyleBoxFlat:
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
	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	return style

func _make_frame_style(border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style

func _on_card_mouse_entered(card: Button) -> void:
	card.set_meta("hovered", true)
	_update_card_lift(card)

func _on_card_mouse_exited(card: Button) -> void:
	card.set_meta("hovered", false)
	_update_card_lift(card)

func _on_card_focus_entered(card: Button) -> void:
	card.set_meta("focused", true)
	_update_card_lift(card)

func _on_card_focus_exited(card: Button) -> void:
	card.set_meta("focused", false)
	_update_card_lift(card)

func _update_card_lift(card: Button) -> void:
	if not is_instance_valid(card) or card.disabled or bool(card.get_meta("reveal_active", false)):
		return
	var lifted := bool(card.get_meta("hovered", false)) or bool(card.get_meta("focused", false))
	_tween_card_scale(card, LIFT_SCALE if lifted else Vector2.ONE, 0.12, Tween.TRANS_CUBIC)

func _play_reveal_scale(card: Button) -> void:
	_set_card_pivot(card)
	card.set_meta("reveal_active", true)
	card.scale = REVEAL_START_SCALE
	_kill_tween(_reveal_tweens.get(card, null))
	var tween := card.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_reveal_tweens[card] = tween
	tween.tween_property(card, "scale", Vector2.ONE, REVEAL_SCALE_TIME)
	tween.tween_callback(_finish_reveal_scale.bind(card))

func _finish_reveal_scale(card: Button) -> void:
	if not is_instance_valid(card):
		return
	card.set_meta("reveal_active", false)
	_update_card_lift(card)

func _flash_card_border(card: Button, color: Color) -> void:
	var frame := card.get_node_or_null("FlashFrame") as Panel
	if frame == null:
		return
	frame.visible = true
	frame.modulate = Color(1, 1, 1, 0.95)
	frame.add_theme_stylebox_override("panel", _make_frame_style(color.lightened(0.18), 4, 8))
	var tween := frame.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(frame, "modulate", Color(1, 1, 1, 0), 0.32)
	tween.tween_callback(func() -> void:
		if is_instance_valid(frame):
			frame.visible = false
	)

func _tween_card_scale(card: Button, target: Vector2, duration: float, transition: Tween.TransitionType) -> void:
	_set_card_pivot(card)
	_kill_tween(_lift_tweens.get(card, null))
	var tween := card.create_tween().set_trans(transition).set_ease(Tween.EASE_OUT)
	_lift_tweens[card] = tween
	tween.tween_property(card, "scale", target, duration)

func _set_card_pivot(card: Control) -> void:
	var pivot := card.size * 0.5
	if pivot == Vector2.ZERO:
		pivot = card.custom_minimum_size * 0.5
	card.pivot_offset = pivot

func _kill_tween(value: Variant) -> void:
	var tween := value as Tween
	if tween != null and tween.is_valid():
		tween.kill()

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)
