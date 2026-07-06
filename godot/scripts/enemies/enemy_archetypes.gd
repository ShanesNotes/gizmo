class_name EnemyArchetypes
extends RefCounted

const ARCHETYPE_CHAFF := "chaff"
const ARCHETYPE_BRUISER := "bruiser"

const STATS := {
	ARCHETYPE_CHAFF: {
		"archetype": ARCHETYPE_CHAFF,
		"max_hp": 1.0,
		"damage": 1,
		"move_speed": 2.1,
		"contact_radius": 1.0,
		"attack_release_radius": 1.25,
		"attack_windup": 0.35,
		"attack_recovery": 0.65,
		"budget_cost": 1.1,
		"visual_scale": 1.0,
	},
	ARCHETYPE_BRUISER: {
		"archetype": ARCHETYPE_BRUISER,
		"max_hp": 4.0,
		"damage": 1,
		"move_speed": 1.65,
		"contact_radius": 1.55,
		"attack_release_radius": 1.9375,
		"attack_windup": 0.55,
		"attack_recovery": 0.9,
		"budget_cost": 3.4,
		"visual_scale": 1.35,
	},
}

static func has_archetype(archetype: String) -> bool:
	return STATS.has(archetype)

static func normalize_archetype(archetype: String) -> String:
	if has_archetype(archetype):
		return archetype
	push_warning(
		"EnemyArchetypes: unknown archetype '%s', falling back to '%s'."
		% [archetype, ARCHETYPE_CHAFF]
	)
	return ARCHETYPE_CHAFF

static func stats_for(archetype: String) -> Dictionary:
	var key := normalize_archetype(archetype)
	var stats: Dictionary = STATS[key]
	return stats.duplicate(true)
