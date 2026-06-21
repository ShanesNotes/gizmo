class_name Hud
extends CanvasLayer

## In-game HUD for the Gizmo 3D rogue-lite.
##
## Driven entirely by the game controller through render(sim) — the HUD never
## reaches into the Simulation on its own and never runs per-frame logic of its
## own beyond the level-up flash and the XP-fill tweens. The .tscn ships with
## sensible default widget values so running this scene standalone shows a
## populated HUD.

## Seconds the "LEVEL UP" flash takes to fade from opaque to transparent.
const FLASH_FADE_SECONDS: float = 1.2

## Seconds the XP bar takes to ease toward a new fill level (the "satisfying fill").
const XP_FILL_SECONDS: float = 0.35

@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _sparks_label: Label = %SparksLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _level_up_flash: Label = %LevelUpFlash

var _flash_tween: Tween
var _xp_tween: Tween
var _xp_shown: float = -1.0   # last XP fill (0..100) the bar was driven to; <0 = not shown yet


## Push one frame of Simulation state into every widget. Typed because this is
## the public controller→HUD contract; the Simulation is the source of truth and
## the HUD only reads it (ADR 0002).
func render(sim: Simulation) -> void:
	_hp_bar.value = sim.hp_progress() * 100.0
	_hp_label.text = "%d / %d" % [sim.hp, sim.max_hp]

	_level_label.text = str(sim.level)

	_update_xp_fill(sim.xp_progress() * 100.0)
	_sparks_label.text = str(sim.xp)

	_timer_label.text = format_clock(sim.time_remaining())

	for event in sim.last_events:
		if event.get("type") == "levelup":
			_play_level_up_flash()
			break


## Whole-minute:zero-padded-seconds for a COUNT-DOWN clock: round up so any time
## left still reads on the dial (0.1s shows "0:01"), and only the true end shows
## "0:00". Pure — unit-tested headless.
static func format_clock(seconds: float) -> String:
	var total: int = 0 if seconds <= 0.0 else int(ceilf(seconds))
	var minutes: int = total / 60
	var secs: int = total % 60
	return "%d:%02d" % [minutes, secs]


## Ease the XP bar toward a new fill (0..100) so gaining Sparks visibly *fills* it
## instead of snapping. The first frame snaps (no startup animation); after that, a
## changed target retargets a short eased tween. No-op when the fill is unchanged,
## so this is safe to call every frame.
func _update_xp_fill(target: float) -> void:
	if _xp_shown < 0.0:
		_xp_bar.value = target
		_xp_shown = target
		return
	if is_equal_approx(target, _xp_shown):
		return
	_xp_shown = target
	if is_instance_valid(_xp_tween):
		_xp_tween.kill()
	_xp_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_xp_tween.tween_property(_xp_bar, "value", target, XP_FILL_SECONDS)


## Show the centered "LEVEL UP" label at full opacity, then fade it out.
## Restarting mid-fade is safe: any prior tween is killed first.
## set_trans/set_ease are set BEFORE tween_property so they apply to the fade.
func _play_level_up_flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()

	_level_up_flash.visible = true
	_level_up_flash.modulate.a = 1.0

	_flash_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_flash_tween.tween_property(_level_up_flash, "modulate:a", 0.0, FLASH_FADE_SECONDS)
	_flash_tween.tween_callback(func() -> void: _level_up_flash.visible = false)
