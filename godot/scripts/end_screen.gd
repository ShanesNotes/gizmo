class_name EndScreen
extends CanvasLayer

## The win/lose screen for the Gizmo 3D rogue-lite (0012).
##
## The Simulation owns the run's phase (ADR 0002); this screen only renders the
## outcome. The controller calls show_outcome(sim) once, the frame the run leaves
## the "playing" phase — a win (the Beacon rekindled, ADR 0005) or a loss (HP 0).
## Starts hidden; RETRY reloads the scene for a fresh run.

@onready var _root: Control = %Root
@onready var _title: Label = %TitleLabel
@onready var _flavor: Label = %FlavorLabel
@onready var _survived_value: Label = %SurvivedValue
@onready var _level_value: Label = %LevelValue
@onready var _sparks_value: Label = %SparksValue
@onready var _retry_button: Button = %RetryButton

func _ready() -> void:
	_root.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)


## Outcome copy for a finished run, keyed off the Simulation phase. Pure — so it's
## unit-tested headless. A run still "playing" has no outcome (defensive: the title
## stays empty, so a mis-call shows nothing rather than a wrong banner).
static func outcome(phase: String) -> Dictionary:
	if phase == Simulation.PHASE_COMPLETE:
		return {"title": "BEACON REKINDLED", "flavor": "The hearth catches; the cold world holds back.", "win": true}
	if phase == Simulation.PHASE_GAMEOVER:
		return {"title": "GIZMO OFFLINE", "flavor": "Gizmo's light failed.", "win": false}
	return {"title": "", "flavor": "", "win": false}


## Populate the panel from the finished run and reveal it. Reuses Hud.format_clock
## for the survived time — the same pure formatter the HUD's run clock uses.
func show_outcome(sim: Simulation) -> void:
	var copy := outcome(sim.phase)
	_title.text = copy["title"]
	_flavor.text = copy["flavor"]
	# Survived = whole seconds lasted: floor the partial second (you died at 2:17.6,
	# not 2:18), and clamp a win's slight overshoot to the run length. Pre-flooring an
	# integer into Hud.format_clock (which rounds up for the count-down clock) yields
	# floor semantics here — one shared formatter, the caller picks the rounding.
	_survived_value.text = Hud.format_clock(floorf(minf(sim.elapsed, sim.run_duration)))
	_level_value.text = str(sim.level)
	_sparks_value.text = str(sim.xp)
	_root.visible = true
	_retry_button.grab_focus()


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
