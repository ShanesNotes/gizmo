class_name EnemyArchetypes
extends RefCounted

const ARCHETYPE_CHAFF := "chaff"
const ARCHETYPE_BRUISER := "bruiser"
const ARCHETYPE_ELITE := "elite"

const STATS := {
	ARCHETYPE_CHAFF: {
		"archetype": ARCHETYPE_CHAFF,
		"max_hp": 30.0,
		"damage": 1,
		"move_speed": 2.1,
		"contact_radius": 0.9,
		"attack_release_radius": 1.125,
		"attack_windup": 0.65,
		"attack_recovery": 1.45,
		"budget_cost": 1.0,
		"visual_scale": 1.0,
	},
	ARCHETYPE_BRUISER: {
		"archetype": ARCHETYPE_BRUISER,
		"max_hp": 140.0,
		"damage": 1,
		"move_speed": 1.65,
		"contact_radius": 1.35,
		"attack_release_radius": 1.6875,
		"attack_windup": 0.85,
		"attack_recovery": 1.85,
		"budget_cost": 2.4,
		"visual_scale": 1.35,
	},
	ARCHETYPE_ELITE: {
		"archetype": ARCHETYPE_ELITE,
		"max_hp": 640.0,
		"damage": 2,
		"move_speed": 1.25,
		"contact_radius": 1.75,
		"attack_release_radius": 2.1875,
		"attack_windup": 1.05,
		"attack_recovery": 2.35,
		"budget_cost": 9.0,
		"visual_scale": 1.7,
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
