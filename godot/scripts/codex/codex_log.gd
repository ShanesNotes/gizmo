extends Node

signal entry_unlocked(entry_id: StringName)

const CodexEntries := preload("res://scripts/codex/codex_entries.gd")

const CURRENT_SCHEMA_VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://saves/codex_log.cfg"

@export var save_path: String = DEFAULT_SAVE_PATH

var _unlocked_by_id: Dictionary = {}

func _ready() -> void:
	_load()

func notify_event(event: StringName) -> Array[StringName]:
	var newly_unlocked: Array[StringName] = []
	if event == &"":
		return newly_unlocked

	for raw_entry_id in CodexEntries.TABLE.keys():
		var entry_id := StringName(raw_entry_id)
		var entry := CodexEntries.TABLE[entry_id] as Dictionary
		if StringName(entry.get("unlock_event", &"")) != event:
			continue
		if _unlocked_by_id.has(entry_id):
			continue
		_unlocked_by_id[entry_id] = true
		newly_unlocked.append(entry_id)

	if newly_unlocked.is_empty():
		return newly_unlocked

	var save_error := _save()
	if save_error != OK:
		push_error("CodexLog could not save unlocks to %s: %s" % [save_path, save_error])
	for entry_id in newly_unlocked:
		entry_unlocked.emit(entry_id)
	return newly_unlocked

func is_unlocked(entry_id: Variant) -> bool:
	return _unlocked_by_id.has(StringName(entry_id))

func unlocked_entries() -> Array[StringName]:
	var result: Array[StringName] = []
	for raw_entry_id in CodexEntries.TABLE.keys():
		var entry_id := StringName(raw_entry_id)
		if _unlocked_by_id.has(entry_id):
			result.append(entry_id)
	return result

func _load() -> void:
	_unlocked_by_id.clear()
	var config := ConfigFile.new()
	var load_error := config.load(save_path)
	if load_error == ERR_FILE_NOT_FOUND:
		return
	if load_error != OK:
		push_error("CodexLog could not load %s: %s" % [save_path, load_error])
		return

	var loaded_version := int(config.get_value("codex", "schema_version", 0))
	if loaded_version > CURRENT_SCHEMA_VERSION:
		push_warning("CodexLog save version %d is newer than supported version %d." % [loaded_version, CURRENT_SCHEMA_VERSION])

	var loaded_ids := _variant_to_string_name_array(config.get_value("unlocks", "entry_ids", []))
	for entry_id in loaded_ids:
		if CodexEntries.TABLE.has(entry_id):
			_unlocked_by_id[entry_id] = true

func _save() -> Error:
	var dir_error := _ensure_parent_dir(save_path)
	if dir_error != OK:
		return dir_error

	var config := ConfigFile.new()
	config.set_value("codex", "schema_version", CURRENT_SCHEMA_VERSION)
	config.set_value("unlocks", "entry_ids", _string_name_array_to_strings(unlocked_entries()))
	return config.save(save_path)

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
