class_name Hud
extends CanvasLayer

## In-game HUD for the Gizmo 3D rogue-lite.
##
## Driven entirely by the game controller through render(sim) — the HUD never
## reaches into the Simulation on its own. The .tscn ships with sensible default
## widget values so running this scene standalone shows a populated HUD.

const ABILITY_SLOT_DIM_ALPHA := 0.4
const SPARK_READY_EPSILON := 0.001
## Halo-CE vitals presentation: guard renders as one flat recharging shield
## bar; hp renders as discrete hull blocks (divider ticks over the warm bar).
const HP_BLOCKS := 3
const SPARK_PIP_COUNT := 3
const SHIELD_HIT_FLASH := Color(0.95, 0.25, 0.2, 1.0)
const BRASS_PANEL_BG := Color(0.102, 0.0824, 0.0706, 0.93)
const BRASS_BORDER := Color(0.6902, 0.5529, 0.3412, 1.0)
const BRASS_HIGHLIGHT := Color(0.8784, 0.7569, 0.4784, 1.0)
const BRASS_SHADOW := Color(0.0, 0.0, 0.0, 0.5)
const HP_CELL_FLASH := Color(1.0, 0.78, 0.42, 0.92)
const HP_CELL_DULL := Color(0.45, 0.20, 0.15, 0.0)
const SPARK_PIP_LIT := Color(0.5412, 0.3569, 0.6902, 1.0)
const SPARK_PIP_DARK := Color(0.102, 0.0824, 0.0706, 0.88)
const PARCHMENT_PANEL := Color(0.9804, 0.898, 0.8, 0.96)
const PARCHMENT_INK := Color(0.2078, 0.1725, 0.1686, 1.0)

class BoonSlotRow:
	extends HBoxContainer

	var frame_style: StyleBoxFlat

	func _draw() -> void:
		if frame_style != null:
			draw_style_box(frame_style, Rect2(Vector2.ZERO, size))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

@onready var _root: Control = $Root
@onready var _shield_bar: ProgressBar = %ShieldBar
@onready var _shield_glow: ProgressBar = %ShieldTopGlow
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _sparks_label: Label = %SparksLabel
@onready var _spark_gauge: PanelContainer = %SparkGauge
@onready var _spark_fill: ProgressBar = %SparkFill
@onready var _spark_pips: HBoxContainer = %SparkPips
@onready var _spark_status: Label = %Status
@onready var _boon_loadout: VBoxContainer = %BoonLoadout
@onready var _ability_bar: HBoxContainer = %AbilityBar
@onready var _ability_frame: PanelContainer = $Root/AbilityFrame

var _spark_pip_lit_style: StyleBoxFlat
var _spark_pip_unlit_style: StyleBoxFlat
var _hp_cell_flashes: Array[ColorRect] = []
var _last_hp_value := -1.0

func _ready() -> void:
	_last_hp_value = float(_hp_bar.value)
	_spark_pip_lit_style = _make_spark_pip_style(true)
	_spark_pip_unlit_style = _make_spark_pip_style(false)
	_build_hp_block_dividers()
	_update_spark_pips(0.0, 1.0)
	_hp_bar.value_changed.connect(_on_hp_value_changed)


## Push one frame of Simulation state into every widget. Typed because this is
## the public controller→HUD contract; the Simulation is the source of truth and
## the HUD only reads it (ADR 0002).
func render(sim: Simulation) -> void:
	_hp_bar.value = sim.hp_progress() * 100.0
	_hp_label.text = "%d / %d" % [sim.hp, sim.max_hp]
	_sparks_label.text = str(sim.xp)


## Payload-driven shield bar (ADR 0007 guard, Halo-CE presentation). Controller
## passes guard values when the player entity exists; the Simulation has no
## guard fields in this rescope. Same seam name, bar semantics.
var _last_shield := -1

