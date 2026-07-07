extends SceneTree

# Headless tests for AudioDirector voice-line manifest/file drift.
# Run with:
#   godot --headless --user-data-dir /tmp/godot-night-lore --path godot --script res://tests/run_voice_manifest_tests.gd

const AudioDirectorScript := preload("res://scripts/audio/audio_director.gd")
const OpeningSequenceScript := preload("res://scripts/ui/opening_sequence.gd")
const VOICE_DIR := "res://audio/voice/"

# Existing AudioDirector seam test: manifest-known but intentionally unrecorded.
const INTENTIONALLY_DARK_LINE_IDS := [&"margin_reserved_dark"]

var _passed := 0
var _failed := 0

func _initialize() -> void:
	print("Running voice manifest tests...")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var manifest: Dictionary = _voice_line_manifest()
	var expected_paths: Dictionary = _expected_manifest_paths(manifest)
	var runtime_source_paths: Dictionary = _runtime_voice_source_paths()
	var manifest_count: int = _manifest_variant_count(manifest)
	var covered_count := 0

	_check("voice line manifest is not empty", not manifest.is_empty())
	_check_manifest_files_exist(expected_paths)
	covered_count = _check_audio_files_are_accounted_for(expected_paths, runtime_source_paths)
	_check_eq("covered .ogg file count equals file-backed manifest variant count", covered_count, manifest_count)

	print("")
	if _failed == 0 and _passed > 0:
		print("PASS - %d checks" % _passed)
		quit(0)
	else:
		printerr(
			"FAIL - %d passed, %d failed%s"
			% [_passed, _failed, " (0 checks => voice manifest suite failed to load/compile)" if _passed == 0 else ""]
		)
		quit(1)

func _check(desc: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("  ok   - ", desc)
	else:
		_failed += 1
		printerr("  FAIL - %s" % desc)

func _check_eq(desc: String, actual: Variant, expected: Variant) -> void:
	_check("%s (got %s, expected %s)" % [desc, actual, expected], actual == expected)

func _voice_line_manifest() -> Dictionary:
	var constants: Dictionary = (AudioDirectorScript as GDScript).get_script_constant_map()
	return constants.get("VOICE_LINE_MANIFEST", {}) as Dictionary

func _expected_manifest_paths(manifest: Dictionary) -> Dictionary:
	var expected_paths: Dictionary = {}
	for raw_line_id in _sorted_manifest_keys(manifest):
		var line_id := StringName(raw_line_id)
		if _is_intentionally_dark_line(line_id):
			continue
		var count := int(manifest.get(raw_line_id, 0))
		for path in _expected_paths_for(line_id, count):
			var owners: Array[StringName] = []
			if expected_paths.has(path):
				owners = expected_paths[path] as Array[StringName]
			owners.append(line_id)
			expected_paths[path] = owners
	return expected_paths

func _runtime_voice_source_paths() -> Dictionary:
	# OpeningSequence registers these through AudioDirector.register_voice_line().
	var paths: Dictionary = {}
	var sources: Dictionary = OpeningSequenceScript.VOICE_SOURCES
	for line_id in sources:
		var path := String(sources[line_id])
		if not path.begins_with(VOICE_DIR) or not path.ends_with(".ogg"):
			continue
		var owners: Array[StringName] = []
		if paths.has(path):
			owners = paths[path] as Array[StringName]
		owners.append(StringName(line_id))
		paths[path] = owners
	return paths

func _sorted_manifest_keys(manifest: Dictionary) -> Array:
	var keys := manifest.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	return keys

func _expected_paths_for(line_id: StringName, count: int) -> Array[String]:
	var paths: Array[String] = []
	if count <= 0:
		return paths
	if count == 1:
		paths.append("%s%s.ogg" % [VOICE_DIR, line_id])
		return paths
	for variant_index in range(1, count + 1):
		paths.append("%s%s_%d.ogg" % [VOICE_DIR, line_id, variant_index])
	return paths

func _manifest_variant_count(manifest: Dictionary) -> int:
	var total := 0
	for line_id in manifest:
		if _is_intentionally_dark_line(StringName(line_id)):
			continue
		total += int(manifest.get(line_id, 0))
	return total

func _check_manifest_files_exist(expected_paths: Dictionary) -> void:
	var paths := expected_paths.keys()
	paths.sort()
	for raw_path in paths:
		var path := String(raw_path)
		var owners: Array[StringName] = []
		if expected_paths.has(path):
			owners = expected_paths[path] as Array[StringName]
		_check(
			"manifest file exists for %s at %s" % [_owner_label(owners), path],
			FileAccess.file_exists(path)
		)

func _check_audio_files_are_accounted_for(expected_paths: Dictionary, runtime_source_paths: Dictionary) -> int:
	var covered_count := 0
	var file_names := DirAccess.get_files_at(VOICE_DIR)
	file_names.sort()
	for file_name in file_names:
		if not _is_source_ogg(file_name):
			continue
		var path := VOICE_DIR + file_name
		var owners: Array[StringName] = []
		if expected_paths.has(path):
			owners = expected_paths[path] as Array[StringName]
		var runtime_owners: Array[StringName] = []
		if runtime_source_paths.has(path):
			runtime_owners = runtime_source_paths[path] as Array[StringName]
		if owners.size() == 1:
			covered_count += 1
		_check(
			"voice file %s is covered by exactly one AudioDirector manifest entry or runtime voice source" % path,
			owners.size() == 1 or (owners.is_empty() and runtime_owners.size() == 1)
		)
	return covered_count

func _is_source_ogg(file_name: String) -> bool:
	return file_name.ends_with(".ogg") and not file_name.ends_with(".import") and not file_name.ends_with(".uid")

func _is_intentionally_dark_line(line_id: StringName) -> bool:
	return INTENTIONALLY_DARK_LINE_IDS.has(line_id)

func _owner_label(owners: Array[StringName]) -> String:
	if owners.is_empty():
		return "<unowned>"
	var labels: Array[String] = []
	for owner in owners:
		labels.append(String(owner))
	return ", ".join(labels)
