class_name RoomDoor
extends Area3D

signal exit_requested(connection: RoomConnection)

enum State { SEALED, OPEN }

const TELEGRAPH_LABEL_NAME := &"RewardTelegraph"
const UNLOCK_SHINE_NAME := &"UnlockShine"
const REWARD_GLYPH_NAME := &"RewardGlyph"
const BECKON_GLOW_NAME := &"BeckonGlow"
# Door-lure anatomy (playtest 2): big glyph at squint distance, warm beckon.
const GLYPH_HEIGHT := 2.3
const GLYPH_SCALE := 1.35
const BECKON_BASE_ENERGY := 1.3
const BECKON_PEAK_ENERGY := 2.1
const BECKON_PULSE_SECONDS := 1.4
# Warm gold flash on unlock (tokens.metal.gold_lit #e0c17a — room-clear reward beat).
const UNLOCK_SHINE_COLOR := Color(0.878, 0.757, 0.478)
const UNLOCK_SHINE_PEAK_ENERGY := 2.2
const UNLOCK_SHINE_SECONDS := 0.45

@export var player_group: StringName = &"player"

var state: State = State.SEALED
var bound_connection: RoomConnection = null
var reward_type: RoomNode.RewardType = RoomNode.RewardType.BOON
var door_name: String = ""

var _exit_requested: bool = false
var _overlap_check_generation: int = 0
var _telegraph_label: Label3D = null
var _unlock_shine: OmniLight3D = null
var _shine_tween: Tween = null
var _reward_glyph: Node3D = null
var _beckon_glow: OmniLight3D = null
var _beckon_tween: Tween = null
var _glyph_tween: Tween = null

func _init() -> void:
	monitoring = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func open_for(connection: RoomConnection, next_reward_type: RoomNode.RewardType) -> void:
	if connection == null:
		push_error("RoomDoor: open_for requires a RoomConnection")
		seal()
		return

	bound_connection = connection
	reward_type = next_reward_type
	door_name = connection.door_name
	state = State.OPEN
	_exit_requested = false
	monitoring = true
	_notify_audio_event(&"door_open")
	_show_reward_telegraph(next_reward_type)
	_show_reward_glyph(next_reward_type)
	_light_beckon_glow(next_reward_type)
	_play_unlock_shine()
	_overlap_check_generation += 1
	call_deferred("_check_for_already_overlapping_player", _overlap_check_generation)

func seal() -> void:
	state = State.SEALED
	monitoring = false
	bound_connection = null
	reward_type = RoomNode.RewardType.BOON
	door_name = ""
	_exit_requested = false
	_hide_reward_telegraph()
	_hide_reward_glyph()
	_snuff_beckon_glow()
	_snuff_unlock_shine()
	_overlap_check_generation += 1

func telegraph_data() -> Dictionary:
	return {
		&"door_name": door_name,
		&"reward_type": reward_type,
	}

func _on_body_entered(body: Node3D) -> void:
	_request_exit_from_body(body)

func _check_for_already_overlapping_player(generation: int) -> void:
	if not is_inside_tree():
		return
	await get_tree().physics_frame
	if generation != _overlap_check_generation:
		return
	if state != State.OPEN or _exit_requested or bound_connection == null:
		return
	for body in get_overlapping_bodies():
		if _request_exit_from_body(body):
			return

func _request_exit_from_body(body: Node3D) -> bool:
	if state != State.OPEN:
		return false
	if _exit_requested:
		return false
	if bound_connection == null:
		return false
	if not _is_player_body(body):
		return false

	_exit_requested = true
	exit_requested.emit(bound_connection)
	return true

func _is_player_body(body: Node3D) -> bool:
	if body == null:
		return false
	return body is CharacterBody3D and body.is_in_group(player_group)

func _ensure_telegraph_label() -> Label3D:
	if _telegraph_label != null and is_instance_valid(_telegraph_label):
		return _telegraph_label

	_telegraph_label = Label3D.new()
	_telegraph_label.name = TELEGRAPH_LABEL_NAME
	_telegraph_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Subtitle under the glyph: the mesh is the read, the canon term confirms it.
	_telegraph_label.font_size = 40
	_telegraph_label.outline_size = 10
	_telegraph_label.outline_modulate = Color(0.11, 0.07, 0.03, 1.0)
	_telegraph_label.no_depth_test = true
	_telegraph_label.position = Vector3(0.0, 1.5, 0.0)
	_telegraph_label.visible = false
	add_child(_telegraph_label)
	return _telegraph_label

