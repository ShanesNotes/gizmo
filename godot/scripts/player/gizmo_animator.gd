class_name GizmoAnimator
extends Node

## Expresses the player's state through an AnimationTree over the shipped
## gizmo.glb visual. STRICTLY AN OBSERVER: code-driven movement stays
## authoritative — no root motion, no writes to the body. It reads velocity,
## listens to existing AbilityComponent / PlayerVitals signals, and mounts the
## brass wrench on the right hand bone so the attack silhouette reads.
##
## Clips come from res://assets/animations/gizmo_clips.glb (animation-only GLB
## authored by tools/animation/author_gizmo_clips.py on a copy of the shipped
## 53-bone rig) and are grafted onto the live model at runtime.

const CLIPS_SCENE := preload("res://assets/animations/gizmo_clips.glb")
const WRENCH_SCENE := preload("res://assets/props/brass_winding_wrench/brass_winding_wrench.tscn")

## Pure state-mapping rules, testable headless without a scene tree.
class Logic:
	const MAX_RUN_TIME_SCALE := 1.5
	const ONE_SHOT_SLOTS: Array[StringName] = [&"attack", &"special", &"dash", &"hit", &"spark_cast"]
	const LOOPING_CLIPS: Array[StringName] = [&"idle", &"run"]
	## Cinematic poses played directly through the ClipPlayer (not the blend
	## tree) that must loop while held — e.g. the lore lane's campfire seat.
	const CINEMATIC_LOOPING_CLIPS: Array[StringName] = [&"campfire_sit"]
	## Personality idle-breakers, fired in alternation from a dedicated one-shot
	## once Gizmo has stood still past IDLE_FIDGET_DELAY (kept out of
	## ONE_SHOT_SLOTS so the combat request-path contract is unchanged).
	const FIDGET_CLIPS: Array[StringName] = [&"idle_fidget_key", &"idle_fidget_chirp"]
	const IDLE_FIDGET_DELAY := 7.0
	const IDLE_SPEED_EPSILON := 0.05

	## True once the standing-idle timer has crossed the fidget delay.
	static func should_fire_fidget(idle_time: float, delay: float) -> bool:
		return idle_time >= delay

	## Alternate key-turn / head-tilt so the same fidget never plays twice.
	static func next_fidget(index: int) -> StringName:
		return FIDGET_CLIPS[index % FIDGET_CLIPS.size()]

	## Measured horizontal speed -> locomotion blend position (0 idle, 1 run).
	static func locomotion_blend(speed: float, reference_speed: float) -> float:
		if reference_speed <= 0.0:
			return 1.0 if speed > 0.0 else 0.0
		return clampf(speed / reference_speed, 0.0, 1.0)

	## Above reference speed the run cycle plays faster so feet track the
	## ground; below it the blend position carries the change (never < 1.0,
	## or idle breathing would freeze).
	static func run_time_scale(speed: float, reference_speed: float) -> float:
		if reference_speed <= 0.0 or speed <= reference_speed:
			return 1.0
		return minf(speed / reference_speed, MAX_RUN_TIME_SCALE)

	## Ability slot -> AnimationTree one-shot request parameter path.
	static func request_path(slot: StringName) -> String:
		if not ONE_SHOT_SLOTS.has(slot):
			return ""
		return "parameters/%s_shot/request" % slot

## Game-feel over clip fidelity: tight fade-ins so actions snap, longer
## fade-outs so the body settles instead of popping (seconds: [in, out]).
const ONE_SHOT_FADES := {
	&"attack": [0.05, 0.10],
	&"special": [0.08, 0.15],
	&"dash": [0.04, 0.08],
	&"hit": [0.03, 0.12],
	&"spark_cast": [0.06, 0.12],
}
const DEATH_BLEND_SECONDS := 0.2
## Gentle blends so an idle-breaker eases in over the breathing idle.
const FIDGET_FADES := [0.25, 0.5]

