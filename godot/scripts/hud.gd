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
const SHIELD_HIT_FLASH := Color(0.95, 0.25, 0.2, 1.0)

@onready var _shield_bar: ProgressBar = %ShieldBar
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel

func _ready() -> void:
	_build_hp_block_dividers()
@onready var _sparks_label: Label = %SparksLabel
@onready var _spark_gauge: PanelContainer = %SparkGauge
@onready var _spark_fill: ProgressBar = %SparkFill
@onready var _spark_status: Label = %Status
@onready var _boon_loadout: VBoxContainer = %BoonLoadout
@onready var _ability_bar: HBoxContainer = %AbilityBar


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
		_last_shield = -1
		return

	var filled := clampi(guard, 0, guard_max)
	_shield_bar.visible = true
	_shield_bar.max_value = float(guard_max)
	_shield_bar.value = float(filled)
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
		return

	var safe_charge := clampf(charge, 0.0, safe_max)
	_spark_gauge.visible = true
	_spark_fill.max_value = safe_max
	_spark_fill.value = safe_charge
	if safe_charge + SPARK_READY_EPSILON >= safe_max:
		_spark_status.text = "READY"
	else:
		_spark_status.text = "%d%%" % int(roundf((safe_charge / safe_max) * 100.0))


## Payload-driven region toast: the orchestrator passes the entered room's
## display name (drawn from the Shattered Meridian region graph) and the HUD
## shows it briefly. The label is built lazily so the .tscn stays untouched.
const REGION_TOAST_HOLD_SECONDS := 2.2
const REGION_TOAST_FADE_SECONDS := 0.6
const REGION_TOAST_BRASS := Color(0.7882, 0.5647, 0.4196, 1.0)

var _region_toast: Label = null

func render_region_toast(text: String) -> void:
	if text.strip_edges() == "":
		return
	if _region_toast == null or not is_instance_valid(_region_toast):
		_region_toast = Label.new()
		_region_toast.name = "RegionToast"
		_region_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_region_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_region_toast.add_theme_font_size_override("font_size", 26)
		_region_toast.add_theme_color_override("font_color", REGION_TOAST_BRASS)
		add_child(_region_toast)
		_region_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
		_region_toast.offset_top = 46.0
	_region_toast.text = text
	_region_toast.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_region_toast.visible = true
	var tween := _region_toast.create_tween()
	tween.tween_interval(REGION_TOAST_HOLD_SECONDS)
	tween.tween_property(_region_toast, "modulate:a", 0.0, REGION_TOAST_FADE_SECONDS)


## Payload-driven boon loadout rows (HZ-052). Controller passes picked boons when the
## run has kit slots filled; clears and repopulates on each call.
func render_boons(picked: Array[BoonDef]) -> void:
	if picked.is_empty():
		_boon_loadout.visible = false
		return

	_boon_loadout.visible = true
	for child in _boon_loadout.get_children():
		child.free()

	for boon in picked:
		if boon == null:
			continue
		_boon_loadout.add_child(_make_boon_row(boon))


## Payload-driven ability bar slots (HZ-051). Controller passes per-slot runtime
## state when the player kit is active; clears and repopulates on each call.
func render_abilities(states: Array) -> void:
	if states.is_empty():
		_ability_bar.visible = false
		return

	_ability_bar.visible = true
	for child in _ability_bar.get_children():
		child.free()

	for state in states:
		if typeof(state) != TYPE_DICTIONARY:
			continue
		_ability_bar.add_child(_make_ability_slot(state))


func _make_ability_slot(state: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 52)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
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
	slot_label.add_theme_font_size_override("font_size", 11)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(slot_label)

	var status_label := Label.new()
	status_label.theme_type_variation = &"NumericLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
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
	for i in range(1, HP_BLOCKS):
		var divider := ColorRect.new()
		divider.name = "BlockDivider%d" % i
		divider.color = Color(0.08, 0.06, 0.05, 0.9)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hp_bar.add_child(divider)
		divider.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		divider.anchor_left = float(i) / float(HP_BLOCKS)
		divider.anchor_right = divider.anchor_left
		divider.offset_left = -1.0
		divider.offset_right = 1.0


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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var slot_label := Label.new()
	slot_label.theme_type_variation = &"CapsLabel"
	slot_label.text = boon.slot_label()
	slot_label.add_theme_font_size_override("font_size", 11)

	var name_label := Label.new()
	name_label.text = _display_name_for_boon(boon)
	name_label.add_theme_color_override("font_color", _rarity_tint(boon.rarity))

	row.add_child(slot_label)
	row.add_child(name_label)
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