func _reward_telegraph_text(next_reward_type: RoomNode.RewardType) -> String:
	match next_reward_type:
		RoomNode.RewardType.BOON:
			return "BOON"
		RoomNode.RewardType.SCRAP:
			return "SCRAP"
		RoomNode.RewardType.SPARKS:
			return "SPARKS"
		RoomNode.RewardType.HAMMER:
			return "INGENUITY"
		RoomNode.RewardType.HEAL:
			return "MENDING"
		RoomNode.RewardType.SHOP:
			return "TRADE"
		RoomNode.RewardType.REST:
			return "SANCTUARY"
		RoomNode.RewardType.REWARD:
			return "RELIQUARY"
		_:
			return "UNMARKED"

func _reward_telegraph_color(next_reward_type: RoomNode.RewardType) -> Color:
	match next_reward_type:
		RoomNode.RewardType.BOON:
			return Color(1.0, 0.843, 0.0)
		RoomNode.RewardType.SCRAP:
			return Color(0.804, 0.498, 0.196)
		RoomNode.RewardType.SPARKS:
			return Color(0.259, 0.522, 0.957)
		RoomNode.RewardType.HAMMER:
			return Color(1.0, 0.549, 0.0)
		RoomNode.RewardType.HEAL:
			return Color(0.298, 0.686, 0.314)
		RoomNode.RewardType.SHOP:
			return Color(0.612, 0.153, 0.690)
		RoomNode.RewardType.REST:
			return Color(0.42, 0.82, 0.72)
		RoomNode.RewardType.REWARD:
			return Color(0.78, 0.86, 0.92)
		_:
			return Color.WHITE

func _show_reward_telegraph(next_reward_type: RoomNode.RewardType) -> void:
	var label := _ensure_telegraph_label()
	label.text = _reward_telegraph_text(next_reward_type)
	label.modulate = _reward_telegraph_color(next_reward_type)
	label.visible = true

func _hide_reward_telegraph() -> void:
	if _telegraph_label != null and is_instance_valid(_telegraph_label):
		_telegraph_label.visible = false

func _ensure_unlock_shine() -> OmniLight3D:
	if _unlock_shine != null and is_instance_valid(_unlock_shine):
		return _unlock_shine

	_unlock_shine = OmniLight3D.new()
	_unlock_shine.name = UNLOCK_SHINE_NAME
	_unlock_shine.light_color = UNLOCK_SHINE_COLOR
	_unlock_shine.omni_range = 4.0
	_unlock_shine.light_energy = 0.0
	_unlock_shine.position = Vector3(0.0, 1.2, 0.0)
	add_child(_unlock_shine)
	return _unlock_shine

## Cosmetic room-clear beat: a brief warm flash on the door telegraph when it
## unlocks. Purely visual — no gameplay state.
func _play_unlock_shine() -> void:
	var shine := _ensure_unlock_shine()
	if _shine_tween != null and _shine_tween.is_valid():
		_shine_tween.kill()
	shine.light_energy = UNLOCK_SHINE_PEAK_ENERGY
	if not is_inside_tree():
		return
	_shine_tween = create_tween()
	_shine_tween.tween_property(shine, "light_energy", 0.0, UNLOCK_SHINE_SECONDS) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _snuff_unlock_shine() -> void:
	if _shine_tween != null and _shine_tween.is_valid():
		_shine_tween.kill()
	if _unlock_shine != null and is_instance_valid(_unlock_shine):
		_unlock_shine.light_energy = 0.0

## The lure: a large primitive-mesh glyph (distinct silhouette per reward type)
## floating over the door, slowly turning, plus a warm pulsing beckon light.
## Readable at gameplay distance where the old 32px label was not.
func _show_reward_glyph(next_reward_type: RoomNode.RewardType) -> void:
	if _reward_glyph == null or not is_instance_valid(_reward_glyph):
		_reward_glyph = Node3D.new()
		_reward_glyph.name = REWARD_GLYPH_NAME
		add_child(_reward_glyph)
	for child in _reward_glyph.get_children():
		_reward_glyph.remove_child(child)
		child.queue_free()
	_reward_glyph.position = Vector3(0.0, GLYPH_HEIGHT, 0.0)
	_reward_glyph.scale = Vector3.ONE * GLYPH_SCALE
	_reward_glyph.rotation = Vector3.ZERO
	_build_glyph_meshes(_reward_glyph, next_reward_type)
	_reward_glyph.visible = true
	_spin_glyph()

