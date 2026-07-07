extends SceneTree

# Headless tests for the Gizmo animation pipeline:
#   - GizmoAnimator.Logic pure state-mapping (velocity -> locomotion params,
#     ability signal -> one-shot request path)
#   - the authored clip GLB (res://assets/animations/gizmo_clips.glb) arriving
#     as a usable AnimationLibrary with correct loop modes
#   - the runtime wiring smoke: AnimationTree grafted onto the shipped
#     gizmo.glb visual, weapon mounted on the right hand bone
#   - the PlayerVitals damage_taken hit-react seam
# Run: godot --headless --path godot --user-data-dir /tmp/fable-anim-agent \
#        --script res://tests/run_animation_tests.gd
# Exits 0 if all pass, 1 if any fail.

var _passed := 0
var _failed := 0

const GizmoAnimatorScript := preload("res://scripts/player/gizmo_animator.gd")
const PlayerVitalsScript := preload("res://scripts/player/player_vitals.gd")
const GizmoGlb := preload("res://assets/gizmo.glb")

const EXPECTED_CLIPS: Array[StringName] = [
	&"idle", &"run", &"attack", &"special", &"dash", &"hit", &"death", &"victory",
]

func _initialize() -> void:
	print("Running animation tests…")
	_test_locomotion_blend()
	_test_run_time_scale()
	_test_one_shot_request_paths()
	_test_clip_library_contents()
	_test_clip_library_loop_modes()
	_test_vitals_damage_taken_seam()
	await _test_runtime_wiring_smoke()
	print("")
	if _failed == 0 and _passed > 0:
		print("PASS — %d checks" % _passed)
		quit(0)
	else:
		print("FAIL — %d passed, %d failed" % [_passed, _failed])
		quit(1)

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("  FAILED: %s" % label)

# --- pure logic -------------------------------------------------------------

func _test_locomotion_blend() -> void:
	var logic := GizmoAnimatorScript.Logic
	_check(is_equal_approx(logic.locomotion_blend(0.0, 4.0), 0.0), "blend at rest is 0")
	_check(is_equal_approx(logic.locomotion_blend(2.0, 4.0), 0.5), "blend at half speed is 0.5")
	_check(is_equal_approx(logic.locomotion_blend(4.0, 4.0), 1.0), "blend at reference speed is 1")
	_check(is_equal_approx(logic.locomotion_blend(9.0, 4.0), 1.0), "blend clamps above reference")
	_check(is_equal_approx(logic.locomotion_blend(-1.0, 4.0), 0.0), "blend clamps below zero")
	_check(is_equal_approx(logic.locomotion_blend(3.0, 0.0), 1.0), "degenerate reference treats motion as full run")

func _test_run_time_scale() -> void:
	var logic := GizmoAnimatorScript.Logic
	_check(is_equal_approx(logic.run_time_scale(4.0, 4.0), 1.0), "run playback 1x at reference speed")
	_check(is_equal_approx(logic.run_time_scale(0.0, 4.0), 1.0), "idle speed keeps timescale at 1 (idle must not freeze)")
	_check(is_equal_approx(logic.run_time_scale(2.0, 4.0), 1.0), "below reference clamps to 1 floor via blend dominance")
	_check(is_equal_approx(logic.run_time_scale(8.0, 4.0), logic.MAX_RUN_TIME_SCALE), "double speed clamps to max timescale")
	var mid := logic.run_time_scale(5.0, 4.0)
	_check(mid > 1.0 and mid < logic.MAX_RUN_TIME_SCALE, "between reference and max scales proportionally")

func _test_one_shot_request_paths() -> void:
	var logic := GizmoAnimatorScript.Logic
	_check(logic.ONE_SHOT_SLOTS.size() == 4, "four one-shot slots (attack/special/dash/hit)")
	_check(logic.request_path(&"attack") == "parameters/attack_shot/request", "attack request path")
	_check(logic.request_path(&"special") == "parameters/special_shot/request", "special request path")
	_check(logic.request_path(&"dash") == "parameters/dash_shot/request", "dash request path")
	_check(logic.request_path(&"hit") == "parameters/hit_shot/request", "hit request path")
	_check(logic.request_path(&"nonsense") == "", "unknown slot maps to empty path")

