extends SceneTree

# Grip-pose proof for lantern_staff_01 (canon proof_policy): mounts the staff
# wrapper on Gizmo's WeaponMount in place of the wrench and renders idle +
# swing-contact frames at the fixed camera. Run WITH a display:
#   godot --user-data-dir /tmp/godot-night-assets --path . --script res://tests/_probe_lantern_grip_proof.gd

const OUT_DIR := "/tmp/gizmo-pose-proof"
const STAFF_SCENE := "res://assets/weapons/lantern_staff_01.tscn"
const SHOTS := [
	["idle", 1.2],
	["attack_1", 0.10],
	["attack_3", 0.14],
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
	var skeleton := player.get_node_or_null("VisualPivot/Model/UniRigArmature/Skeleton3D")
	var mount: BoneAttachment3D = skeleton.get_node_or_null("WeaponMount") if skeleton != null else null
	if anim_player == null or mount == null:
		printerr("no AnimationPlayer or WeaponMount")
		quit(1)
		return

	# Swap the wrench for the staff on the same mount.
	for child in mount.get_children():
		child.queue_free()
	var staff := (load(STAFF_SCENE) as PackedScene).instantiate()
	mount.add_child(staff)
	await process_frame

	controller.set_physics_process(false)
	var visual := player.get_node_or_null("VisualPivot")
	if visual != null:
		visual.set_physics_process(false)

	for shot in SHOTS:
		anim_player.play("gizmo/%s" % shot[0])
		anim_player.seek(float(shot[1]), true)
		anim_player.pause()
		await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		var out_path := "%s/lantern_grip_%s_%03d.png" % [OUT_DIR, shot[0], int(float(shot[1]) * 1000.0)]
		image.save_png(out_path)
		print("saved ", out_path)

	quit(0)
