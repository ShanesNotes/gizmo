extends CharacterBody3D

## How fast Gizmo moves, in metres per second.
@export var speed: float = 6.0
## How quickly he reaches top speed and how hard he brakes.
@export var acceleration: float = 40.0
@export var friction: float = 50.0
## How quickly he turns to face his travel direction.
@export var turn_speed: float = 12.0

@onready var model: Node3D = $Model

func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var direction := Vector3(input.x, 0.0, input.y)
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
		# Face travel direction (model's front is +Z), turning smoothly.
		var target_yaw := atan2(direction.x, direction.z)
		var turn_weight := 1.0 - exp(-turn_speed * delta)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, turn_weight)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	move_and_slide()
