class_name CombatEffects
extends RefCounted

## Greybox combat-feedback kit (HZ-084). Every helper is purely cosmetic:
## no gameplay state is read or written, every spawned node frees itself,
## and everything is safe headless (plain scene-tree tweens).

const HIT_FLASH_UP := 0.08
const HIT_FLASH_DOWN := 0.12
const DEATH_POP_SECONDS := 0.22
const BURST_RING_SECONDS := 0.4
const SWING_WEDGE_SECONDS := 0.18
const STAGGER_TILT_RADIANS := 0.38

static func flash_hit(visual_root: Node3D) -> void:
	if visual_root == null or not visual_root.is_inside_tree():
		return
	var mesh := _first_mesh(visual_root)
	if mesh == null:
		return
	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color(1.0, 0.98, 0.9, 1.0)
	flash.emission_enabled = true
	flash.emission = Color(1.0, 0.92, 0.7, 1.0)
	flash.emission_energy_multiplier = 1.6
	mesh.material_override = flash
	var tween := mesh.create_tween()
	tween.tween_interval(HIT_FLASH_UP)
	tween.tween_property(flash, "emission_energy_multiplier", 0.0, HIT_FLASH_DOWN)
	tween.tween_callback(func() -> void:
		if is_instance_valid(mesh):
			mesh.material_override = null)

static func death_pop(body: Node3D) -> void:
	## Squash-and-fade a corpse, then free it. Caller must have finished all
	## gameplay bookkeeping first — this only delays the visual removal.
	## NEVER scales the physics body (Jolt rejects non-uniform body scales);
	## the squash targets the visual subtree, and collision is disabled at once.
	if body == null or not body.is_inside_tree():
		if body != null and is_instance_valid(body):
			body.queue_free()
		return
	if body is CollisionObject3D:
		for child in body.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).set_deferred("disabled", true)
	if body is PhysicsBody3D:
		body.set_physics_process(false)
	var visual: Node3D = body.get_node_or_null("VisualPivot") as Node3D
	if visual == null:
		var mesh_node := _first_mesh(body)
		visual = mesh_node
	if visual == null:
		body.queue_free()
		return
	var tween := body.create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector3(1.25, 0.05, 1.25), DEATH_POP_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var mesh := _first_mesh(visual)
	if mesh != null:
		var fade := StandardMaterial3D.new()
		fade.albedo_color = Color(0.9, 0.85, 0.75, 1.0)
		fade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = fade
		tween.tween_property(fade, "albedo_color:a", 0.0, DEATH_POP_SECONDS)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(body):
			body.queue_free())

static func spawn_burst_ring(parent: Node, origin: Vector3, radius: float, color: Color = Color(1.0, 0.72, 0.3, 0.9)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.34
	torus.outer_radius = 0.5
	ring.mesh = torus
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.4
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = material
	parent.add_child(ring)
	ring.global_position = Vector3(origin.x, maxf(origin.y, 0.1), origin.z)
	ring.scale = Vector3(0.2, 0.35, 0.2)
	var target := maxf(radius, 0.5) / 0.5
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(target, 0.5, target), BURST_RING_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, BURST_RING_SECONDS)
	tween.chain().tween_callback(ring.queue_free)

static func spawn_swing_wedge(parent: Node, origin: Vector3, forward: Vector3, range_units: float, color: Color = Color(1.0, 0.9, 0.6, 0.7)) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var wedge := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(maxf(range_units, 0.5) * 1.1, 0.04, maxf(range_units, 0.5))
	wedge.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.1
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wedge.material_override = material
	parent.add_child(wedge)
	var flat := Vector3(forward.x, 0.0, forward.z)
	if flat.length_squared() <= 0.000001:
		flat = Vector3(0.0, 0.0, -1.0)
	flat = flat.normalized()
	wedge.global_position = Vector3(origin.x, 0.12, origin.z) + flat * (maxf(range_units, 0.5) * 0.5)
	wedge.rotation.y = atan2(flat.x, flat.z)
	var tween := wedge.create_tween()
	tween.tween_property(material, "albedo_color:a", 0.0, SWING_WEDGE_SECONDS)
	tween.tween_callback(wedge.queue_free)

static func apply_stagger_read(body: Node3D, visual_root: Node3D, duration: float) -> void:
	if visual_root == null or not visual_root.is_inside_tree():
		return
	var mesh := _first_mesh(visual_root)
	var gray: StandardMaterial3D = null
	if mesh != null and mesh.material_override == null:
		gray = StandardMaterial3D.new()
		gray.albedo_color = Color(0.32, 0.32, 0.38, 1.0)
		mesh.material_override = gray
	var original_scale_y := visual_root.scale.y
	var tween := visual_root.create_tween()
	tween.tween_property(visual_root, "rotation:x", STAGGER_TILT_RADIANS, 0.08)
	tween.parallel().tween_property(visual_root, "scale:y", original_scale_y * 0.8, 0.08)
	tween.tween_interval(maxf(duration - 0.16, 0.0))
	tween.tween_property(visual_root, "rotation:x", 0.0, 0.08)
	tween.parallel().tween_property(visual_root, "scale:y", original_scale_y, 0.08)
	tween.tween_callback(func() -> void:
		if mesh != null and is_instance_valid(mesh) and mesh.material_override == gray:
			mesh.material_override = null)

static func _first_mesh(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root
	for child in root.get_children():
		var found := _first_mesh(child)
		if found != null:
			return found
	return null
