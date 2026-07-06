class_name EndScreen
extends CanvasLayer

## Hub-return summary for a finished run.

@onready var _root: Control = %Root
@onready var _title: Label = %TitleLabel
@onready var _flavor: Label = %FlavorLabel
@onready var _result_value: Label = %ResultValue
@onready var _rooms_value: Label = %RoomsValue
@onready var _boons_value: Label = %BoonsValue
@onready var _scrap_value: Label = %ScrapValue
@onready var _survived_value: Label = %SurvivedValue
@onready var _retry_button: Button = %RetryButton

func _ready() -> void:
	_root.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)

static func title_for(victory: bool) -> String:
	return "RUN COMPLETE" if victory else "RUN LOST"

static func result_for(victory: bool) -> String:
	return "COMPLETE" if victory else "LOST"

func show_run_summary(stats: Dictionary) -> void:
	var victory := bool(stats.get("victory", false))
	_title.text = title_for(victory)
	_flavor.text = "Run summary recorded."
	_result_value.text = result_for(victory)
	_rooms_value.text = str(maxi(0, int(stats.get("rooms_cleared", 0))))
	_boons_value.text = str(maxi(0, int(stats.get("boons_taken", 0))))
	_scrap_value.text = str(maxi(0, int(stats.get("scrap_banked", 0))))
	_survived_value.text = Hud.format_clock(maxf(0.0, float(stats.get("survived_seconds", 0.0))))
	_root.visible = true
	_retry_button.grab_focus()

func show_outcome(sim: Simulation) -> void:
	var victory := sim != null and sim.phase == Simulation.PHASE_COMPLETE
	var survived_seconds := sim.elapsed if sim != null else 0.0
	show_run_summary({
		"rooms_cleared": 0,
		"boons_taken": 0,
		"scrap_banked": 0,
		"survived_seconds": survived_seconds,
		"victory": victory,
	})
	# Compatibility for the pre-pivot controller path. Hades-flow callers should
	# use show_run_summary(stats).
	_title.text = "BEACON REKINDLED" if victory else "GIZMO OFFLINE"

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
