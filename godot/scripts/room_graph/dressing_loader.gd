class_name DressingLoader
extends RefCounted

## Data-driven room dressing per the level lab's grammar
## (docs/reference/dressing-grammar.json; res:// copy is the derived runtime
## artifact — derived from level canon; do not edit as source).
##
## The loader plans placements in normalized floor space (nx = x/(width/2),
## nz = z/(depth/2), band radius r = max(|nx|,|nz|)) and resolves asset ids
## against the asset lab's install paths, falling back to greybox placeholders
## per height class until real world-kit scenes land. Placements never enter
## the door aprons; tall pieces stay off the camera-near (+z) arc.

const GRAMMAR_PATH := "res://resources/dressing_grammar.json"
const ASSET_PATH_CANDIDATES := [
	"res://assets/world_kit/%s/%s.tscn",
	"res://assets/world_kit/%s.tscn",
	"res://assets/props/%s/%s.tscn",
]
const PLACEHOLDER_COLORS := {
	"low": Color(0.4, 0.34, 0.26, 1.0),
	"mid": Color(0.5, 0.4, 0.26, 1.0),
	"tall": Color(0.62, 0.46, 0.26, 1.0),
}

static func load_grammar(path: String = GRAMMAR_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

## Plans a room's dressing deterministically for a seed. Doors are normalized
## positions ([{"nx","nz"}]) used to keep aprons clear. Returns placement dicts:
## {cluster_archetype, asset, nx, nz, height_class, yaw}.
static func plan_room(
	grammar: Dictionary,
	room_archetype: String,
	region_id: String,
	rng_seed: int,
	doors: Array = [],
) -> Array:
	var placements: Array = []
	var spec: Dictionary = grammar.get("room_archetypes", {}).get(room_archetype, {})
	if spec.is_empty():
		return placements
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var bands: Dictionary = grammar.get("bands", {})
	var region: Dictionary = grammar.get("regions", {}).get(region_id, {})

	if String(spec.get("landmark", "")) == "required":
		var landmark_asset := String(spec.get("landmark_must_be",
			spec.get("landmark_should_be", region.get("landmark_pref", "spire_01"))))
		placements.append(_place(rng, grammar, "landmark_anchor", landmark_asset, "tall", doors, bands))

	var punct_range: Array = spec.get("vertical_punctuation", [0, 0])
	var punct_members: Array = grammar.get("cluster_archetypes", {}).get("vertical_punctuation", {}).get("members", ["gear_ring_01"])
	for _i in range(rng.randi_range(int(punct_range[0]), int(punct_range[1]))):
		placements.append(_place(rng, grammar, "vertical_punctuation", String(punct_members[rng.randi() % punct_members.size()]), "mid", doors, bands))

	var debris_range: Array = spec.get("debris_scatter", [0, 0])
	var debris_members: Array = grammar.get("cluster_archetypes", {}).get("debris_scatter", {}).get("members", ["debris_cluster_01"])
	for _i in range(rng.randi_range(int(debris_range[0]), int(debris_range[1]))):
		placements.append(_place(rng, grammar, "debris_scatter", String(debris_members[rng.randi() % debris_members.size()]), "low", doors, bands))

	return placements

## Builds the GrammarDressing layer under room_root. Reads the floor and door
## layout from the scene itself; safe no-op when the grammar or floor is absent.
static func apply_to_room(room_root: Node3D, room_archetype: String, region_id: String, rng_seed: int) -> Node3D:
	var grammar := load_grammar()
	if grammar.is_empty() or room_root == null:
		return null
	var floor_node := room_root.find_child("Floor", true, false) as CSGBox3D
	if floor_node == null:
		return null
	var half := Vector2(floor_node.size.x * 0.5, floor_node.size.z * 0.5)
	if half.x <= 0.0 or half.y <= 0.0:
		return null

	var doors: Array = []
	for door in room_root.find_children("RoomExit*", "Area3D", true, false):
		doors.append({"nx": door.position.x / half.x, "nz": door.position.z / half.y})

	var container := Node3D.new()
	container.name = "GrammarDressing"
	room_root.add_child(container)
	for placement in plan_room(grammar, room_archetype, region_id, rng_seed, doors):
		var piece := _resolve_asset(String(placement["asset"]), String(placement["height_class"]))
		piece.set_meta("cluster_archetype", String(placement["cluster_archetype"]))
		piece.set_meta("asset_id", String(placement["asset"]))
		piece.set_meta("height_class", String(placement["height_class"]))
		piece.position = Vector3(float(placement["nx"]) * half.x, 0.0, float(placement["nz"]) * half.y)
		piece.rotation.y = float(placement["yaw"])
		container.add_child(piece)
	return container

static func _place(
	rng: RandomNumberGenerator,
	grammar: Dictionary,
	cluster_archetype: String,
	asset: String,
	height_class: String,
	doors: Array,
	bands: Dictionary,
) -> Dictionary:
	var allowed: Array = grammar.get("cluster_archetypes", {}).get(cluster_archetype, {}).get("allowed_bands", ["perimeter_band"])
	var r_min := 0.8
	var r_max := 0.97
	if allowed.has("mid_band") and not allowed.has("perimeter_band"):
		r_min = float(bands.get("mid_band", {}).get("r_min", 0.55))
		r_max = float(bands.get("mid_band", {}).get("r_max", 0.8))
	elif allowed.has("mid_band"):
		r_min = float(bands.get("mid_band", {}).get("r_min", 0.55))
	var apron := float(bands.get("door_apron_radius", 0.22))
	var camera_near_nz := float(bands.get("camera_near_arc_nz", 0.55))

	var nx := 0.0
	var nz := 0.0
	for _attempt in range(24):
		var r := rng.randf_range(r_min, minf(r_max, 0.97))
		var side := rng.randi() % 4
		var along := rng.randf_range(-r, r)
		match side:
			0:
				nx = along
				nz = -r
			1:
				nx = along
				nz = r
			2:
				nx = -r
				nz = along
			_:
				nx = r
				nz = along
		if height_class == "tall" and nz > camera_near_nz:
			continue
		if _clear_of_doors(nx, nz, doors, apron):
			break
	return {
		"cluster_archetype": cluster_archetype,
		"asset": asset,
		"nx": nx,
		"nz": nz,
		"height_class": height_class,
		"yaw": rng.randf_range(0.0, TAU),
	}

static func _clear_of_doors(nx: float, nz: float, doors: Array, apron: float) -> bool:
	for door in doors:
		if maxf(absf(nx - float(door.get("nx", 0.0))), absf(nz - float(door.get("nz", 0.0)))) <= apron:
			return false
	return true

## Asset-lab seam: prefer installed world-kit scenes; greybox placeholder until
## they land so the dressing layer works tonight and upgrades itself later.
static func _resolve_asset(asset_id: String, height_class: String) -> Node3D:
	for pattern in ASSET_PATH_CANDIDATES:
		var path: String = pattern % ([asset_id, asset_id] if pattern.count("%s") == 2 else [asset_id])
		if ResourceLoader.exists(path, "PackedScene"):
			var scene := load(path) as PackedScene
			if scene != null:
				var instance := scene.instantiate()
				if instance is Node3D:
					return instance as Node3D
				instance.free()
	return _placeholder_for(height_class)

static func _placeholder_for(height_class: String) -> Node3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = PLACEHOLDER_COLORS.get(height_class, PLACEHOLDER_COLORS["mid"])
	material.roughness = 0.88
	var piece := CSGBox3D.new()
	piece.material = material
	match height_class:
		"low":
			piece.size = Vector3(1.5, 0.45, 1.2)
			piece.position.y = 0.22
			piece.use_collision = false
		"tall":
			piece.size = Vector3(1.7, 4.2, 1.7)
			piece.position.y = 2.1
			piece.use_collision = true
		_:
			piece.size = Vector3(1.3, 1.6, 1.3)
			piece.position.y = 0.8
			piece.use_collision = true
	var wrapper := Node3D.new()
	wrapper.add_child(piece)
	return wrapper