func render_guard(guard: int, guard_max: int) -> void:
	if guard_max <= 0:
		_shield_bar.visible = false
		_shield_glow.visible = false
		_last_shield = -1
		return

	var filled := clampi(guard, 0, guard_max)
	_shield_bar.visible = true
	_shield_bar.max_value = float(guard_max)
	_shield_bar.value = float(filled)
	_shield_glow.visible = true
	_shield_glow.max_value = float(guard_max)
	_shield_glow.value = float(filled)
	# Shield-hit read (HZ-084 carried forward): red flash on any drop.
	if _last_shield >= 0 and filled < _last_shield:
		_shield_bar.modulate = SHIELD_HIT_FLASH
		var tween := _shield_bar.create_tween()
		tween.tween_property(_shield_bar, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	_last_shield = filled

func render_spark(charge: float, charge_max: float) -> void:
	var safe_max := maxf(charge_max, 0.0)
	if safe_max <= 0.0:
		_spark_gauge.visible = false
		_update_spark_pips(0.0, 1.0)
		return

	var safe_charge := clampf(charge, 0.0, safe_max)
	_spark_gauge.visible = true
	_spark_fill.max_value = safe_max
	_spark_fill.value = safe_charge
	_update_spark_pips(safe_charge, safe_max)
	if safe_charge + SPARK_READY_EPSILON >= safe_max:
		_spark_status.text = "READY"
	else:
		_spark_status.text = "%d%%" % int(roundf((safe_charge / safe_max) * 100.0))


## Payload-driven region toast: the orchestrator passes the entered room's
## display name (drawn from the Shattered Meridian region graph) and the HUD
## shows it briefly. The label is built lazily so the .tscn stays untouched.
const REGION_TOAST_HOLD_SECONDS := 2.2
const REGION_TOAST_FADE_SECONDS := 0.6

var _region_toast: Label = null
var _region_toast_tween: Tween = null

func render_region_toast(text: String) -> void:
	if text.strip_edges() == "":
		return
	if _region_toast == null or not is_instance_valid(_region_toast):
		_build_region_toast()
	if _region_toast_tween != null and _region_toast_tween.is_valid():
		_region_toast_tween.kill()
	_region_toast.text = text
	_region_toast.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_region_toast.visible = true
	_region_toast_tween = _region_toast.create_tween()
	_region_toast_tween.tween_interval(REGION_TOAST_HOLD_SECONDS)
	_region_toast_tween.tween_property(_region_toast, "modulate:a", 0.0, REGION_TOAST_FADE_SECONDS)


## Payload-driven boon loadout rows (HZ-052). Controller passes picked boons when the
## run has kit slots filled; clears and repopulates on each call.
func render_boons(picked: Array[BoonDef]) -> void:
	for child in _boon_loadout.get_children():
		child.free()

	if picked.is_empty():
		_boon_loadout.visible = false
		return

	_boon_loadout.visible = true
	for boon in picked:
		if boon == null:
			continue
		_boon_loadout.add_child(_make_boon_row(boon))


## Payload-driven ability bar slots (HZ-051). Controller passes per-slot runtime
## state when the player kit is active; clears and repopulates on each call.
func render_abilities(states: Array) -> void:
	for child in _ability_bar.get_children():
		child.free()

	if states.is_empty():
		_ability_bar.visible = false
		_ability_frame.visible = false
		return

	_ability_bar.visible = true
	_ability_frame.visible = true

	for state in states:
		if typeof(state) != TYPE_DICTIONARY:
			continue
		_ability_bar.add_child(_make_ability_slot(state))
	_ability_bar.visible = _ability_bar.get_child_count() > 0
	_ability_frame.visible = _ability_bar.visible


func _make_ability_slot(state: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 60)
	panel.add_theme_stylebox_override("panel", _make_brass_stylebox(BRASS_PANEL_BG, BRASS_HIGHLIGHT, 2, 8, true))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	margin.add_child(col)

	var kind: int = int(state.get("kind", Ability.AbilityKind.ATTACK))
	var ready: bool = bool(state.get("ready", true))
	var count: int = int(state.get("count", -1))

	var slot_label := Label.new()
	slot_label.theme_type_variation = &"CapsLabel"
	slot_label.text = _ability_kind_label(kind)
	slot_label.add_theme_font_size_override("font_size", 18)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(slot_label)

	var status_label := Label.new()
	status_label.theme_type_variation = &"NumericLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	if count >= 0:
		status_label.text = str(count)
		status_label.visible = true
	else:
		status_label.text = ""
		status_label.visible = false
	col.add_child(status_label)

	panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if ready else ABILITY_SLOT_DIM_ALPHA)
	return panel