@export var model_path: NodePath = NodePath("../VisualPivot/Model")
## 0 = read `move_speed` from the parent player (fallback 4.0).
@export var reference_speed: float = 0.0
## Arbitration with the zero-spend fallback layer (AnimationController /
## gizmo_animation_controller.gd, concurrent work): two mixers cannot drive one
## skeleton. Default: this authored-clip pipeline supersedes the fallback at
## runtime (its file is never touched). Set true to stand down instead.
@export var defer_to_fallback_controller: bool = false
@export_group("Weapon")
@export var weapon_bone: String = "Bone_024"  # right hand (fable-assets bone audit wins; was Bone_019)
@export var weapon_scale: float = 0.45
@export var weapon_position: Vector3 = Vector3(0.0, 0.10, 0.0)
@export var weapon_rotation_degrees: Vector3 = Vector3(0.0, 0.0, 90.0)

var animation_tree: AnimationTree
var _model: Node3D
var _anim_player: AnimationPlayer
var _reference_speed := 4.0
var _death_playing := false
var _vitals_connected := false
var _idle_time := 0.0
var _fidget_index := 0

static func build_animation_library() -> AnimationLibrary:
	var instance := CLIPS_SCENE.instantiate()
	var source: AnimationPlayer = instance.find_child("AnimationPlayer", true, false)
	if source == null:
		instance.free()
		push_error("gizmo_clips.glb has no AnimationPlayer; re-run tools/animation/author_gizmo_clips.py")
		return null
	var names := source.get_animation_library_list()
	if names.is_empty():
		instance.free()
		return null
	var library: AnimationLibrary = source.get_animation_library(names[0]).duplicate(true)
	instance.free()
	for clip in library.get_animation_list():
		var animation := library.get_animation(clip)
		animation.loop_mode = Animation.LOOP_LINEAR if (Logic.LOOPING_CLIPS.has(clip) \
				or Logic.CINEMATIC_LOOPING_CLIPS.has(clip)) else Animation.LOOP_NONE
	return library

func _ready() -> void:
	_model = get_node_or_null(model_path) as Node3D
	if _model == null:
		push_warning("GizmoAnimator found no model at %s; animation disabled." % model_path)
		set_physics_process(false)
		return
	if not _arbitrate_with_fallback_controller():
		set_physics_process(false)
		return
	_resolve_reference_speed()
	_build_player_and_tree()
	_mount_weapon()
	_connect_ability_signals()
	_try_connect_vitals()

func _physics_process(delta: float) -> void:
	if not _vitals_connected:
		_try_connect_vitals()
	if animation_tree == null or _death_playing:
		return
	var speed := _horizontal_speed()
	animation_tree.set("parameters/locomotion/blend_position",
			Logic.locomotion_blend(speed, _reference_speed))
	animation_tree.set("parameters/speed/scale",
			Logic.run_time_scale(speed, _reference_speed))
	_tick_idle_fidget(delta, speed)

## Standing-idle personality: once Gizmo has held still past the delay, fire an
## alternating fidget and reset. Any motion or combat one-shot resets the timer.
func _tick_idle_fidget(delta: float, speed: float) -> void:
	if not animation_tree.active or speed >= Logic.IDLE_SPEED_EPSILON:
		_idle_time = 0.0
		return
	_idle_time += delta
	if Logic.should_fire_fidget(_idle_time, Logic.IDLE_FIDGET_DELAY):
		_idle_time = 0.0
		play_fidget(Logic.next_fidget(_fidget_index))
		_fidget_index += 1

