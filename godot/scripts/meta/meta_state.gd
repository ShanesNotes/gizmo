class_name MetaState
extends Resource

## Persistent player meta-progression. This is save data, so it serializes to a
## ConfigFile rather than a Resource file loaded from user-controlled storage.

const CURRENT_SCHEMA_VERSION: int = 2
const DEFAULT_SAVE_PATH: String = "user://saves/meta_state.cfg"
const STAT_GRADE_KEYS: Array[String] = ["dash_charges", "guard_max", "draft_rerolls"]
const STAT_GRADE_CAPS: Dictionary = {
	"dash_charges": 2,
	"guard_max": 2,
	"draft_rerolls": 2,
}
const STAT_GRADE_PRICES: Array[int] = [50, 100]

@export var schema_version: int = CURRENT_SCHEMA_VERSION
@export var scrap_banked: int = 0
@export var sparks_banked: int = 0
@export var unlocked_boon_ids: Array[StringName] = []
@export var stat_grades: Dictionary = {}

func bank_currency(scrap: int, sparks: int = 0) -> void:
	scrap_banked = maxi(0, scrap_banked + maxi(0, scrap))
	sparks_banked = maxi(0, sparks_banked + maxi(0, sparks))

func unlock_boon(boon_id: StringName) -> void:
	if boon_id == &"" or unlocked_boon_ids.has(boon_id):
		return
	unlocked_boon_ids.append(boon_id)

func is_boon_unlocked(boon_id: StringName) -> bool:
	return unlocked_boon_ids.has(boon_id)

func get_stat_grade(stat: String) -> int:
	_ensure_stat_grades()
	return int(stat_grades.get(stat, 0))

func purchase_grade(stat: String) -> bool:
	_ensure_stat_grades()
	if not STAT_GRADE_CAPS.has(stat):
		return false
	var current_rank := int(stat_grades.get(stat, 0))
	var cap := int(STAT_GRADE_CAPS[stat])
	if current_rank >= cap:
		return false
	var cost := STAT_GRADE_PRICES[current_rank]
	if scrap_banked < cost:
		return false
	scrap_banked -= cost
	stat_grades[stat] = current_rank + 1
	return true

func save_to_path(path: String = DEFAULT_SAVE_PATH) -> Error:
	schema_version = CURRENT_SCHEMA_VERSION
	var dir_error := _ensure_parent_dir(path)
	if dir_error != OK:
		push_error("MetaState could not create save directory for %s: %s" % [path, dir_error])
		return dir_error

	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", schema_version)
	config.set_value("currency", "scrap_banked", scrap_banked)
	config.set_value("currency", "sparks_banked", sparks_banked)
	config.set_value("unlocks", "boon_ids", _string_name_array_to_strings(unlocked_boon_ids))
	_ensure_stat_grades()
	for key in STAT_GRADE_KEYS:
		config.set_value("stat_grades", key, int(stat_grades.get(key, 0)))

	var save_error := config.save(path)
	if save_error != OK:
		push_error("MetaState could not save %s: %s" % [path, save_error])
	return save_error

static func load_from_path(path: String = DEFAULT_SAVE_PATH) -> Resource:
	var state = load("res://scripts/meta/meta_state.gd").new()
	var config := ConfigFile.new()
	var load_error := config.load(path)
	if load_error == ERR_FILE_NOT_FOUND:
		return state
	if load_error != OK:
		push_error("MetaState could not load %s: %s" % [path, load_error])
		return state

	var loaded_version := int(config.get_value("meta", "schema_version", 0))
	if loaded_version > CURRENT_SCHEMA_VERSION:
		push_warning("MetaState save version %d is newer than supported version %d." % [loaded_version, CURRENT_SCHEMA_VERSION])

	state.schema_version = CURRENT_SCHEMA_VERSION
	state.scrap_banked = maxi(0, int(config.get_value("currency", "scrap_banked", 0)))
	state.sparks_banked = maxi(0, int(config.get_value("currency", "sparks_banked", 0)))
	state.unlocked_boon_ids = _variant_to_string_name_array(config.get_value("unlocks", "boon_ids", []))
	state._ensure_stat_grades()
	for key in STAT_GRADE_KEYS:
		state.stat_grades[key] = maxi(0, int(config.get_value("stat_grades", key, 0)))
	return state

static func _ensure_parent_dir(path: String) -> Error:
	var base_dir := path.get_base_dir()
	if base_dir == "" or base_dir == ".":
		return OK
	var absolute_dir := base_dir
	if not absolute_dir.is_absolute_path():
		absolute_dir = ProjectSettings.globalize_path(base_dir)
	return DirAccess.make_dir_recursive_absolute(absolute_dir)

static func _string_name_array_to_strings(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result

static func _variant_to_string_name_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	match typeof(value):
		TYPE_PACKED_STRING_ARRAY:
			for item in value:
				_append_unique_string_name(result, StringName(item))
		TYPE_ARRAY:
			for item in value:
				_append_unique_string_name(result, StringName(str(item)))
		TYPE_STRING, TYPE_STRING_NAME:
			for item in str(value).split(",", false):
				_append_unique_string_name(result, StringName(item.strip_edges()))
		_:
			return result
	return result

static func _append_unique_string_name(values: Array[StringName], value: StringName) -> void:
	if value == &"" or values.has(value):
		return
	values.append(value)

func _ensure_stat_grades() -> void:
	for key in STAT_GRADE_KEYS:
		if not stat_grades.has(key):
			stat_grades[key] = 0
		else:
			stat_grades[key] = maxi(0, int(stat_grades[key]))