## The hull bar reads as discrete blocks: thin divider ticks split the warm
## bar into HP_BLOCKS segments. The orchestrator keeps driving HpBar's ratio;
## the ticks are pure presentation.
func _build_hp_block_dividers() -> void:
	if _hp_bar == null:
		return
	_hp_cell_flashes.clear()
	for i in range(HP_BLOCKS):
		var flash := ColorRect.new()
		flash.name = "HpCellFlash%d" % (i + 1)
		flash.color = HP_CELL_DULL
		flash.visible = false
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hp_bar.add_child(flash)
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		flash.anchor_left = float(i) / float(HP_BLOCKS)
		flash.anchor_right = float(i + 1) / float(HP_BLOCKS)
		flash.offset_left = 2.0
		flash.offset_top = 2.0
		flash.offset_right = -2.0
		flash.offset_bottom = -2.0
		_hp_cell_flashes.append(flash)

	for i in range(1, HP_BLOCKS):
		var divider := ColorRect.new()
		divider.name = "BlockDivider%d" % i
		divider.color = Color(0.8784, 0.7569, 0.4784, 0.95)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hp_bar.add_child(divider)
		divider.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		divider.anchor_left = float(i) / float(HP_BLOCKS)
		divider.anchor_right = divider.anchor_left
		divider.offset_left = -1.5
		divider.offset_right = 1.5


func _ability_kind_label(kind: int) -> String:
	match kind:
		Ability.AbilityKind.DASH:
			return "DASH"
		Ability.AbilityKind.ATTACK:
			return "ATTACK"
		Ability.AbilityKind.SPECIAL:
			return "SPECIAL"
		Ability.AbilityKind.CAST:
			return "CAST"
		Ability.AbilityKind.SURGE:
			return "SURGE"
		_:
			return "ATTACK"


func _make_boon_row(boon: BoonDef) -> HBoxContainer:
	var tint := _rarity_tint(boon.rarity)
	var row := BoonSlotRow.new()
	row.custom_minimum_size = Vector2(260, 38)
	row.frame_style = _make_brass_stylebox(BRASS_PANEL_BG, tint, 2, 7, true)
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var slot_label := Label.new()
	slot_label.theme_type_variation = &"CapsLabel"
	slot_label.text = boon.slot_label()
	slot_label.custom_minimum_size = Vector2(86, 30)
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.add_theme_color_override("font_color", BRASS_HIGHLIGHT)
	slot_label.add_theme_font_size_override("font_size", 18)

	var name_label := Label.new()
	name_label.text = _display_name_for_boon(boon)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", tint)
	name_label.add_theme_font_size_override("font_size", 18)

	row.add_child(slot_label)
	row.add_child(name_label)
	row.queue_redraw()
	return row


func _display_name_for_boon(boon: BoonDef) -> String:
	if not boon.display_name.is_empty():
		return boon.display_name
	return String(boon.boon_id).capitalize()


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


## Whole-minute:zero-padded-seconds clock, kept as a pure formatter for the end
## screen's "survived" run-length stat. Rounds up so a partial second still reads;
## only true zero shows "0:00".
static func format_clock(seconds: float) -> String:
	var total: int = 0 if seconds <= 0.0 else int(ceilf(seconds))
	var minutes: int = total / 60
	var secs: int = total % 60
	return "%d:%02d" % [minutes, secs]


