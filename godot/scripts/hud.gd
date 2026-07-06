class_name Hud
extends CanvasLayer

## In-game HUD for the Gizmo 3D rogue-lite.
##
## Driven entirely by the game controller through render(sim) — the HUD never
## reaches into the Simulation on its own. The .tscn ships with sensible default
## widget values so running this scene standalone shows a populated HUD.

const GUARD_PIP_MAX := 12
const GUARD_PIP_SIZE := Vector2(14.0, 14.0)
const GUARD_PIP_BRASS := Color(0.7882, 0.5647, 0.4196, 1.0)
const GUARD_PIP_EMPTY_ALPHA := 0.25
const ABILITY_SLOT_DIM_ALPHA := 0.4
const SPARK_READY_EPSILON := 0.001

@onready var _guard_pips: HBoxContainer = %GuardPips
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
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


## Payload-driven guard pips (ADR 0007). Controller passes guard values when the
## player entity exists; the Simulation has no guard fields in this rescope.
func render_guard(guard: int, guard_max: int) -> void:
	var max_pips := clampi(guard_max, 0, GUARD_PIP_MAX)
	if max_pips <= 0:
		_guard_pips.visible = false
		return

	_ensure_guard_pip_count(max_pips)
	var filled := clampi(guard, 0, max_pips)
	_guard_pips.visible = true
	var pips := _guard_pips.get_children()
	for i in pips.size():
		var pip := pips[i] as ColorRect
		pip.visible = i < max_pips
		if pip.visible:
			var alpha := 1.0 if i < filled else GUARD_PIP_EMPTY_ALPHA
			pip.color = Color(GUARD_PIP_BRASS.r, GUARD_PIP_BRASS.g, GUARD_PIP_BRASS.b, alpha)

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


func _ensure_guard_pip_count(count: int) -> void:
	while _guard_pips.get_child_count() < count:
		var pip := ColorRect.new()
		pip.name = "Pip%d" % _guard_pips.get_child_count()
		pip.custom_minimum_size = GUARD_PIP_SIZE
		pip.color = GUARD_PIP_BRASS
		_guard_pips.add_child(pip)


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