func _hide_reward_glyph() -> void:
	if _glyph_tween != null and _glyph_tween.is_valid():
		_glyph_tween.kill()
	if _reward_glyph != null and is_instance_valid(_reward_glyph):
		_reward_glyph.visible = false

func _spin_glyph() -> void:
	if not is_inside_tree() or _reward_glyph == null:
		return
	if _glyph_tween != null and _glyph_tween.is_valid():
		_glyph_tween.kill()
	_glyph_tween = create_tween().set_loops()
	_glyph_tween.tween_property(_reward_glyph, "rotation:y", TAU, 6.0).from(0.0)

func _light_beckon_glow(next_reward_type: RoomNode.RewardType) -> void:
	if _beckon_glow == null or not is_instance_valid(_beckon_glow):
		_beckon_glow = OmniLight3D.new()
		_beckon_glow.name = BECKON_GLOW_NAME
		_beckon_glow.position = Vector3(0.0, GLYPH_HEIGHT - 0.4, 0.0)
		_beckon_glow.omni_range = 7.0
		add_child(_beckon_glow)
	# Warm-shifted reward color so every lure beckons like a hearth.
	var reward_color := _reward_telegraph_color(next_reward_type)
	_beckon_glow.light_color = reward_color.lerp(Color(1.0, 0.78, 0.45), 0.55)
	_beckon_glow.light_energy = BECKON_BASE_ENERGY
	if not is_inside_tree():
		return
	if _beckon_tween != null and _beckon_tween.is_valid():
		_beckon_tween.kill()
	_beckon_tween = create_tween().set_loops()
	_beckon_tween.tween_property(_beckon_glow, "light_energy", BECKON_PEAK_ENERGY, BECKON_PULSE_SECONDS) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_beckon_tween.tween_property(_beckon_glow, "light_energy", BECKON_BASE_ENERGY, BECKON_PULSE_SECONDS) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _snuff_beckon_glow() -> void:
	if _beckon_tween != null and _beckon_tween.is_valid():
		_beckon_tween.kill()
	if _beckon_glow != null and is_instance_valid(_beckon_glow):
		_beckon_glow.light_energy = 0.0

## Canon emblem language (design-system EMBLEMS.md): rewards with a canonical
## sign use it; salvage/spark/ingenuity keep primitive-mesh glyphs until the
## emblem library grows those motifs. thorn stays reserved for elite room marks.
const REWARD_EMBLEM_PATHS := {
	RoomNode.RewardType.BOON: "res://assets/emblems/moon.svg",
	RoomNode.RewardType.REWARD: "res://assets/emblems/sun.svg",
	RoomNode.RewardType.HEAL: "res://assets/emblems/thread.svg",
	RoomNode.RewardType.REST: "res://assets/emblems/lamp.svg",
	RoomNode.RewardType.SHOP: "res://assets/emblems/seal-cracked.svg",
}
const EMBLEM_WORLD_HEIGHT := 1.7

func _emblem_sprite_for(next_reward_type: RoomNode.RewardType) -> Sprite3D:
	var path := String(REWARD_EMBLEM_PATHS.get(next_reward_type, ""))
	if path == "" or not ResourceLoader.exists(path, "Texture2D"):
		return null
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	var sprite := Sprite3D.new()
	sprite.name = "Emblem"
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.no_depth_test = true
	sprite.pixel_size = EMBLEM_WORLD_HEIGHT / maxf(float(texture.get_height()), 1.0)
	return sprite

func _glyph_material(next_reward_type: RoomNode.RewardType) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := _reward_telegraph_color(next_reward_type)
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.6
	material.roughness = 0.4
	return material

