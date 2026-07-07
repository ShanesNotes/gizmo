class_name HubController
extends Node3D

const MetaState := preload("res://scripts/meta/meta_state.gd")

signal run_requested()

const RUN_SURFACE_LOAD_FAILURE_COPY := "Run surface failed to load - run the import step (see docs/hades-pivot/export.md)."

@export var movement_speed: float = 4.0
@export var acceleration: float = 32.0
@export var friction: float = 40.0

## Where mirror purchases persist; tests point this at a scratch save file.
var mirror_save_path: String = MetaState.DEFAULT_SAVE_PATH

const MIRROR_STAT_ROWS := {
	"dash_charges": "GYRE STEP - +1 dash charge",
	"guard_max": "HEARTHPLATE - +guard",
	"draft_rerolls": "MARGIN'S GRACE - +1 draft reroll",
}

var meta_state: MetaState:
	get:
		return _meta_state
	set(value):
		_meta_state = value
		_render_meta_state()

@onready var _scrap_label: Label = %ScrapLabel
@onready var _run_surface_failure_label: Label = %RunSurfaceFailureLabel
@onready var _run_door: Area3D = %RunDoor
@onready var _mirror_zone: Area3D = %MirrorZone
@onready var _mirror_panel: Control = %MirrorPanel
@onready var _player_body: CharacterBody3D = %GizmoPlaceholder

var _meta_state: MetaState = null
var _requested_body_ids: Dictionary = {}

func _ready() -> void:
	if _meta_state == null:
		_meta_state = MetaState.new()
	_run_door.body_entered.connect(_on_run_door_body_entered)
	_run_door.body_exited.connect(_on_run_door_body_exited)
	_mirror_zone.body_entered.connect(_on_mirror_zone_body_entered)
	_mirror_zone.body_exited.connect(_on_mirror_zone_body_exited)
	_connect_mirror_buy_buttons()
	clear_run_surface_load_failure()
	_render_meta_state()

func _physics_process(delta: float) -> void:
	if _player_body == null:
		return

	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()

	if direction != Vector3.ZERO:
		_player_body.velocity.x = move_toward(_player_body.velocity.x, direction.x * movement_speed, acceleration * delta)
		_player_body.velocity.z = move_toward(_player_body.velocity.z, direction.z * movement_speed, acceleration * delta)
	else:
		_player_body.velocity.x = move_toward(_player_body.velocity.x, 0.0, friction * delta)
		_player_body.velocity.z = move_toward(_player_body.velocity.z, 0.0, friction * delta)

	_player_body.move_and_slide()

func _render_meta_state() -> void:
	if _scrap_label == null:
		return
	if _meta_state == null:
		_scrap_label.text = "SCRAP 0"
		_render_mirror_panel()
		return
	_scrap_label.text = "SCRAP %d" % _meta_state.scrap_banked
	_render_mirror_panel()

func show_run_surface_load_failure(message: String = RUN_SURFACE_LOAD_FAILURE_COPY) -> void:
	if _run_surface_failure_label == null:
		return
	_run_surface_failure_label.text = message
	_run_surface_failure_label.visible = true

func clear_run_surface_load_failure() -> void:
	if _run_surface_failure_label == null:
		return
	_run_surface_failure_label.text = RUN_SURFACE_LOAD_FAILURE_COPY
	_run_surface_failure_label.visible = false

## The Mirror is the meta-upgrade surface: a brass panel listing the three
## stat grades with their next price; purchases spend banked scrap and persist.
func purchase_mirror_grade(stat: String) -> bool:
	if _meta_state == null:
		return false
	if not _meta_state.purchase_grade(stat):
		return false
	var save_error := _meta_state.save_to_path(mirror_save_path)
	if save_error != OK:
		push_error("HubController could not persist mirror purchase: %s" % save_error)
	_render_meta_state()
	return true

func _connect_mirror_buy_buttons() -> void:
	for stat in MIRROR_STAT_ROWS.keys():
		var button := _mirror_buy_button(stat)
		if button != null:
			button.pressed.connect(func() -> void: purchase_mirror_grade(stat))

func _mirror_row(stat: String) -> Control:
	if _mirror_panel == null:
		return null
	return _mirror_panel.find_child("MirrorRow_%s" % stat, true, false) as Control

func _mirror_buy_button(stat: String) -> Button:
	var row := _mirror_row(stat)
	if row == null:
		return null
	return row.find_child("BuyButton", true, false) as Button

func _render_mirror_panel() -> void:
	if _mirror_panel == null:
		return
	for stat in MIRROR_STAT_ROWS.keys():
		var row := _mirror_row(stat)
		if row == null:
			continue
		var grade := _meta_state.get_stat_grade(stat) if _meta_state != null else 0
		var cap := int(MetaState.STAT_GRADE_CAPS.get(stat, 0))
		var row_label := row.find_child("RowLabel", true, false) as Label
		if row_label != null:
			row_label.text = "%s  [%d/%d]" % [MIRROR_STAT_ROWS[stat], grade, cap]
		var button := _mirror_buy_button(stat)
		if button == null:
			continue
		if grade >= cap or grade >= MetaState.STAT_GRADE_PRICES.size():
			button.text = "KEPT"
			button.disabled = true
		else:
			var price := int(MetaState.STAT_GRADE_PRICES[grade])
			button.text = "%d SCRAP" % price
			button.disabled = _meta_state == null or _meta_state.scrap_banked < price

func _on_mirror_zone_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	if _mirror_panel == null:
		return
	_render_mirror_panel()
	_mirror_panel.visible = true

func _on_mirror_zone_body_exited(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	if _mirror_panel != null:
		_mirror_panel.visible = false

func _on_run_door_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	var body_id := body.get_instance_id()
	if _requested_body_ids.has(body_id):
		return
	_requested_body_ids[body_id] = true
	run_requested.emit()

func _on_run_door_body_exited(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	_requested_body_ids.erase(body.get_instance_id())
