extends CharacterBody3D

## How fast Gizmo moves, in metres per second.
@export var speed: float = 3.6
## How quickly he reaches top speed and how hard he brakes.
@export var acceleration: float = 40.0
@export var friction: float = 50.0
## How quickly he turns to face his travel direction.
@export var turn_speed: float = 12.0
## Minimum horizontal speed before the readable walk animation takes over.
@export var movement_animation_threshold: float = 0.2
## Pose/timing reference copied from the downloaded 6x6 concept walk sheet.
@export_file("*.png") var walk_reference_sprite_sheet_path: String = "res://assets/reference/gizmo/gizmo_walk_sheet_6x6.png"
## Keeps the hand-authored walk cycle close to the six-pose sprite reference.
@export var walk_animation_cycle_seconds: float = 0.72
## Subtle speed variation keeps the walk from looking like a fixed metronome.
@export var walk_animation_speed_min: float = 0.85
@export var walk_animation_speed_max: float = 1.2

@onready var visual_pivot: Node3D = $VisualPivot
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	_play_animation(&"idle_bob")

func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := Vector3(input.x, 0.0, input.y).normalized()
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		# Face travel direction (model's front is +Z), turning smoothly.
		var target_yaw := atan2(direction.x, direction.z)
		var turn_weight := 1.0 - exp(-turn_speed * delta)
		visual_pivot.rotation.y = lerp_angle(visual_pivot.rotation.y, target_yaw, turn_weight)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	move_and_slide()
	_update_animation_from_velocity()

func _update_animation_from_velocity() -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > movement_animation_threshold:
		var speed_ratio := clampf(horizontal_speed / maxf(speed, 0.001), 0.0, 1.0)
		animation_player.speed_scale = lerpf(walk_animation_speed_min, walk_animation_speed_max, speed_ratio)
		_play_animation(&"walk_bob")
	else:
		animation_player.speed_scale = 1.0
		_play_animation(&"idle_bob")

func _play_animation(name: StringName) -> void:
	if animation_player == null:
		return
	if not animation_player.has_animation(name):
		push_warning("Gizmo missing animation: %s" % name)
		return
	if animation_player.current_animation == name and animation_player.is_playing():
		return
	animation_player.play(name)
