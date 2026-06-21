class_name Hud
extends CanvasLayer

## In-game HUD for the Gizmo 3D rogue-lite.
##
## Driven entirely by the game controller through render(sim) — the HUD never
## reaches into the Simulation on its own and never runs per-frame logic of its
## own beyond the level-up flash tween. The .tscn ships with sensible default
## widget values so running this scene standalone shows a populated HUD.

## Seconds the "LEVEL UP" flash takes to fade from opaque to transparent.
const FLASH_FADE_SECONDS: float = 1.2

@onready var _hp_bar: ProgressBar = %HpBar
@onready var _hp_label: Label = %HpLabel
@onready var _level_label: Label = %LevelLabel
@onready var _xp_bar: ProgressBar = %XpBar
@onready var _sparks_label: Label = %SparksLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _level_up_flash: Label = %LevelUpFlash

var _flash_tween: Tween


## Push one frame of Simulation state into every widget.
## sim must expose: hp:int, max_hp:int, hp_progress()->float, level:int,
## xp:int, xp_progress()->float, time_remaining()->float,
## last_events:Array[Dictionary].
func render(sim) -> void:
	_hp_bar.value = sim.hp_progress() * 100.0
	_hp_label.text = "%d / %d" % [sim.hp, sim.max_hp]

	_level_label.text = str(sim.level)

	_xp_bar.value = sim.xp_progress() * 100.0
	_sparks_label.text = str(sim.xp)

	_timer_label.text = format_clock(sim.time_remaining())

	for event in sim.last_events:
		if event.get("type") == "levelup":
			_play_level_up_flash()
			break


## Whole-minute:zero-padded-seconds, clamped at zero. Pure — unit-tested headless.
static func format_clock(seconds: float) -> String:
	var total: int = int(maxf(seconds, 0.0))
	var minutes: int = total / 60
	var secs: int = total % 60
	return "%d:%02d" % [minutes, secs]


## Show the centered "LEVEL UP" label at full opacity, then fade it out.
## Restarting mid-fade is safe: any prior tween is killed first.
func _play_level_up_flash() -> void:
	if is_instance_valid(_flash_tween):
		_flash_tween.kill()

	_level_up_flash.visible = true
	_level_up_flash.modulate.a = 1.0

	_flash_tween = create_tween()
	_flash_tween.tween_property(_level_up_flash, "modulate:a", 0.0, FLASH_FADE_SECONDS)
	_flash_tween.set_ease(Tween.EASE_IN)
	_flash_tween.tween_callback(func() -> void: _level_up_flash.visible = false)