## Swap the shared fidget one-shot to `clip` and fire it over the idle blend.
func play_fidget(clip: StringName) -> void:
	if animation_tree == null or _death_playing:
		return
	var tree := animation_tree.tree_root as AnimationNodeBlendTree
	if tree == null or not tree.has_node(&"fidget_clip"):
		return
	var node := tree.get_node(&"fidget_clip") as AnimationNodeAnimation
	if node == null or (_anim_player != null and not _anim_player.has_animation(clip)):
		return
	node.animation = clip
	animation_tree.set("parameters/fidget_shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

## Fire a one-shot expression (attack/special/dash/hit) over locomotion.
func play_one_shot(slot: StringName) -> void:
	if animation_tree == null or _death_playing:
		return
	var path := Logic.request_path(slot)
	if path.is_empty():
		return
	_idle_time = 0.0  # acting resets the standing-idle fidget clock
	animation_tree.set(path, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

## Death takes over playback entirely; the final slump pose holds.
func play_death() -> void:
	if _anim_player == null or _death_playing:
		return
	_death_playing = true
	if animation_tree != null:
		animation_tree.active = false
	_anim_player.play(&"death", DEATH_BLEND_SECONDS)

func is_death_playing() -> bool:
	return _death_playing

## Rekindle/room-clear celebration (safe to call from orchestrators).
func play_victory() -> void:
	if _anim_player == null or _death_playing:
		return
	if animation_tree != null:
		animation_tree.active = false
	_anim_player.play(&"victory", DEATH_BLEND_SECONDS)

## Seat Gizmo at the campfire for the lore lane's opening cinematic. Takes over
## playback with the looping "campfire_sit" pose; call resume_locomotion() to
## hand control back to the blend tree when the beat ends.
func play_campfire_sit() -> void:
	if _anim_player == null or _death_playing:
		return
	if animation_tree != null:
		animation_tree.active = false
	_anim_player.play(&"campfire_sit", DEATH_BLEND_SECONDS)

## Return control to the blend tree (after victory, or on respawn/reset).
func resume_locomotion() -> void:
	_death_playing = false
	if animation_tree != null:
		animation_tree.active = true

# --- construction ------------------------------------------------------------

func _build_player_and_tree() -> void:
	var library := build_animation_library()
	if library == null:
		return
	_graft_timed_swing_clips(library)
	_anim_player = AnimationPlayer.new()
	_anim_player.name = "ClipPlayer"
	add_child(_anim_player)
	_anim_player.root_node = _anim_player.get_path_to(_model)
	_anim_player.add_animation_library(&"", library)

	animation_tree = AnimationTree.new()
	animation_tree.name = "GizmoAnimationTree"
	add_child(animation_tree)
	animation_tree.anim_player = animation_tree.get_path_to(_anim_player)
	animation_tree.tree_root = _build_blend_tree()
	animation_tree.active = true

## Animation-led combat (playtest 2): the swing clips' strike poses are keyed
## to SwingTiming's contact seconds (the resolver's damage frame), and the
## 3-step combo needs three distinct silhouettes. The code-built swing clips
## own those slots; the authored GLB keeps everything else. Their tracks are
## remapped from the code library's "Skeleton3D:" root onto whatever node
## path the GLB tracks use, so both drive the same skeleton.
func _graft_timed_swing_clips(library: AnimationLibrary) -> void:
	var skeleton: Skeleton3D = _model.find_child("Skeleton3D", true, false)
	if skeleton == null:
		return
	var prefix := _skeleton_track_prefix(library)
	var code_library := GizmoAnimationController.build_clip_library(skeleton)
	for clip_name: StringName in [&"attack_1", &"attack_2", &"attack_3", &"special"]:
		if not code_library.has_animation(clip_name):
			continue
		var animation: Animation = code_library.get_animation(clip_name).duplicate(true)
		for track in animation.get_track_count():
			var path := String(animation.track_get_path(track))
			var bone_split := path.rsplit(":", true, 1)
			if bone_split.size() == 2:
				animation.track_set_path(track, "%s:%s" % [prefix, bone_split[1]])
		animation.loop_mode = Animation.LOOP_NONE
		if library.has_animation(clip_name):
			library.remove_animation(clip_name)
		library.add_animation(clip_name, animation)
	# The attack one-shot slot defaults to &"attack"; keep that name pointing
	# at the timed step-1 swing so every route sees SwingTiming's contact.
	if library.has_animation(&"attack_1"):
		if library.has_animation(&"attack"):
			library.remove_animation(&"attack")
		library.add_animation(&"attack", library.get_animation(&"attack_1").duplicate(true))

func _skeleton_track_prefix(library: AnimationLibrary) -> String:
	for clip in library.get_animation_list():
		var animation := library.get_animation(clip)
		for track in animation.get_track_count():
			var path := String(animation.track_get_path(track))
			var split := path.rsplit(":", true, 1)
			if split.size() == 2 and split[0].contains("Skeleton3D"):
				return split[0]
	return "Skeleton3D"

## Route the attack one-shot to the combo step's swing variant before firing.
func _set_attack_variant(step: int) -> void:
	if animation_tree == null:
		return
	var tree := animation_tree.tree_root as AnimationNodeBlendTree
	if tree == null or not tree.has_node(&"attack_clip"):
		return
	var clip := tree.get_node(&"attack_clip") as AnimationNodeAnimation
	if clip == null:
		return
	var variant: StringName = SwingTiming.melee_clip_name(step)
	if _anim_player != null and _anim_player.has_animation(variant):
		clip.animation = variant

func _build_blend_tree() -> AnimationNodeBlendTree:
	var tree := AnimationNodeBlendTree.new()

	var locomotion := AnimationNodeBlendSpace1D.new()
	var idle_clip := AnimationNodeAnimation.new()
	idle_clip.animation = &"idle"
	var run_clip := AnimationNodeAnimation.new()
	run_clip.animation = &"run"
	locomotion.add_blend_point(idle_clip, 0.0, -1, &"idle")
	locomotion.add_blend_point(run_clip, 1.0, -1, &"run")
	tree.add_node(&"locomotion", locomotion, Vector2(-500, 0))

	var speed := AnimationNodeTimeScale.new()
	tree.add_node(&"speed", speed, Vector2(-300, 0))
	tree.connect_node(&"speed", 0, &"locomotion")

	var previous: StringName = &"speed"
	var column := -100
	for slot: StringName in Logic.ONE_SHOT_SLOTS:
		var shot := AnimationNodeOneShot.new()
		var fades: Array = ONE_SHOT_FADES[slot]
		shot.fadein_time = fades[0]
		shot.fadeout_time = fades[1]
		var clip := AnimationNodeAnimation.new()
		clip.animation = slot  # clip names match slot names by construction
		var shot_name := StringName("%s_shot" % slot)
		var clip_name := StringName("%s_clip" % slot)
		tree.add_node(shot_name, shot, Vector2(column, 0))
		tree.add_node(clip_name, clip, Vector2(column, 150))
		tree.connect_node(shot_name, 0, previous)
		tree.connect_node(shot_name, 1, clip_name)
		previous = shot_name
		column += 200
	# Dedicated idle-fidget one-shot, chained last so a personality beat layers
	# over locomotion but yields to any combat one-shot below it. Its clip is
	# swapped per fire (see play_fidget); default to the first fidget.
	var fidget := AnimationNodeOneShot.new()
	fidget.fadein_time = FIDGET_FADES[0]
	fidget.fadeout_time = FIDGET_FADES[1]
	var fidget_clip := AnimationNodeAnimation.new()
	fidget_clip.animation = Logic.FIDGET_CLIPS[0]
	tree.add_node(&"fidget_shot", fidget, Vector2(column, 0))
	tree.add_node(&"fidget_clip", fidget_clip, Vector2(column, 150))
	tree.connect_node(&"fidget_shot", 0, previous)
	tree.connect_node(&"fidget_shot", 1, &"fidget_clip")
	previous = &"fidget_shot"
	tree.connect_node(&"output", 0, previous)
	return tree

## Runs after the sibling fallback's _ready (scene order). Returns true when
## this animator should drive the skeleton.
func _arbitrate_with_fallback_controller() -> bool:
	var fallback := get_parent().get_node_or_null("AnimationController")
	if fallback == null:
		return true
	if defer_to_fallback_controller:
		print("GizmoAnimator: deferring to fallback AnimationController (export flag).")
		return false
	print("GizmoAnimator: authored-clip pipeline superseding fallback AnimationController at runtime.")
	fallback.process_mode = Node.PROCESS_MODE_DISABLED
	var fallback_player: Variant = fallback.get("animation_player")
	if fallback_player is AnimationPlayer:
		(fallback_player as AnimationPlayer).stop()
	var skeleton: Skeleton3D = _model.find_child("Skeleton3D", true, false)
	if skeleton != null:
		skeleton.reset_bone_poses()
		var fallback_mount := skeleton.get_node_or_null("WeaponMount") as Node3D
		if fallback_mount != null:
			fallback_mount.visible = false
	return true

func _mount_weapon() -> void:
	var skeleton: Skeleton3D = _model.find_child("Skeleton3D", true, false)
	if skeleton == null or skeleton.find_bone(weapon_bone) < 0:
		push_warning("GizmoAnimator: no skeleton/bone '%s'; weapon not mounted." % weapon_bone)
		return
	var mount := BoneAttachment3D.new()
	mount.name = "GizmoWeaponMount"
	skeleton.add_child(mount)
	mount.bone_name = weapon_bone
	var wrench := WRENCH_SCENE.instantiate() as Node3D
	wrench.name = "BrassWrench"
	mount.add_child(wrench)
	wrench.scale = Vector3.ONE * weapon_scale
	wrench.position = weapon_position
	wrench.rotation_degrees = weapon_rotation_degrees

# --- signal seams (additive; existing signals only) ---------------------------

func _connect_ability_signals() -> void:
	var abilities := get_parent().get_node_or_null("AbilityComponent")
	if abilities == null:
		return
	abilities.attack_started.connect(func(step: int, _damage: float) -> void:
		_set_attack_variant(step)
		play_one_shot(&"attack"))
	abilities.special_started.connect(func(_potency: float) -> void:
		play_one_shot(&"special"))
	# Surge reuses the heavy two-hand slam read; cast throws the spark as a gift
	# (dedicated underhand-lob clip, contact-true release beat).
	abilities.surge_started.connect(func(_damage: float, _radius: float, _stagger: float) -> void:
		play_one_shot(&"special"))
	abilities.cast_started.connect(func(_potency: float) -> void:
		play_one_shot(&"spark_cast"))
	abilities.dash_started.connect(func(_direction: Vector3, _speed: float, _duration: float) -> void:
		play_one_shot(&"dash"))

func _try_connect_vitals() -> void:
	var vitals := get_parent().get_node_or_null("PlayerVitals")
	if vitals == null:
		return
	_vitals_connected = true
	if vitals.has_signal("damage_taken") and not vitals.damage_taken.is_connected(_on_damage_taken):
		vitals.damage_taken.connect(_on_damage_taken)
	if not vitals.player_died.is_connected(_on_player_died):
		vitals.player_died.connect(_on_player_died)

func _on_damage_taken(_absorbed: int, _hp_damage: int) -> void:
	play_one_shot(&"hit")

func _on_player_died() -> void:
	play_death()

# --- helpers ------------------------------------------------------------------

func _resolve_reference_speed() -> void:
	if reference_speed > 0.0:
		_reference_speed = reference_speed
		return
	var parent_speed: Variant = get_parent().get("move_speed")
	_reference_speed = float(parent_speed) if parent_speed is float else 4.0

func _horizontal_speed() -> float:
	var body := get_parent() as CharacterBody3D
	if body == null:
		return 0.0
	return Vector2(body.velocity.x, body.velocity.z).length()
