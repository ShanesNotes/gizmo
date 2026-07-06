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
@onready var _stats_value: Label = %StatsValue
@onready var _retry_button: Button = %RetryButton

func _ready() -> void:
	_root.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)


## Outcome copy for a finished run, keyed off the Simulation phase. Pure — so it's
## unit-tested headless. A run still "playing" has no outcome (defensive: the title
## stays empty, so a mis-call shows nothing rather than a wrong banner).
static func outcome(phase: String) -> Dictionary:
	if phase == Simulation.PHASE_COMPLETE:
		return {"title": "Beacon Rekindled", "flavor": "The hearth catches; the cold world holds back.", "win": true}
	if phase == Simulation.PHASE_GAMEOVER:
		return {"title": "Gizmo's light failed", "flavor": "The Beacon waits in the dark.", "win": false}
	return {"title": "", "flavor": "", "win": false}


## Populate the panel from the finished run and reveal it.
func show_outcome(sim: Simulation) -> void:
	var copy := outcome(sim.phase)
	_title.text = copy["title"]
	_flavor.text = copy["flavor"]
	_stats_value.text = "Level %d · %d kills · %d Sparks" % [sim.level, sim.kills, sim.xp]
	_root.visible = true
	_retry_button.grab_focus()


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
