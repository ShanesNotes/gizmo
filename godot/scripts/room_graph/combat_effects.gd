class_name CombatEffects
extends RefCounted

## Greybox combat-feedback kit (HZ-084). Every helper is purely cosmetic:
## no gameplay state is read or written, every spawned node frees itself,
## and everything is safe headless (plain scene-tree tweens).

## FX identity hue (docs/hades-pivot/design/hades-visual-workflow.md §1/§4):
## every player-threat/impact effect wears the ONE ember-amber identity hue,
## in every room, always. Layer recipe: crushed dark core + amber body + a
## saturated rim accent + a single near-white flash on the contact beat.
const FX_IDENTITY := Color(1.0, 0.62, 0.18, 1.0)
const FX_IDENTITY_RIM := Color(1.0, 0.82, 0.45, 1.0)
const FX_CONTACT_FLASH := Color(1.0, 0.95, 0.85, 1.0)
const FX_CORE_DARK := Color(0.16, 0.09, 0.03, 1.0)

const HIT_FLASH_UP := 0.08
const HIT_FLASH_DOWN := 0.12
const DEATH_POP_SECONDS := 0.22
const SWING_TRAIL_SEGMENTS := 9
const SWING_TRAIL_HEIGHT := 1.15
const SWING_TRAIL_FADE := 0.14
const DEATH_IMPLOSION_SECONDS := 0.14
const DEATH_SPARK_COUNT := 8
const DEATH_SPARK_SECONDS := 0.35
const SURGE_WAVE_SECONDS := 0.35
const SURGE_AFTERGLOW_SECONDS := 0.6
const STAGGER_TILT_RADIANS := 0.38
const DAMAGE_NUMBER_SECONDS := 0.6
const DAMAGE_NUMBER_RISE := 0.9
const DAMAGE_NUMBER_COLOR := Color(1.0, 0.95, 0.8, 1.0)
const DAMAGE_NUMBER_CRIT_COLOR := Color(1.0, 0.62, 0.18, 1.0)
const PLAYER_HIT_NUMBER_COLOR := Color(0.95, 0.25, 0.2, 1.0)
const SHIELDED_NUMBER_COLOR := Color(0.48, 0.62, 0.78, 1.0)
const HIT_STOP_SECONDS := 0.05
const HIT_STOP_TIME_SCALE := 0.05
const CAST_BOLT_SPEED := 28.0
const CAST_BOLT_TRAIL_SEGMENTS := 3

static func spawn_damage_number(parent: Node, origin: Vector3, amount: float, color: Color = DAMAGE_NUMBER_COLOR) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label3D.new()
	label.text = str(maxi(1, roundi(amount)))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 64
	label.outline_size = 14
	label.outline_modulate = Color(0.08, 0.05, 0.02, 0.9)
	label.modulate = color
	parent.add_child(label)
	label.global_position = origin
	var drift := Vector3(randf_range(-0.35, 0.35), 0.0, randf_range(-0.15, 0.15))
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", origin + drift + Vector3(0.0, DAMAGE_NUMBER_RISE, 0.0), DAMAGE_NUMBER_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, DAMAGE_NUMBER_SECONDS * 0.55) \
		.set_delay(DAMAGE_NUMBER_SECONDS * 0.45)
	tween.tween_property(label, "outline_modulate:a", 0.0, DAMAGE_NUMBER_SECONDS * 0.55) \
		.set_delay(DAMAGE_NUMBER_SECONDS * 0.45)
	tween.chain().tween_callback(label.queue_free)

## Brief global time freeze for hit punch. Cosmetic-only and guarded: it no-ops
## headless (suite determinism) and never stacks; restore ignores time scale so
## the freeze can always end itself.
static func hit_stop(host: Node, duration: float = HIT_STOP_SECONDS) -> void:
	if host == null or not host.is_inside_tree():
		return
	if DisplayServer.get_name() == "headless":
		return
	if Engine.time_scale < 0.999:
		return
	Engine.time_scale = HIT_STOP_TIME_SCALE
	var timer := host.get_tree().create_timer(maxf(duration, 0.01), true, false, true)
	timer.timeout.connect(func() -> void:
		Engine.time_scale = 1.0)

