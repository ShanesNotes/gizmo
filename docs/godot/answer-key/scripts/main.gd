extends Node3D

var sim: Simulation = Simulation.new()
var state: Dictionary = {}

@onready var player_avatar: PlayerAvatar3D = %PlayerAvatar
@onready var camera_rig: CameraRig3D = $CameraRig
@onready var hud: HudPresenter = $HUD
@onready var ground: MeshInstance3D = $World/Ground

func _ready() -> void:
	state = sim.create_game_state()
	_configure_stage_ground()
	_apply_state()

func _configure_stage_ground() -> void:
	var plane := ground.mesh as PlaneMesh
	if plane == null:
		return
	var stage_size: Vector2 = SimSpace.world_size_to_stage(state["world"])
	var unique_plane := plane.duplicate() as PlaneMesh
	unique_plane.size = stage_size
	ground.mesh = unique_plane

func _physics_process(delta: float) -> void:
	sim.update_state(state, _read_input_state(), delta)
	_apply_state()

func _read_input_state() -> Dictionary:
	var direction: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	return {
		"x": direction.x,
		"y": direction.y,
	}

func _apply_state() -> void:
	var player: Dictionary = state["player"]
	var player_stage_position: Vector3 = SimSpace.to_world_from_snapshot(player)
	player_avatar.apply_snapshot(player)
	camera_rig.follow_stage_position(player_stage_position)
	hud.apply_state(state)
