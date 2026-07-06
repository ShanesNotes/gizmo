class_name GizmoPlayer
extends CharacterBody3D

const PlayerMotorScript := preload("res://scripts/player/player_motor.gd")

@export_group("Movement")
@export var move_speed: float = 4.0
@export var acceleration: float = 32.0
@export var friction: float = 40.0
@export var turn_speed: float = 14.0

@export_group("Dash")
@export var dash_speed: float = 14.0
@export var dash_duration: float = 0.25

@onready var visual_pivot: Node3D = $VisualPivot
@onready var ability_component: AbilityComponent = $AbilityComponent
@onready var ability_input_router: AbilityInputRouter = $AbilityInputRouter

var motor = PlayerMotorScript.new()

func _ready() -> void:
	_configure_motor()
	_configure_default_dash()
	if ability_input_router != null:
		ability_input_router.bind_component(ability_component)
		ability_input_router.bind_direction_provider(Callable(self, "current_input_direction"))
	if ability_component != null and not ability_component.dash_started.is_connected(_on_dash_started):
		ability_component.dash_started.connect(_on_dash_started)

func _physics_process(delta: float) -> void:
	var input_direction: Vector3 = current_input_direction()
	velocity = motor.step(velocity, input_direction, delta)
	move_and_slide()
	_face_direction(motor.facing_direction, delta)

func current_input_direction() -> Vector3:
	var input_vector := Input.get_vector(
		&"gizmo_move_left",
		&"gizmo_move_right",
		&"gizmo_move_up",
		&"gizmo_move_down"
	)
	return PlayerMotorScript.input_vector_to_world_direction(input_vector)

func trigger_action(action: StringName, direction: Vector3 = Vector3.ZERO) -> bool:
	if ability_input_router == null:
		return false
	return ability_input_router.handle_action_pressed(action, direction)

func _configure_motor() -> void:
	motor.move_speed = move_speed
	motor.acceleration = acceleration
	motor.friction = friction
	motor.dash_speed = dash_speed
	motor.dash_duration = dash_duration

func _configure_default_dash() -> void:
	if ability_component == null:
		return
	var dash := ability_component.get_ability(&"dash") as DashAbility
	if dash == null:
		return
	dash.dash_duration = dash_duration
	dash.iframe_duration = minf(dash.iframe_duration, dash_duration)
	dash.dash_speed = dash_speed

func _on_dash_started(direction: Vector3, speed: float, duration: float) -> void:
	var dash_direction: Vector3 = direction
	if dash_direction == Vector3.ZERO:
		dash_direction = current_input_direction()
	motor.begin_dash(dash_direction, speed, duration)

func _face_direction(direction: Vector3, delta: float) -> void:
	if visual_pivot == null:
		return
	var flat_direction: Vector3 = PlayerMotorScript.flatten_direction(direction)
	if flat_direction == Vector3.ZERO:
		return
	var target_yaw := atan2(flat_direction.x, flat_direction.z)
	var turn_weight := 1.0 - exp(-turn_speed * maxf(delta, 0.0))
	visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_yaw, turn_weight)
