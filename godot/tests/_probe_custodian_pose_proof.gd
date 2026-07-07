extends SceneTree

# Fixed-camera pose proof for the rigged custodian_boss.glb (canon proof_policy).
# Run WITH a display:
#   godot --user-data-dir /tmp/godot-night-assets --path . --script res://tests/_probe_custodian_pose_proof.gd

const OUT_DIR := "/tmp/gizmo-pose-proof"
const SHOTS := [
	["idle", 2.6],
	["phase_shift", 0.48],
	["attack", 1.20],
	["attack_sweep", 0.90],
	["death", 0.62],
	["death", 2.50],
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
	plane.size = Vector2(10.0, 10.0)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)
	var camera := Camera3D.new()
	var camera_position := Vector3(2.4, 4.6, 4.2)
	var camera_target := Vector3(0.0, 1.1, 0.0)
	camera.transform = Transform3D(
		Basis.looking_at((camera_target - camera_position).normalized(), Vector3.UP),
		camera_position
	)
	camera.fov = 45.0
	world.add_child(camera)
	camera.current = true

	var boss_scene: PackedScene = load("res://assets/enemies/custodian_boss.glb")
	var boss := boss_scene.instantiate()
	world.add_child(boss)
	await process_frame
	await process_frame

	var anim := boss.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim == null:
		printerr("no AnimationPlayer in custodian_boss.glb")
		quit(1)
		return

	for shot in SHOTS:
		var key := ""
		for library_name in anim.get_animation_library_list():
			if anim.get_animation_library(library_name).has_animation(StringName(shot[0])):
				key = "%s/%s" % [library_name, shot[0]] if String(library_name) != "" else String(shot[0])
				break
		if key == "":
			printerr("missing clip ", shot[0])
			continue
		anim.play(key)
		anim.seek(float(shot[1]), true)
		anim.pause()
		await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		var out_path := "%s/custodian_%s_%03d.png" % [OUT_DIR, shot[0], int(float(shot[1]) * 100.0)]
		image.save_png(out_path)
		print("saved ", out_path)
	quit(0)
