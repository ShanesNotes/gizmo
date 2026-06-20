extends CharacterBody3D

## How fast Gizmo moves, in metres per second.
@export var speed: float = 6.0
## How quickly he reaches top speed and how hard he brakes.
@export var acceleration: float = 40.0
@export var friction: float = 50.0

func _physics_process(delta: float) -> void:
	# 1. Read input as a 2D vector: x = left/right, y = up/down on screen.
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	# 2. Map it onto the ground plane: X = sideways, Z = toward/away from camera.
	var direction := Vector3(input.x, 0.0, input.y)
	# 3. Accelerate toward target velocity, or brake to a stop.
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	# 4. Let the engine move him and resolve collisions.
	move_and_slide()
