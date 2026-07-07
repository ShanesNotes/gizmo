class_name GizmoAnimationController
extends Node

## Cosmetic skeletal animation layer for Gizmo's 53-bone rig. Authors the clip
## library in code (canon/animation-pipeline.yaml fallback_2: code-driven clips,
## zero spend), mirrors PlayerActionStateMachine states onto clips, and mounts
## the weapon on the right-hand bone. Reads gameplay state; never writes it.
## Composes with GizmoVisual: that script moves the whole Model node (bob/lean),
## this one poses bones inside it.

const LIBRARY_NAME := "gizmo"
const WEAPON_SCENE_PATH := "res://assets/props/brass_winding_wrench/brass_winding_wrench.tscn"
const RIGHT_HAND_BONE := "Bone_024"

## Clip-source seam (team-lead ruling 2026-07-06): when a Blender-authored
## animation-only GLB exists at this path, its clips supersede the code-built
## poses per contract clip name (aliases below); any clip it lacks falls back
## to the code-built library, so the full contract always ships. Track paths
## are remapped onto this controller's skeleton on graft.
const EXTERNAL_CLIPS_PATH := "res://assets/animations/gizmo_clips.glb"
const EXTERNAL_CLIP_ALIASES := {&"hit_react": &"hit"}
## Night-lane update 2026-07-07: the authored GLB now carries attack_1/2/3 and
## special keyed CONTACT-TRUE to SwingTiming (authored at 50fps so 0.10/0.14/
## 0.22s land on exact frames; strike keys verified at camera). The code-built
## swings remain in CLIP_DATA as the guarantee tier — graft only replaces a
## clip the GLB actually carries, so timing law still holds if the GLB is lost.
## Clips beyond the state contract, grafted when the GLB carries them
## (value = loop mode; NLA import drops loop flags so they are pinned here).
## campfire_sit is the lore lane's cinematic clip — called by name.
const EXTERNAL_EXTRA_CLIPS := {
	&"spark_cast": false,
	&"death": false,
	&"victory": false,
	&"campfire_sit": true,
	&"idle_fidget_key": false,
	&"idle_fidget_chirp": false,
}
## Personality fidgets: after this long of unbroken idle, one plays, then idle
## resumes. Alternates between the two.
const FIDGET_CLIPS: Array[StringName] = [&"idle_fidget_key", &"idle_fidget_chirp"]
const FIDGET_IDLE_SECONDS := 7.0
## The authored clips swing the Bone_019-hand arm (audited at camera 2026-07-06);
## the code-built fallback clips swing the Bone_024-hand arm. The weapon mount
## follows whichever source won the attack clip so the wrench rides the swing.
const EXTERNAL_WEAPON_BONE := "Bone_019"
## Authored walk cycle is 0.72s (canon cadence) — a walk, not Gizmo's eager
## patter. The run clip plays through this multiplier so locomotion stays quick.
const RUN_EAGERNESS := 1.3

# Bone aliases for the meshy/UniRig skeleton (see brief: gizmo_clips.brief.yaml).
const B_ROOT := "Bone_000"
const B_SPINE_LOW := "Bone_005"
const B_SPINE_MID := "Bone_004"
const B_CHEST := "Bone_002"
const B_NECK := "Bone_018"
const B_HEAD := "Bone_016"
const B_L_UPPER_ARM := "Bone_022"
const B_L_ELBOW := "Bone_021"
const B_R_UPPER_ARM := "Bone_027"
const B_R_ELBOW := "Bone_026"
const B_L_HIP := "Bone_010"
const B_L_KNEE := "Bone_009"
const B_R_HIP := "Bone_015"
const B_R_KNEE := "Bone_014"

@export var skeleton_path: NodePath = NodePath("../VisualPivot/Model/UniRigArmature/Skeleton3D")
@export var clip_blend_seconds: float = 0.12
@export var moving_speed_threshold: float = 0.4
@export var run_speed_reference: float = 4.0

var animation_player: AnimationPlayer = null