## Cosmetic cast read: a fast ember projectile with a short ghost trail. The
## resolver still applies damage immediately; this only makes the cast legible.
static func spawn_cast_bolt(parent: Node, from: Vector3, to: Vector3) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var root := Node3D.new()
	root.name = "CastBoltFX"
	parent.add_child(root)
	root.global_position = from

	var delta := to - from
	var distance := delta.length()
	var direction := delta / distance if distance > 0.000001 else Vector3(0.0, 0.0, -1.0)
	var flight_seconds := maxf(distance / CAST_BOLT_SPEED, 0.03)

	var core := MeshInstance3D.new()
	core.name = "Core"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.12
	core_mesh.height = 0.24
	core.mesh = core_mesh
	var core_material := _fx_material(FX_IDENTITY_RIM, 2.4)
	core.material_override = core_material
	root.add_child(core)

	var trail_materials: Array[StandardMaterial3D] = []
	for index in range(CAST_BOLT_TRAIL_SEGMENTS):
		var ghost := MeshInstance3D.new()
		ghost.name = "Trail%d" % (index + 1)
		var ghost_mesh := SphereMesh.new()
		ghost_mesh.radius = 0.09 - float(index) * 0.015
		ghost_mesh.height = ghost_mesh.radius * 2.0
		ghost.mesh = ghost_mesh
		var alpha := 0.52 - float(index) * 0.14
		var ghost_material := _fx_material(Color(FX_IDENTITY.r, FX_IDENTITY.g, FX_IDENTITY.b, alpha), 1.4)
		ghost.material_override = ghost_material
		root.add_child(ghost)
		ghost.position = -direction * (0.22 + float(index) * 0.18)
		trail_materials.append(ghost_material)

	var tween := root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(root, "global_position", to, flight_seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(core, "scale", Vector3.ONE * 0.45, flight_seconds)
	tween.tween_property(core_material, "albedo_color:a", 0.0, flight_seconds * 0.55) \
		.set_delay(flight_seconds * 0.45)
	for material in trail_materials:
		tween.tween_property(material, "albedo_color:a", 0.0, flight_seconds * 0.8)
	tween.chain().tween_callback(root.queue_free)

## Cosmetic camera shake on the active 3D camera, if it is a RoomCamera-style
## rig exposing shake(). Safe headless: no camera means no-op.
static func shake_active_camera(host: Node, strength: float = 0.12, duration: float = 0.1) -> void:
	if host == null or not host.is_inside_tree():
		return
	var camera := host.get_viewport().get_camera_3d()
	if camera != null and camera.has_method(&"shake"):
		camera.call(&"shake", strength, duration)

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

## Unshaded identity-hue material helper (FX layer recipe base coat).
static func _fx_material(color: Color, energy: float = 1.4) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b, 1.0)
	material.emission_energy_multiplier = energy
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	return material

## Melee swing read: a thin arc TRAIL of blade segments at weapon height that
## sweeps with the actual swing (not a floor decal). Segments light up in
## sweep order across `sweep_seconds` (the clip's windup->contact window) —
## the sweep head runs a step ahead in near-white so the contact beat pops.
static func spawn_swing_trail(
	parent: Node,
	origin: Vector3,
	forward: Vector3,
	range_units: float,
	arc_degrees: float,
	sweep_seconds: float,
	sweep_sign: float = 1.0
) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var flat := Vector3(forward.x, 0.0, forward.z)
	if flat.length_squared() <= 0.000001:
		flat = Vector3(0.0, 0.0, -1.0)
	flat = flat.normalized()
	var base_yaw := atan2(flat.x, flat.z)
	var half_arc := deg_to_rad(clampf(arc_degrees, 10.0, 360.0) * 0.5)
	var radius := maxf(range_units, 0.5) * 0.8
	var seg_length := (2.0 * half_arc * radius) / float(SWING_TRAIL_SEGMENTS) * 1.15
	var sweep := maxf(sweep_seconds, 0.04)
	var direction := 1.0 if sweep_sign >= 0.0 else -1.0

	for i in range(SWING_TRAIL_SEGMENTS):
		var progress := float(i) / float(SWING_TRAIL_SEGMENTS - 1)
		var angle := base_yaw + direction * lerpf(half_arc, -half_arc, progress)
		var blade := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(seg_length, 0.55, 0.05)
		blade.mesh = mesh
		var is_head := i == SWING_TRAIL_SEGMENTS - 1
		var color := FX_CONTACT_FLASH if is_head else FX_IDENTITY
		var material := _fx_material(Color(color.r, color.g, color.b, 0.0), 1.9 if is_head else 1.4)
		blade.material_override = material
		parent.add_child(blade)
		blade.global_position = Vector3(origin.x, SWING_TRAIL_HEIGHT, origin.z) \
			+ Vector3(sin(angle), 0.0, cos(angle)) * radius
		blade.rotation.y = angle + PI * 0.5
		var delay := sweep * progress
		var tween := blade.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(material, "albedo_color:a", 0.95, 0.02)
		tween.tween_property(material, "albedo_color:a", 0.0, SWING_TRAIL_FADE) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(blade.queue_free)

