class_name RegionTable
extends RefCounted

## Region identity vocabulary for run generation. Derived from the world
## grammar in docs/reference/shattered-meridian-region-graph.json
## (macro_topology routes + regions.*.name/landmark) — that graph is the naming
## source of truth; no invented place names. Derived data; do not edit as source.

const REGIONS := {
	"HEARTH": {"name": "Hearthwake Basin", "landmark": "The Heart Spire"},
	"BRASS": {"name": "Brasswind Highlands", "landmark": "The Chronarch Keep"},
	"VERDANT": {"name": "Verdant Archive", "landmark": "The Memory Tree"},
	"PRISM": {"name": "Prism Reach", "landmark": "The Nebula Prism"},
	"TEMPEST": {"name": "Tempest Verge", "landmark": "The Storm Engine"},
	"NULL": {"name": "The Null Crown", "landmark": "The Last Ember"},
	"RUST": {"name": "Rustchain Expanse", "landmark": "The Titan Yard"},
	"ASH": {"name": "Ashfall Foundries", "landmark": "The Ember Crucible"},
}

## macro_topology.upper_route / lower_route. The mystery route (RUNE/OBS) is
## optional side content in the graph and stays out of the main run spine.
const ROUTE_UPPER: Array[String] = ["HEARTH", "BRASS", "VERDANT", "PRISM", "TEMPEST", "NULL"]
const ROUTE_LOWER: Array[String] = ["HEARTH", "RUST", "ASH", "TEMPEST", "NULL"]


## Reads rng.state instead of rolling so the route choice never consumes from
## the run stream: fixture picks, director budgets, and spawn placement are
## seed-pinned by tests and tuning, and must not shift under region assignment.
static func pick_route(rng: RandomNumberGenerator) -> Array[String]:
	if rng == null:
		return ROUTE_UPPER
	return ROUTE_UPPER if (rng.state & 1) == 0 else ROUTE_LOWER


## Maps run progress onto the route so region order is monotonic: room 0 is
## always HEARTH (departure) and the final room always reaches NULL (finale).
static func region_for_index(route: Array[String], index: int, room_count: int) -> String:
	if route.is_empty():
		return ""
	if room_count <= 1:
		return route[route.size() - 1]
	var progress := float(clampi(index, 0, room_count - 1)) / float(room_count - 1)
	return route[int(roundf(progress * float(route.size() - 1)))]


static func display_name_for(region_id: String, use_landmark: bool) -> String:
	var entry: Dictionary = REGIONS.get(region_id, {})
	if entry.is_empty():
		return ""
	return String(entry["landmark"]) if use_landmark else String(entry["name"])