# --- authored clip asset ----------------------------------------------------

func _test_clip_library_contents() -> void:
	var library: AnimationLibrary = GizmoAnimatorScript.build_animation_library()
	_check(library != null, "clip library builds from gizmo_clips.glb")
	if library == null:
		return
	for clip in EXPECTED_CLIPS:
		_check(library.has_animation(clip), "library has clip '%s'" % clip)
	var attack := library.get_animation(&"attack")
	_check(attack != null and attack.length > 0.2 and attack.length < 0.8, "attack clip length is snappy")

func _test_clip_library_loop_modes() -> void:
	var library: AnimationLibrary = GizmoAnimatorScript.build_animation_library()
	if library == null:
		_check(false, "clip library unavailable for loop-mode checks")
		return
	_check(library.get_animation(&"idle").loop_mode == Animation.LOOP_LINEAR, "idle loops")
	_check(library.get_animation(&"run").loop_mode == Animation.LOOP_LINEAR, "run loops")
	_check(library.get_animation(&"death").loop_mode == Animation.LOOP_NONE, "death does not loop")
	_check(library.get_animation(&"attack").loop_mode == Animation.LOOP_NONE, "attack does not loop")

# --- PlayerVitals hit-react seam --------------------------------------------

func _test_vitals_damage_taken_seam() -> void:
	var vitals := PlayerVitalsScript.new()
	_check(vitals.has_signal("damage_taken"), "PlayerVitals exposes damage_taken signal")
	if not vitals.has_signal("damage_taken"):
		vitals.free()
		return
	vitals.reset()
	var hits: Array = []
	vitals.damage_taken.connect(func(absorbed: int, hp_damage: int) -> void:
		hits.append([absorbed, hp_damage]))
	vitals.apply_damage(2)
	_check(hits.size() == 1, "damage_taken fires once per damaging hit")
	if hits.size() == 1:
		_check(int(hits[0][0]) == 2, "damage_taken reports guard absorption")
	vitals.apply_damage(1)
	_check(hits.size() == 1, "damage lockout suppresses damage_taken")
	vitals.free()

# --- runtime wiring smoke ----------------------------------------------------

func _test_runtime_wiring_smoke() -> void:
	var player := CharacterBody3D.new()
	player.name = "GizmoPlayer"
	var pivot := Node3D.new()
	pivot.name = "VisualPivot"
	player.add_child(pivot)
	var model: Node3D = GizmoGlb.instantiate()
	model.name = "Model"
	pivot.add_child(model)
	var animator: Node = GizmoAnimatorScript.new()
	animator.name = "GizmoAnimator"
	player.add_child(animator)
	root.add_child(player)
	await process_frame

	var tree: AnimationTree = animator.animation_tree
	_check(tree != null, "animator builds an AnimationTree")
	if tree == null:
		player.queue_free()
		return
	_check(tree.active, "AnimationTree is active")
	_check(tree.get("parameters/locomotion/blend_position") != null, "locomotion blend parameter exists")

	player.velocity = Vector3(4.0, 0.0, 0.0)
	await physics_frame
	await physics_frame
	_check(is_equal_approx(float(tree.get("parameters/locomotion/blend_position")), 1.0),
		"full velocity drives locomotion blend to run")

	animator.play_one_shot(&"attack")
	await process_frame
	await process_frame
	_check(bool(tree.get("parameters/attack_shot/active")), "attack one-shot fires through the tree")

	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false)
	_check(skeleton != null, "shipped model exposes Skeleton3D")
	if skeleton != null:
		var mount := skeleton.get_node_or_null("GizmoWeaponMount") as BoneAttachment3D
		_check(mount != null, "weapon mount BoneAttachment3D exists")
		if mount != null:
			_check(mount.bone_name != "", "weapon mount is bound to a bone")
			_check(mount.get_child_count() > 0, "wrench attached under the mount")

	animator.play_death()
	await process_frame
	_check(animator.is_death_playing(), "death takes over playback")

	player.queue_free()
	await process_frame
