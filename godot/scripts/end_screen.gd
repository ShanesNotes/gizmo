class_name EndScreen
extends CanvasLayer

## Hub-return summary for a finished run.

## Death/victory presentation beat: the summary eases in from ink-dark over
## this long instead of popping (the panel is visible immediately; only its
## modulate alpha is animated, so overlay/visibility contracts are untouched).
const INK_FADE_SECONDS := 0.8

var _fade_tween: Tween = null

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
	return "VIGIL KEPT" if victory else "THE LIGHT FAILED"

static func result_for(victory: bool) -> String:
	return "KEPT" if victory else "FAILED"

func show_run_summary(stats: Dictionary) -> void:
	var victory := bool(stats.get("victory", false))
	_title.text = title_for(victory)
	_flavor.text = "Margin enters it in the Codex."
	_result_value.text = result_for(victory)
	_rooms_value.text = str(maxi(0, int(stats.get("rooms_cleared", 0))))
	_boons_value.text = str(maxi(0, int(stats.get("boons_taken", 0))))
	_scrap_value.text = str(maxi(0, int(stats.get("scrap_banked", 0))))
	_survived_value.text = Hud.format_clock(maxf(0.0, float(stats.get("survived_seconds", 0.0))))
	_play_ink_fade()
	_root.visible = true
	_retry_button.grab_focus()

func _play_ink_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	if not is_inside_tree():
		_root.modulate.a = 1.0
		return
	_root.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_root, "modulate:a", 1.0, INK_FADE_SECONDS) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

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
	_title.text = "BEACON REKINDLED" if victory else "GIZMO'S LIGHT FAILED"

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
