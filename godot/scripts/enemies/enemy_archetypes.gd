class_name EnemyArchetypes
extends RefCounted

const ARCHETYPE_CHAFF := "chaff"
const ARCHETYPE_BRUISER := "bruiser"
const ARCHETYPE_ELITE := "elite"

const AFFIX_NONE: StringName = &""
const AFFIX_SHIELDED: StringName = &"shielded"
const AFFIX_FRENZIED: StringName = &"frenzied"
const AFFIX_WARDED: StringName = &"warded"
const ELITE_AFFIXES: Array[StringName] = [
	AFFIX_SHIELDED,
	AFFIX_FRENZIED,
	AFFIX_WARDED,
]

const STATS := {
	ARCHETYPE_CHAFF: {
		"archetype": ARCHETYPE_CHAFF,
		"max_hp": 30.0,
		"damage": 20,
		"move_speed": 2.1,
		"contact_radius": 0.9,
		"attack_release_radius": 1.125,
		"attack_windup": 0.65,
		"attack_recovery": 1.45,
		"movement_style": "skirmisher",
		"budget_cost": 1.0,
		"visual_scale": 1.0,
	},
	ARCHETYPE_BRUISER: {
		"archetype": ARCHETYPE_BRUISER,
		"max_hp": 140.0,
		"damage": 30,
		"move_speed": 1.65,
		"contact_radius": 1.35,
		"attack_release_radius": 1.6875,
		"attack_windup": 0.85,
		"attack_recovery": 1.85,
		"movement_style": "juggernaut",
		"budget_cost": 2.4,
		"visual_scale": 1.35,
	},
	ARCHETYPE_ELITE: {
		"archetype": ARCHETYPE_ELITE,
		"max_hp": 640.0,
		"damage": 45,
		"move_speed": 1.25,
		"contact_radius": 1.75,
		"attack_release_radius": 2.1875,
		"attack_windup": 1.05,
		"attack_recovery": 2.35,
		"movement_style": "stalker",
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
	var result := stats.duplicate(true)
	result["affix"] = ""
	return result

static func normalize_affix(affix_id: StringName) -> StringName:
	if ELITE_AFFIXES.has(affix_id):
		return affix_id
	return AFFIX_NONE
