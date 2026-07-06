class_name Hud
extends CanvasLayer

## In-game HUD for the Gizmo 3D rogue-lite.
##
## Driven entirely by the game controller through render(sim) — the HUD never
## reaches into the Simulation on its own. The .tscn ships with sensible default
## widget values so running this scene standalone shows a populated HUD.

const GUARD_PIP_MAX := 4
const GUARD_PIP_BRASS := Color(0.7882, 0.5647, 0.4196, 1.0)
const GUARD_PIP_EMPTY_ALPHA := 0.25

@onready var _guard_pips: HBoxContainer = %GuardPips
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _sparks_label: Label = %SparksLabel


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

	var filled := clampi(guard, 0, max_pips)
	_guard_pips.visible = true
	var pips := _guard_pips.get_children()
	for i in GUARD_PIP_MAX:
		var pip := pips[i] as ColorRect
		pip.visible = i < max_pips
		if pip.visible:
			var alpha := 1.0 if i < filled else GUARD_PIP_EMPTY_ALPHA
			pip.color = Color(GUARD_PIP_BRASS.r, GUARD_PIP_BRASS.g, GUARD_PIP_BRASS.b, alpha)


## Whole-minute:zero-padded-seconds clock, kept as a pure formatter for the end
## screen's "survived" run-length stat. Rounds up so a partial second still reads;
## only true zero shows "0:00".
static func format_clock(seconds: float) -> String:
	var total: int = 0 if seconds <= 0.0 else int(ceilf(seconds))
	var minutes: int = total / 60
	var secs: int = total % 60
	return "%d:%02d" % [minutes, secs]