var _skeleton: Skeleton3D = null
var _current_clip: StringName = &""
var _external_attack_grafted := false
var _idle_seconds := 0.0
var _next_fidget := 0

## Clip data: per-clip length/loop and keyframes. Each key holds per-bone euler
## rotation deltas (radians, applied on top of the bone rest pose) plus a root
## bone vertical offset. Signs verified at camera via the pose-proof render pass.
const CLIP_DATA := {
	&"idle": {
		"length": 2.4,
		"loop": true,
		"keys": [
			{"t": 0.0, "root_y": 0.0, "bones": {
				B_CHEST: Vector3(0.02, 0.0, 0.0),
				B_HEAD: Vector3(0.03, 0.0, 0.0),
			}},
			{"t": 0.6, "root_y": 0.006, "bones": {
				B_CHEST: Vector3(-0.01, 0.0, 0.0),
				B_SPINE_LOW: Vector3(-0.02, 0.0, 0.0),
				B_HEAD: Vector3(0.0, 0.10, 0.0),
				B_L_UPPER_ARM: Vector3(0.0, 0.0, 0.05),
				B_R_UPPER_ARM: Vector3(0.0, 0.0, -0.05),
			}},
			{"t": 1.2, "root_y": 0.012, "bones": {
				B_CHEST: Vector3(-0.05, 0.0, 0.0),
				B_SPINE_LOW: Vector3(-0.03, 0.0, 0.0),
				B_HEAD: Vector3(-0.05, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(0.0, 0.0, 0.08),
				B_R_UPPER_ARM: Vector3(0.0, 0.0, -0.08),
			}},
			{"t": 1.8, "root_y": 0.005, "bones": {
				B_CHEST: Vector3(-0.01, 0.0, 0.0),
				B_HEAD: Vector3(0.0, -0.08, 0.0),
			}},
			{"t": 2.4, "root_y": 0.0, "bones": {
				B_CHEST: Vector3(0.02, 0.0, 0.0),
				B_HEAD: Vector3(0.03, 0.0, 0.0),
			}},
		],
	},
	&"run": {
		"length": 0.5,
		"loop": true,
		"keys": [
			{"t": 0.0, "root_y": -0.01, "bones": {
				B_SPINE_LOW: Vector3(0.10, 0.0, 0.0),
				B_CHEST: Vector3(0.08, 0.0, 0.0),
				B_HEAD: Vector3(-0.08, 0.0, 0.0),
				B_L_HIP: Vector3(-0.5, 0.0, 0.0),
				B_L_KNEE: Vector3(0.15, 0.0, 0.0),
				B_R_HIP: Vector3(0.45, 0.0, 0.0),
				B_R_KNEE: Vector3(0.55, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(0.5, 0.0, 0.08),
				B_L_ELBOW: Vector3(0.35, 0.0, 0.0),
				B_R_UPPER_ARM: Vector3(-0.5, 0.0, -0.08),
				B_R_ELBOW: Vector3(0.35, 0.0, 0.0),
			}},
			{"t": 0.125, "root_y": 0.02, "bones": {
				B_SPINE_LOW: Vector3(0.10, 0.0, 0.0),
				B_CHEST: Vector3(0.08, 0.0, 0.0),
				B_HEAD: Vector3(-0.08, 0.0, 0.0),
				B_L_HIP: Vector3(0.0, 0.0, 0.0),
				B_L_KNEE: Vector3(0.45, 0.0, 0.0),
				B_R_HIP: Vector3(0.0, 0.0, 0.0),
				B_R_KNEE: Vector3(0.45, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(0.0, 0.0, 0.08),
				B_R_UPPER_ARM: Vector3(0.0, 0.0, -0.08),
				B_L_ELBOW: Vector3(0.35, 0.0, 0.0),
				B_R_ELBOW: Vector3(0.35, 0.0, 0.0),
			}},
			{"t": 0.25, "root_y": -0.01, "bones": {
				B_SPINE_LOW: Vector3(0.10, 0.0, 0.0),
				B_CHEST: Vector3(0.08, 0.0, 0.0),
				B_HEAD: Vector3(-0.08, 0.0, 0.0),
				B_L_HIP: Vector3(0.45, 0.0, 0.0),
				B_L_KNEE: Vector3(0.55, 0.0, 0.0),
				B_R_HIP: Vector3(-0.5, 0.0, 0.0),
				B_R_KNEE: Vector3(0.15, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(-0.5, 0.0, 0.08),
				B_L_ELBOW: Vector3(0.35, 0.0, 0.0),
				B_R_UPPER_ARM: Vector3(0.5, 0.0, -0.08),
				B_R_ELBOW: Vector3(0.35, 0.0, 0.0),
			}},
			{"t": 0.375, "root_y": 0.02, "bones": {
				B_SPINE_LOW: Vector3(0.10, 0.0, 0.0),
				B_CHEST: Vector3(0.08, 0.0, 0.0),
				B_HEAD: Vector3(-0.08, 0.0, 0.0),
				B_L_HIP: Vector3(0.0, 0.0, 0.0),
				B_L_KNEE: Vector3(0.45, 0.0, 0.0),
				B_R_HIP: Vector3(0.0, 0.0, 0.0),
				B_R_KNEE: Vector3(0.45, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(0.0, 0.0, 0.08),
				B_R_UPPER_ARM: Vector3(0.0, 0.0, -0.08),
				B_L_ELBOW: Vector3(0.35, 0.0, 0.0),
				B_R_ELBOW: Vector3(0.35, 0.0, 0.0),
			}},
			{"t": 0.5, "root_y": -0.01, "bones": {
				B_SPINE_LOW: Vector3(0.10, 0.0, 0.0),
				B_CHEST: Vector3(0.08, 0.0, 0.0),
				B_HEAD: Vector3(-0.08, 0.0, 0.0),
				B_L_HIP: Vector3(-0.5, 0.0, 0.0),
				B_L_KNEE: Vector3(0.15, 0.0, 0.0),
				B_R_HIP: Vector3(0.45, 0.0, 0.0),
				B_R_KNEE: Vector3(0.55, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(0.5, 0.0, 0.08),
				B_L_ELBOW: Vector3(0.35, 0.0, 0.0),
				B_R_UPPER_ARM: Vector3(-0.5, 0.0, -0.08),
				B_R_ELBOW: Vector3(0.35, 0.0, 0.0),
			}},
		],
	},
	&"dash": {
		"length": 0.25,
		"loop": false,
		"keys": [
			{"t": 0.0, "root_y": -0.04, "bones": {
				B_SPINE_LOW: Vector3(0.15, 0.0, 0.0),
				B_L_KNEE: Vector3(0.3, 0.0, 0.0),
				B_R_KNEE: Vector3(0.3, 0.0, 0.0),
			}},
			{"t": 0.07, "root_y": -0.03, "bones": {
				B_SPINE_LOW: Vector3(0.42, 0.0, 0.0),
				B_CHEST: Vector3(0.26, 0.0, 0.0),
				B_HEAD: Vector3(-0.30, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(-1.3, 0.0, 0.15),
				B_R_UPPER_ARM: Vector3(-1.3, 0.0, -0.15),
				B_L_ELBOW: Vector3(-0.2, 0.0, 0.0),
				B_R_ELBOW: Vector3(-0.2, 0.0, 0.0),
				B_L_HIP: Vector3(-0.2, 0.0, 0.0),
				B_R_HIP: Vector3(0.35, 0.0, 0.0),
				B_R_KNEE: Vector3(0.5, 0.0, 0.0),
			}},
			{"t": 0.25, "root_y": -0.02, "bones": {
				B_SPINE_LOW: Vector3(0.26, 0.0, 0.0),
				B_CHEST: Vector3(0.16, 0.0, 0.0),
				B_HEAD: Vector3(-0.18, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(-0.85, 0.0, 0.15),
				B_R_UPPER_ARM: Vector3(-0.85, 0.0, -0.15),
				B_L_HIP: Vector3(-0.15, 0.0, 0.0),
				B_R_HIP: Vector3(0.3, 0.0, 0.0),
			}},
		],
	},
	## Combo swings (playtest 2, animation-led): three DISTINCT silhouettes so
	## the kit's 3-step combo reads as three different attacks. Strike poses
	## sit exactly on SwingTiming's contact seconds — the resolver's damage
	## frame — so the hit lands when the swing visually connects.
	&"attack_1": {
		# Forehand sweep, right-to-left. Contact at 0.10s.
		"length": 0.4,
		"loop": false,
		"keys": [
			{"t": 0.0, "root_y": 0.0, "bones": {}},
			{"t": 0.05, "root_y": 0.02, "bones": {
				B_R_UPPER_ARM: Vector3(2.2, 0.0, -0.3),
				B_R_ELBOW: Vector3(0.9, 0.0, 0.0),
				B_CHEST: Vector3(-0.08, 0.35, 0.0),
				B_SPINE_LOW: Vector3(-0.08, 0.20, 0.0),
				B_L_UPPER_ARM: Vector3(0.4, 0.0, 0.2),
				B_HEAD: Vector3(0.0, -0.20, 0.0),
			}},
			{"t": 0.10, "root_y": -0.04, "bones": {
				B_R_UPPER_ARM: Vector3(0.7, 0.0, -0.1),
				B_R_ELBOW: Vector3(0.15, 0.0, 0.0),
				B_CHEST: Vector3(0.24, -0.40, 0.0),
				B_SPINE_LOW: Vector3(0.30, -0.25, 0.0),
				B_L_UPPER_ARM: Vector3(-0.5, 0.0, 0.3),
				B_HEAD: Vector3(0.10, 0.10, 0.0),
				B_L_KNEE: Vector3(0.3, 0.0, 0.0),
				B_R_KNEE: Vector3(0.3, 0.0, 0.0),
			}},
			{"t": 0.22, "root_y": -0.02, "bones": {
				B_R_UPPER_ARM: Vector3(0.4, 0.0, 0.0),
				B_CHEST: Vector3(0.12, -0.20, 0.0),
				B_SPINE_LOW: Vector3(0.12, -0.10, 0.0),
			}},
			{"t": 0.4, "root_y": 0.0, "bones": {
				B_R_UPPER_ARM: Vector3(0.3, 0.0, 0.0),
				B_CHEST: Vector3(0.08, -0.10, 0.0),
			}},
		],
	},
	&"attack_2": {
		# Backhand return, left-to-right — mirrored torso wind. Contact 0.10s.
		"length": 0.4,
		"loop": false,
		"keys": [
			{"t": 0.0, "root_y": 0.0, "bones": {}},
			{"t": 0.05, "root_y": 0.01, "bones": {
				B_R_UPPER_ARM: Vector3(0.9, 0.0, 0.5),
				B_R_ELBOW: Vector3(0.5, 0.0, 0.0),
				B_CHEST: Vector3(0.10, -0.45, 0.0),
				B_SPINE_LOW: Vector3(0.10, -0.25, 0.0),
				B_HEAD: Vector3(0.0, 0.20, 0.0),
			}},
			{"t": 0.10, "root_y": -0.03, "bones": {
				B_R_UPPER_ARM: Vector3(1.6, 0.0, -0.6),
				B_R_ELBOW: Vector3(0.2, 0.0, 0.0),
				B_CHEST: Vector3(-0.10, 0.45, 0.0),
				B_SPINE_LOW: Vector3(-0.05, 0.30, 0.0),
				B_L_UPPER_ARM: Vector3(0.3, 0.0, 0.25),
				B_HEAD: Vector3(0.05, -0.15, 0.0),
			}},
			{"t": 0.22, "root_y": -0.01, "bones": {
				B_R_UPPER_ARM: Vector3(0.9, 0.0, -0.2),
				B_CHEST: Vector3(0.0, 0.20, 0.0),
			}},
			{"t": 0.4, "root_y": 0.0, "bones": {
				B_R_UPPER_ARM: Vector3(0.5, 0.0, 0.0),
				B_CHEST: Vector3(0.0, 0.05, 0.0),
			}},
		],
	},
	&"attack_3": {
		# Overhead finisher — both arms, heavier. Contact at 0.14s.
		"length": 0.5,
		"loop": false,
		"keys": [
			{"t": 0.0, "root_y": 0.0, "bones": {}},
			{"t": 0.07, "root_y": 0.03, "bones": {
				B_R_UPPER_ARM: Vector3(2.6, 0.0, -0.2),
				B_L_UPPER_ARM: Vector3(2.6, 0.0, 0.2),
				B_R_ELBOW: Vector3(0.6, 0.0, 0.0),
				B_L_ELBOW: Vector3(0.6, 0.0, 0.0),
				B_CHEST: Vector3(-0.25, 0.0, 0.0),
				B_SPINE_LOW: Vector3(-0.15, 0.0, 0.0),
				B_HEAD: Vector3(-0.20, 0.0, 0.0),
			}},
			{"t": 0.14, "root_y": -0.06, "bones": {
				B_R_UPPER_ARM: Vector3(0.5, 0.0, -0.1),
				B_L_UPPER_ARM: Vector3(0.5, 0.0, 0.1),
				B_R_ELBOW: Vector3(0.1, 0.0, 0.0),
				B_L_ELBOW: Vector3(0.1, 0.0, 0.0),
				B_CHEST: Vector3(0.45, 0.0, 0.0),
				B_SPINE_LOW: Vector3(0.35, 0.0, 0.0),
				B_HEAD: Vector3(0.15, 0.0, 0.0),
				B_L_KNEE: Vector3(0.4, 0.0, 0.0),
				B_R_KNEE: Vector3(0.4, 0.0, 0.0),
			}},
			{"t": 0.3, "root_y": -0.04, "bones": {
				B_R_UPPER_ARM: Vector3(0.4, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(0.4, 0.0, 0.0),
				B_CHEST: Vector3(0.30, 0.0, 0.0),
			}},
			{"t": 0.5, "root_y": -0.01, "bones": {
				B_CHEST: Vector3(0.10, 0.0, 0.0),
			}},
		],
	},
	&"special": {
		# Wide two-hand sweep — bigger wind, wider follow. Contact at 0.22s.
		"length": 0.6,
		"loop": false,
		"keys": [
			{"t": 0.0, "root_y": -0.02, "bones": {
				B_SPINE_LOW: Vector3(0.10, 0.0, 0.0),
			}},
			{"t": 0.12, "root_y": 0.0, "bones": {
				B_CHEST: Vector3(-0.15, 0.70, 0.0),
				B_SPINE_LOW: Vector3(-0.10, 0.45, 0.0),
				B_R_UPPER_ARM: Vector3(1.8, 0.0, -0.5),
				B_L_UPPER_ARM: Vector3(0.6, 0.0, 0.4),
				B_HEAD: Vector3(0.0, -0.35, 0.0),
			}},
			{"t": 0.22, "root_y": -0.05, "bones": {
				B_CHEST: Vector3(0.20, -0.80, 0.0),
				B_SPINE_LOW: Vector3(0.15, -0.50, 0.0),
				B_R_UPPER_ARM: Vector3(0.8, 0.0, -0.7),
				B_L_UPPER_ARM: Vector3(-0.4, 0.0, 0.6),
				B_HEAD: Vector3(0.10, 0.30, 0.0),
				B_L_KNEE: Vector3(0.3, 0.0, 0.0),
				B_R_KNEE: Vector3(0.3, 0.0, 0.0),
			}},
			{"t": 0.42, "root_y": -0.03, "bones": {
				B_CHEST: Vector3(0.10, -0.40, 0.0),
				B_R_UPPER_ARM: Vector3(0.5, 0.0, -0.3),
			}},
			{"t": 0.6, "root_y": 0.0, "bones": {
				B_CHEST: Vector3(0.05, -0.10, 0.0),
			}},
		],
	},
	&"hit_react": {
		"length": 0.3,
		"loop": false,
		"keys": [
			{"t": 0.0, "root_y": 0.0, "bones": {}},
			{"t": 0.06, "root_y": -0.02, "bones": {
				B_SPINE_LOW: Vector3(-0.25, 0.0, 0.0),
				B_CHEST: Vector3(-0.15, 0.0, 0.05),
				B_HEAD: Vector3(-0.30, 0.0, 0.10),
				B_L_UPPER_ARM: Vector3(-0.3, 0.0, 0.5),
				B_R_UPPER_ARM: Vector3(-0.3, 0.0, -0.5),
			}},
			{"t": 0.3, "root_y": 0.0, "bones": {}},
		],
	},
	&"surge": {
		"length": 0.5,
		"loop": false,
		"keys": [
			{"t": 0.0, "root_y": -0.02, "bones": {
				B_SPINE_LOW: Vector3(0.1, 0.0, 0.0),
			}},
			{"t": 0.12, "root_y": 0.04, "bones": {
				B_CHEST: Vector3(-0.20, 0.0, 0.0),
				B_HEAD: Vector3(-0.25, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(-0.3, 0.0, 1.1),
				B_R_UPPER_ARM: Vector3(-0.3, 0.0, -1.1),
				B_L_ELBOW: Vector3(-0.2, 0.0, 0.0),
				B_R_ELBOW: Vector3(-0.2, 0.0, 0.0),
			}},
			{"t": 0.5, "root_y": 0.02, "bones": {
				B_CHEST: Vector3(-0.12, 0.0, 0.0),
				B_HEAD: Vector3(-0.15, 0.0, 0.0),
				B_L_UPPER_ARM: Vector3(-0.2, 0.0, 0.9),
				B_R_UPPER_ARM: Vector3(-0.2, 0.0, -0.9),
			}},
		],
	},
}

static func clip_for_state(state: int, is_moving: bool) -> StringName:
	match state:
		PlayerActionStateMachine.ActionState.DASH:
			return &"dash"
		PlayerActionStateMachine.ActionState.ATTACK, \
		PlayerActionStateMachine.ActionState.CAST:
			return &"attack_1"
		PlayerActionStateMachine.ActionState.SPECIAL:
			return &"special"
		PlayerActionStateMachine.ActionState.HITSTUN:
			return &"hit_react"
		PlayerActionStateMachine.ActionState.SURGE:
			return &"surge"
		_:
			return &"run" if is_moving else &"idle"

static func build_clip_library(skeleton: Skeleton3D) -> AnimationLibrary:
	var library := AnimationLibrary.new()
	var skeleton_track_prefix := "Skeleton3D:"
	for clip_name: StringName in CLIP_DATA:
		var data: Dictionary = CLIP_DATA[clip_name]
		var animation := Animation.new()
		animation.length = float(data["length"])
		animation.loop_mode = Animation.LOOP_LINEAR if bool(data["loop"]) else Animation.LOOP_NONE
		var keys: Array = data["keys"]

		var clip_bones := {}
		for key: Dictionary in keys:
			for bone_name: String in key["bones"]:
				clip_bones[bone_name] = true
		for bone_name: String in clip_bones:
			var bone_index := skeleton.find_bone(bone_name)
			if bone_index < 0:
				continue
			var rest_rotation := skeleton.get_bone_rest(bone_index).basis.get_rotation_quaternion()
			var track := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, skeleton_track_prefix + bone_name)
			for key: Dictionary in keys:
				var euler_delta: Vector3 = key["bones"].get(bone_name, Vector3.ZERO)
				var rotation := rest_rotation * Quaternion.from_euler(euler_delta)
				animation.rotation_track_insert_key(track, float(key["t"]), rotation)

		var root_index := skeleton.find_bone(B_ROOT)
		if root_index >= 0:
			var rest_origin := skeleton.get_bone_rest(root_index).origin
			var position_track := animation.add_track(Animation.TYPE_POSITION_3D)
			animation.track_set_path(position_track, skeleton_track_prefix + B_ROOT)
			for key: Dictionary in keys:
				var offset := Vector3(0.0, float(key.get("root_y", 0.0)), 0.0)
				animation.position_track_insert_key(position_track, float(key["t"]), rest_origin + offset)

		library.add_animation(clip_name, animation)
	return library

func _ready() -> void:
	_skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	if _skeleton == null:
		return
	_build_animation_player()
	_mount_weapon()
	_connect_retriggers()
	_play_clip(&"idle")

func _physics_process(delta: float) -> void:
	update_animation(delta)

func update_animation(delta: float) -> void:
	if animation_player == null:
		return
	var state := _action_state()
	var desired := clip_for_state(state, _is_moving())
	if state == PlayerActionStateMachine.ActionState.CAST and _library_has(&"spark_cast"):
		desired = &"spark_cast"
	# Personality fidget layer: only ever replaces unbroken idle; any gameplay
	# clip resets the timer.
	if desired == &"idle":
		if FIDGET_CLIPS.has(_current_clip) and animation_player.is_playing():
			animation_player.speed_scale = 1.0
			return  # let the fidget finish
		_idle_seconds += delta
		if _idle_seconds >= FIDGET_IDLE_SECONDS and _library_has(FIDGET_CLIPS[_next_fidget]):
			var fidget := FIDGET_CLIPS[_next_fidget]
			_next_fidget = (_next_fidget + 1) % FIDGET_CLIPS.size()
			_idle_seconds = 0.0
			_play_clip(fidget)
			return
	else:
		_idle_seconds = 0.0
	# Combo retriggers pick the exact swing variant; the state map only knows
	# "an attack is happening" — never let it restart a variant mid-swing.
	var both_attacks := String(desired).begins_with("attack_") and String(_current_clip).begins_with("attack_")
	if desired != _current_clip and not both_attacks:
		_play_clip(desired)
	animation_player.speed_scale = _speed_scale_for(desired)

func _build_animation_player() -> void:
	animation_player = AnimationPlayer.new()
	animation_player.name = "GizmoAnimationPlayer"
	var armature := _skeleton.get_parent()
	armature.add_child(animation_player)
	animation_player.add_animation_library(LIBRARY_NAME, _assemble_library())

func _assemble_library() -> AnimationLibrary:
	var library := build_clip_library(_skeleton)
	var external := _load_external_library()
	if external == null:
		return library
	for clip_name: StringName in CLIP_DATA:
		var source_name: StringName = clip_name
		if not external.has_animation(source_name):
			source_name = EXTERNAL_CLIP_ALIASES.get(clip_name, clip_name)
		if not external.has_animation(source_name):
			continue
		var animation: Animation = external.get_animation(source_name).duplicate(true)
		_remap_tracks_to_skeleton(animation)
		animation.loop_mode = library.get_animation(clip_name).loop_mode
		library.remove_animation(clip_name)
		library.add_animation(clip_name, animation)
		if clip_name == &"attack_1":
			_external_attack_grafted = true
	for clip_name: StringName in EXTERNAL_EXTRA_CLIPS:
		if not external.has_animation(clip_name):
			continue
		var animation: Animation = external.get_animation(clip_name).duplicate(true)
		_remap_tracks_to_skeleton(animation)
		animation.loop_mode = Animation.LOOP_LINEAR if bool(EXTERNAL_EXTRA_CLIPS[clip_name]) else Animation.LOOP_NONE
		library.add_animation(clip_name, animation)
	return library

func _library_has(clip_name: StringName) -> bool:
	if animation_player == null:
		return false
	var library := animation_player.get_animation_library(LIBRARY_NAME)
	return library != null and library.has_animation(clip_name)

func _load_external_library() -> AnimationLibrary:
	if not ResourceLoader.exists(EXTERNAL_CLIPS_PATH, "PackedScene"):
		return null
	var scene := load(EXTERNAL_CLIPS_PATH) as PackedScene
	if scene == null:
		return null
	var instance := scene.instantiate()
	var source := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if source == null:
		instance.free()
		return null
	var names := source.get_animation_library_list()
	if names.is_empty():
		instance.free()
		return null
	var library := source.get_animation_library(names[0]).duplicate(true) as AnimationLibrary
	instance.free()
	return library

func _remap_tracks_to_skeleton(animation: Animation) -> void:
	for track in animation.get_track_count():
		var path := String(animation.track_get_path(track))
		var bone_split := path.rsplit(":", true, 1)
		if bone_split.size() == 2:
			animation.track_set_path(track, "Skeleton3D:%s" % bone_split[1])

func _mount_weapon() -> void:
	var mount := BoneAttachment3D.new()
	mount.name = "WeaponMount"
	_skeleton.add_child(mount)
	mount.bone_name = EXTERNAL_WEAPON_BONE if _external_attack_grafted else RIGHT_HAND_BONE
	var weapon: Node3D = null
	if ResourceLoader.exists(WEAPON_SCENE_PATH, "PackedScene"):
		var weapon_scene := load(WEAPON_SCENE_PATH) as PackedScene
		if weapon_scene != null:
			weapon = weapon_scene.instantiate() as Node3D
	if weapon == null:
		weapon = _placeholder_weapon()
	mount.add_child(weapon)

func _connect_retriggers() -> void:
	var component := _ability_component()
	if component == null:
		return
	component.attack_started.connect(func(step: int, _damage: float) -> void: _play_clip(SwingTiming.melee_clip_name(step)))
	component.special_started.connect(func(_potency: float) -> void: _play_clip(&"special"))
	component.cast_started.connect(func(_potency: float) -> void:
		_play_clip(&"spark_cast" if _library_has(&"spark_cast") else &"attack_1"))
	component.dash_started.connect(func(_direction: Vector3, _speed: float, _duration: float) -> void: _play_clip(&"dash"))
	component.surge_started.connect(func(_damage: float, _radius: float, _stagger: float) -> void: _play_clip(&"surge"))

func _play_clip(clip_name: StringName) -> void:
	if animation_player == null:
		return
	_current_clip = clip_name
	animation_player.play("%s/%s" % [LIBRARY_NAME, clip_name], clip_blend_seconds)

func _speed_scale_for(clip_name: StringName) -> float:
	if clip_name != &"run":
		return 1.0
	var speed := _horizontal_velocity().length()
	return clampf(speed / maxf(run_speed_reference, 0.001), 0.6, 1.6) * RUN_EAGERNESS

func _action_state() -> int:
	var component := _ability_component()
	if component == null:
		return PlayerActionStateMachine.ActionState.IDLE
	return component.current_action_state()

func _is_moving() -> bool:
	return _horizontal_velocity().length() > moving_speed_threshold

func _horizontal_velocity() -> Vector3:
	var parent_node := get_parent()
	if parent_node is CharacterBody3D:
		var body := parent_node as CharacterBody3D
		return Vector3(body.velocity.x, 0.0, body.velocity.z)
	return Vector3.ZERO

func _ability_component() -> AbilityComponent:
	var parent_node := get_parent()
	if parent_node == null:
		return null
	return parent_node.get_node_or_null("AbilityComponent") as AbilityComponent

func _placeholder_weapon() -> Node3D:
	# Fallback so the swing always carries something visible while the promoted
	# brass_winding_wrench prop is absent (canon proof fallback: never stall).
	var weapon := Node3D.new()
	weapon.name = "PlaceholderWrench"
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.03
	handle_mesh.bottom_radius = 0.03
	handle_mesh.height = 0.5
	handle.mesh = handle_mesh
	handle.position = Vector3(0.0, 0.25, 0.0)
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.16, 0.12, 0.06)
	head.mesh = head_mesh
	head.position = Vector3(0.0, 0.5, 0.0)
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.72, 0.52, 0.25)
	brass.roughness = 0.7
	handle.material_override = brass
	head.material_override = brass
	weapon.add_child(handle)
	weapon.add_child(head)
	return weapon
