class_name RunBonuses
extends RefCounted

const MetaState := preload("res://scripts/meta/meta_state.gd")

static func from_meta(meta: MetaState) -> Dictionary:
	var grades := meta.stat_grades
	return {
		"extra_dash_charges": int(grades.get("dash_charges", 0)),
		"extra_guard": int(grades.get("guard_max", 0)),
		"draft_rerolls": int(grades.get("draft_rerolls", 0)),
	}