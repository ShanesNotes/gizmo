extends SceneTree

# Pose-proof probe (canon proof_policy: camera evidence for animation work).
# Renders each GizmoAnimationController clip at representative phase times and
# saves PNGs for readability review. Run WITH a display (not --headless):
#   godot --user-data-dir /tmp/fable-assets-agent --path . --script res://tests/_probe_pose_proof.gd

const OUT_DIR := "/tmp/gizmo-pose-proof"
const SHOTS := [
	["idle", 1.2],
	["run", 0.0],
	["run", 0.12],
	["dash", 0.07],
	["attack_1", 0.10],
	["attack_1", 0.20],
	["attack_2", 0.10],
	["attack_3", 0.14],
	["special", 0.22],
	["spark_cast", 0.15],
	["hit_react", 0.06],
	["surge", 0.12],
	["idle_fidget_key", 0.55],
	["idle_fidget_chirp", 0.50],
	["campfire_sit", 1.6],
	["death", 1.2],
	["victory", 0.45],
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	root.size = Vector2i(960, 540)

	var world := Node3D.new()
	root.add_child(world)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	light.light_energy = 1.4
	world.add_child(light)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, 140.0, 0.0)
	fill.light_energy = 0.5
	world.add_child(fill)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)

	var camera := Camera3D.new()
	var camera_position := Vector3(1.6, 3.4, 2.9)
	var camera_target := Vector3(0.0, 0.8, 0.0)
	camera.transform = Transform3D(
		Basis.looking_at((camera_target - camera_position).normalized(), Vector3.UP),
		camera_position
	)
	camera.fov = 45.0
	world.add_child(camera)
	camera.current = true

	var player_scene: PackedScene = load("res://scenes/gizmo_player.tscn")
	var player := player_scene.instantiate()
	world.add_child(player)
	await process_frame
	await process_frame

	var controller: Node = player.get_node_or_null("AnimationController")
	if controller == null:
		printerr("no AnimationController")
		quit(1)
		return
	var anim_player := controller.get("animation_player") as AnimationPlayer
	if anim_player == null:
		printerr("no AnimationPlayer")
		quit(1)
		return

	# Freeze the procedural + FSM layers so each frame holds a pure clip pose.
	controller.set_physics_process(false)
	var visual := player.get_node_or_null("VisualPivot")
	if visual != null:
		visual.set_physics_process(false)

	for shot in SHOTS:
		var clip := "gizmo/%s" % shot[0]
		anim_player.play(clip)
		anim_player.seek(float(shot[1]), true)
		anim_player.pause()
		await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		var out_path := "%s/%s_%03d.png" % [OUT_DIR, shot[0], int(float(shot[1]) * 1000.0)]
		image.save_png(out_path)
		print("saved ", out_path)

	quit(0)