func _add_glyph_mesh(glyph: Node3D, part_name: String, mesh: Mesh, material: Material, mesh_transform: Transform3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.material_override = material
	instance.transform = mesh_transform
	glyph.add_child(instance)

func _build_glyph_meshes(glyph: Node3D, next_reward_type: RoomNode.RewardType) -> void:
	var emblem := _emblem_sprite_for(next_reward_type)
	if emblem != null:
		glyph.add_child(emblem)
		return
	var material := _glyph_material(next_reward_type)
	match next_reward_type:
		RoomNode.RewardType.BOON:
			var orb := SphereMesh.new()
			orb.radius = 0.32
			orb.height = 0.64
			var halo := TorusMesh.new()
			halo.inner_radius = 0.42
			halo.outer_radius = 0.55
			_add_glyph_mesh(glyph, "BoonOrb", orb, material, Transform3D.IDENTITY)
			_add_glyph_mesh(glyph, "BoonHalo", halo, material, Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0.0, 0.0)), Vector3.ZERO))
		RoomNode.RewardType.SCRAP:
			var block_a := BoxMesh.new()
			block_a.size = Vector3(0.62, 0.34, 0.62)
			var block_b := BoxMesh.new()
			block_b.size = Vector3(0.42, 0.3, 0.42)
			_add_glyph_mesh(glyph, "ScrapBase", block_a, material, Transform3D(Basis.from_euler(Vector3(0.0, 0.35, 0.0)), Vector3(0.0, -0.18, 0.0)))
			_add_glyph_mesh(glyph, "ScrapTop", block_b, material, Transform3D(Basis.from_euler(Vector3(0.0, -0.4, 0.0)), Vector3(0.08, 0.16, 0.0)))
		RoomNode.RewardType.SPARKS:
			var bolt := PrismMesh.new()
			bolt.size = Vector3(0.5, 0.8, 0.25)
			var bolt_tail := PrismMesh.new()
			bolt_tail.size = Vector3(0.4, 0.6, 0.2)
			_add_glyph_mesh(glyph, "SparkBolt", bolt, material, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.18, 0.0)))
			_add_glyph_mesh(glyph, "SparkTail", bolt_tail, material, Transform3D(Basis.from_euler(Vector3(0.0, 0.0, PI)), Vector3(0.12, -0.3, 0.0)))
		RoomNode.RewardType.HAMMER:
			var head := BoxMesh.new()
			head.size = Vector3(0.75, 0.4, 0.4)
			var handle := CylinderMesh.new()
			handle.top_radius = 0.09
			handle.bottom_radius = 0.09
			handle.height = 0.85
			_add_glyph_mesh(glyph, "HammerHead", head, material, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.3, 0.0)))
			_add_glyph_mesh(glyph, "HammerHandle", handle, material, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.2, 0.0)))
		RoomNode.RewardType.HEAL:
			var upright := BoxMesh.new()
			upright.size = Vector3(0.3, 0.95, 0.3)
			var crossbar := BoxMesh.new()
			crossbar.size = Vector3(0.95, 0.3, 0.3)
			_add_glyph_mesh(glyph, "MendUpright", upright, material, Transform3D.IDENTITY)
			_add_glyph_mesh(glyph, "MendCross", crossbar, material, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.12, 0.0)))
		RoomNode.RewardType.SHOP:
			var coin := CylinderMesh.new()
			coin.top_radius = 0.45
			coin.bottom_radius = 0.45
			coin.height = 0.12
			var coin_b := CylinderMesh.new()
			coin_b.top_radius = 0.34
			coin_b.bottom_radius = 0.34
			coin_b.height = 0.12
			_add_glyph_mesh(glyph, "TradeCoin", coin, material, Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0.0, 0.0)), Vector3(-0.12, 0.0, 0.0)))
			_add_glyph_mesh(glyph, "TradeCoinB", coin_b, material, Transform3D(Basis.from_euler(Vector3(PI * 0.5, 0.0, 0.2)), Vector3(0.28, 0.14, -0.05)))
		RoomNode.RewardType.REST:
			var hearth := TorusMesh.new()
			hearth.inner_radius = 0.3
			hearth.outer_radius = 0.5
			var flame := SphereMesh.new()
			flame.radius = 0.22
			flame.height = 0.6
			_add_glyph_mesh(glyph, "HearthRing", hearth, material, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.2, 0.0)))
			_add_glyph_mesh(glyph, "HearthFlame", flame, material, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.15, 0.0)))
		RoomNode.RewardType.REWARD:
			var chest := BoxMesh.new()
			chest.size = Vector3(0.8, 0.45, 0.55)
			var lid := BoxMesh.new()
			lid.size = Vector3(0.8, 0.22, 0.55)
			_add_glyph_mesh(glyph, "ReliquaryChest", chest, material, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.15, 0.0)))
			_add_glyph_mesh(glyph, "ReliquaryLid", lid, material, Transform3D(Basis.from_euler(Vector3(-0.5, 0.0, 0.0)), Vector3(0.0, 0.18, -0.2)))
		_:
			var unknown := SphereMesh.new()
			unknown.radius = 0.35
			unknown.height = 0.7
			_add_glyph_mesh(glyph, "UnmarkedOrb", unknown, material, Transform3D.IDENTITY)

func _notify_audio_event(event: StringName) -> void:
	if not is_inside_tree():
		return
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method(&"notify_event"):
		director.call(&"notify_event", event)