## Enemy death: two timed layers — a collapse implosion (ring and dark core
## crushing inward) then a spark burst on the beat where it lands.
static func spawn_death_collapse(parent: Node, origin: Vector3, scale: float = 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var size := maxf(scale, 0.4)
	var center := Vector3(origin.x, maxf(origin.y, 0.2) + 0.6, origin.z)

	# Layer 1 — implosion: identity ring + crushed-dark core collapse inward.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.7
	torus.outer_radius = 0.85
	ring.mesh = torus
	var ring_material := _fx_material(FX_IDENTITY, 1.6)
	ring.material_override = ring_material
	parent.add_child(ring)
	ring.global_position = center
	ring.scale = Vector3.ONE * (1.3 * size)
	var ring_tween := ring.create_tween()
	ring_tween.set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector3.ONE * 0.08, DEATH_IMPLOSION_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	ring_tween.tween_property(ring_material, "albedo_color:a", 0.2, DEATH_IMPLOSION_SECONDS)
	ring_tween.chain().tween_callback(ring.queue_free)

	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.45
	core_mesh.height = 0.9
	core.mesh = core_mesh
	var core_material := _fx_material(FX_CORE_DARK, 0.2)
	core.material_override = core_material
	parent.add_child(core)
	core.global_position = center
	core.scale = Vector3.ONE * size
	var core_tween := core.create_tween()
	core_tween.tween_property(core, "scale", Vector3.ONE * 0.05, DEATH_IMPLOSION_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	core_tween.tween_callback(core.queue_free)

	# Layer 2 — on the implosion beat: near-white flash + amber spark burst.
	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.3
	flash_mesh.height = 0.6
	flash.mesh = flash_mesh
	var flash_material := _fx_material(Color(FX_CONTACT_FLASH.r, FX_CONTACT_FLASH.g, FX_CONTACT_FLASH.b, 0.0), 2.2)
	flash.material_override = flash_material
	parent.add_child(flash)
	flash.global_position = center
	var flash_tween := flash.create_tween()
	flash_tween.tween_interval(DEATH_IMPLOSION_SECONDS)
	flash_tween.tween_property(flash_material, "albedo_color:a", 0.95, 0.02)
	flash_tween.set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector3.ONE * (2.2 * size), 0.12) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash_material, "albedo_color:a", 0.0, 0.12)
	flash_tween.chain().tween_callback(flash.queue_free)

	for i in range(DEATH_SPARK_COUNT):
		var spark := MeshInstance3D.new()
		var spark_mesh := BoxMesh.new()
		spark_mesh.size = Vector3(0.22, 0.05, 0.05)
		spark.mesh = spark_mesh
		var spark_material := _fx_material(Color(FX_IDENTITY_RIM.r, FX_IDENTITY_RIM.g, FX_IDENTITY_RIM.b, 0.0), 1.8)
		spark.material_override = spark_material
		parent.add_child(spark)
		spark.global_position = center
		var spark_angle := TAU * float(i) / float(DEATH_SPARK_COUNT) + 0.4
		var out := Vector3(cos(spark_angle), 0.0, sin(spark_angle))
		spark.rotation.y = atan2(out.x, out.z) + PI * 0.5
		var spark_tween := spark.create_tween()
		spark_tween.tween_interval(DEATH_IMPLOSION_SECONDS)
		spark_tween.tween_property(spark_material, "albedo_color:a", 0.95, 0.02)
		spark_tween.set_parallel(true)
		spark_tween.tween_property(
			spark, "global_position",
			center + out * (1.5 * size) + Vector3(0.0, 0.5 - 0.9 * float(i % 2), 0.0),
			DEATH_SPARK_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		spark_tween.tween_property(spark_material, "albedo_color:a", 0.0, DEATH_SPARK_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		spark_tween.chain().tween_callback(spark.queue_free)

## Spark Surge: a ground shockwave — displacement ring (squashing torus) with
## a saturated rim runner, a near-white burst flash, and a lingering amber
## afterglow disc where the wave passed.
static func spawn_surge_shockwave(parent: Node, origin: Vector3, radius: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var target := maxf(radius, 1.0)
	var base := Vector3(origin.x, maxf(origin.y, 0.1), origin.z)

	# Displacement ring: thick amber torus that expands while flattening out.
	var wave := MeshInstance3D.new()
	var wave_mesh := TorusMesh.new()
	wave_mesh.inner_radius = 0.62
	wave_mesh.outer_radius = 1.0
	wave.mesh = wave_mesh
	var wave_material := _fx_material(FX_IDENTITY, 1.5)
	wave.material_override = wave_material
	parent.add_child(wave)
	wave.global_position = base
	wave.scale = Vector3(0.3, 0.6, 0.3)
	var wave_tween := wave.create_tween()
	wave_tween.set_parallel(true)
	wave_tween.tween_property(wave, "scale", Vector3(target, 0.22, target), SURGE_WAVE_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wave_tween.tween_property(wave_material, "albedo_color:a", 0.0, SURGE_WAVE_SECONDS)
	wave_tween.chain().tween_callback(wave.queue_free)

	# Rim runner: a thinner, brighter ring a beat ahead of the wave body.
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.9
	rim_mesh.outer_radius = 1.0
	rim.mesh = rim_mesh
	var rim_material := _fx_material(FX_IDENTITY_RIM, 2.0)
	rim.material_override = rim_material
	parent.add_child(rim)
	rim.global_position = base
	rim.scale = Vector3(0.35, 0.5, 0.35)
	var rim_tween := rim.create_tween()
	rim_tween.set_parallel(true)
	rim_tween.tween_property(rim, "scale", Vector3(target * 1.12, 0.16, target * 1.12), SURGE_WAVE_SECONDS * 0.85) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rim_tween.tween_property(rim_material, "albedo_color:a", 0.0, SURGE_WAVE_SECONDS * 0.85)
	rim_tween.chain().tween_callback(rim.queue_free)

	# Contact-beat flash at the epicenter.
	var flash := MeshInstance3D.new()
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.5
	flash_mesh.height = 1.0
	flash.mesh = flash_mesh
	var flash_material := _fx_material(FX_CONTACT_FLASH, 2.2)
	flash.material_override = flash_material
	parent.add_child(flash)
	flash.global_position = base + Vector3(0.0, 0.5, 0.0)
	var flash_tween := flash.create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector3.ONE * 2.4, 0.1) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash_material, "albedo_color:a", 0.0, 0.14)
	flash_tween.chain().tween_callback(flash.queue_free)

	# Afterglow: a low flat amber disc that lingers where the wave passed.
	var glow := MeshInstance3D.new()
	var glow_mesh := CylinderMesh.new()
	glow_mesh.top_radius = 1.0
	glow_mesh.bottom_radius = 1.0
	glow_mesh.height = 0.02
	glow.mesh = glow_mesh
	var glow_material := _fx_material(Color(FX_IDENTITY.r, FX_IDENTITY.g, FX_IDENTITY.b, 0.3), 0.8)
	glow.material_override = glow_material
	parent.add_child(glow)
	glow.global_position = Vector3(base.x, 0.04, base.z)
	glow.scale = Vector3(0.3, 1.0, 0.3)
	var glow_tween := glow.create_tween()
	glow_tween.tween_property(glow, "scale", Vector3(target * 0.85, 1.0, target * 0.85), SURGE_WAVE_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow_material, "albedo_color:a", 0.0, SURGE_AFTERGLOW_SECONDS) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	glow_tween.tween_callback(glow.queue_free)

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