func _on_hp_value_changed(value: float) -> void:
	if _last_hp_value < 0.0:
		_last_hp_value = value
		return
	if value < _last_hp_value - 0.01:
		var loss_index := clampi(int(floor((maxf(_last_hp_value, 0.0) - 0.001) / 100.0 * HP_BLOCKS)), 0, HP_BLOCKS - 1)
		_flash_hp_cell(loss_index)
	_last_hp_value = value


func _flash_hp_cell(index: int) -> void:
	if index < 0 or index >= _hp_cell_flashes.size():
		return
	var flash := _hp_cell_flashes[index]
	flash.visible = true
	flash.color = HP_CELL_FLASH
	var tween := flash.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "color", Color(0.72, 0.31, 0.22, 0.5), 0.12)
	tween.tween_property(flash, "color", HP_CELL_DULL, 0.22)
	tween.tween_callback(Callable(flash, "hide"))


func _update_spark_pips(charge: float, charge_max: float) -> void:
	var lit_count := _spark_lit_count(charge, charge_max)
	for i in range(_spark_pips.get_child_count()):
		var pip := _spark_pips.get_child(i) as PanelContainer
		if pip == null:
			continue
		var lit := i < lit_count
		pip.add_theme_stylebox_override("panel", _spark_pip_lit_style if lit else _spark_pip_unlit_style)
		pip.modulate = Color(1.0, 1.0, 1.0, 1.0 if lit else 0.55)


func _spark_lit_count(charge: float, charge_max: float) -> int:
	if charge_max <= 0.0:
		return 0
	var ratio := clampf(charge / charge_max, 0.0, 1.0)
	if ratio + SPARK_READY_EPSILON >= 1.0:
		return SPARK_PIP_COUNT
	return clampi(int(floor(ratio * SPARK_PIP_COUNT)), 0, SPARK_PIP_COUNT)


func _build_region_toast() -> void:
	# A single Label styled as a parchment caption-bar: the orchestrator
	# contract wants a Label named "RegionToast" as a direct HUD child,
	# so the parchment panel lives in the label's own stylebox.
	_region_toast = Label.new()
	_region_toast.name = "RegionToast"
	_region_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_region_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_region_toast.add_theme_stylebox_override("normal", _make_region_toast_stylebox())
	_region_toast.add_theme_font_size_override("font_size", 30)
	_region_toast.add_theme_color_override("font_color", PARCHMENT_INK)
	_region_toast.add_theme_color_override("font_outline_color", Color(0.8784, 0.7569, 0.4784, 0.5))
	_region_toast.add_theme_constant_override("outline_size", 1)
	add_child(_region_toast)
	_region_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_region_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_region_toast.offset_left = -280.0
	_region_toast.offset_top = 38.0
	_region_toast.offset_right = 280.0
	_region_toast.offset_bottom = 92.0


func _make_region_toast_stylebox() -> StyleBoxFlat:
	var style := _make_parchment_stylebox()
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _make_spark_pip_style(lit: bool) -> StyleBoxFlat:
	var bg := SPARK_PIP_LIT if lit else SPARK_PIP_DARK
	var border := BRASS_HIGHLIGHT if lit else BRASS_BORDER
	return _make_brass_stylebox(bg, border, 2, 4, false)


func _make_parchment_stylebox() -> StyleBoxFlat:
	var style := _make_brass_stylebox(PARCHMENT_PANEL, BRASS_HIGHLIGHT, 3, 8, true)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 8
	return style


func _make_brass_stylebox(bg: Color, border: Color, width: int, radius: int, shadow: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = width
	style.border_width_top = width + 1
	style.border_width_right = width
	style.border_width_bottom = width
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	if shadow:
		style.shadow_color = BRASS_SHADOW
		style.shadow_size = 6
	return style
