# Author Gizmo's animation clip set on the shipped 53-bone UniRig skeleton.
#
# Law (gizmo-asset-pipeline canon): the shipped godot/assets/gizmo.glb is never
# modified. This script imports it, authors clips on the imported skeleton
# copy, strips the mesh, and exports an ANIMATION-ONLY GLB to
# godot/assets/animations/gizmo_clips.glb. The runtime grafts that GLB's
# AnimationLibrary onto the live model (see scripts/player/gizmo_animator.gd).
#
# Usage:
#   blender --background --python tools/animation/author_gizmo_clips.py -- \
#       [--render-dir <dir>] [--no-export]
#
# Motion language ("gouache cosmos, brass soul"): handcrafted-mechanical —
# anticipation, snap, overshoot, settle. Antenna (Bone_016) is the
# follow-through voice. Never mocap-human-slick.
import math
import sys

import bpy
from mathutils import Quaternion, Vector

GLB_IN = "/home/ark/gizmo-hades/godot/assets/gizmo.glb"
GLB_OUT = "/home/ark/gizmo-hades/godot/assets/animations/gizmo_clips.glb"
FPS = 30

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
RENDER_DIR = argv[argv.index("--render-dir") + 1] if "--render-dir" in argv else ""
DO_EXPORT = "--no-export" not in argv

# ---------------------------------------------------------------- rig setup
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB_IN)
ARM = next(o for o in bpy.data.objects if o.type == "ARMATURE")
MESH = next(o for o in bpy.data.objects if o.type == "MESH")
SCENE = bpy.context.scene
SCENE.render.fps = FPS

# Semantic bone map (audited 2026-07-06; see docs/asset-lab/animation-ledger.md).
# Character faces -Y in Blender world space, +Z up. Right side = -X.
ROOT = "Bone_000"      # pelvis root (world bob lives here)
SPINE = "Bone_005"     # lower spine — whole-dome lean/twist
SPINE2 = "Bone_004"
NECK = "Bone_018"
HEAD = "Bone_017"
ANTENNA = "Bone_016"   # bobble antenna — follow-through/lag
R_CLAV, R_ARM, R_FORE, R_WRIST, R_HAND = "Bone_023", "Bone_022", "Bone_021", "Bone_020", "Bone_019"
L_CLAV, L_ARM, L_FORE, L_WRIST, L_HAND = "Bone_028", "Bone_027", "Bone_026", "Bone_025", "Bone_024"
R_THIGH, R_SHIN, R_FOOT = "Bone_010", "Bone_009", "Bone_008"
L_THIGH, L_SHIN, L_FOOT = "Bone_015", "Bone_014", "Bone_013"

# World-axis rotation conventions (empirically audited rest pose + verified
# against rendered stills 2026-07-06):
#   rot X negative  -> lean/swing FORWARD (toward -Y facing)
#   rot X positive  -> swing BACKWARD
#   arms hang down: rotX -150 ~= overhead raise, rotX +70 ~= windup behind
#   rot Z positive  -> twists right shoulder forward
# A raw +X world rotation tips DOWN-pointing bones (arms/legs) forward but
# UP-pointing bones (spine/head/antenna) backward; apply_pose() negates X for
# up-bones so the "negative = forward" convention holds for the whole rig.
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))

UP_BONES = {SPINE, SPINE2, NECK, HEAD, ANTENNA}

_LOCAL_CACHE = {}

def _bone_rest_inv(name):
    if name not in _LOCAL_CACHE:
        pb = ARM.pose.bones[name]
        _LOCAL_CACHE[name] = pb.bone.matrix_local.to_3x3().inverted()
    return _LOCAL_CACHE[name]

def rot(name, axis_world, deg):
    """Quaternion rotating pose bone `name` about a WORLD axis by degrees."""
    axis_local = (_bone_rest_inv(name) @ axis_world).normalized()
    return Quaternion(axis_local, math.radians(deg))

def apply_pose(pose, frame):
    """pose: {bone: [(axis, deg), ...]} plus optional 'ROOT_Z': float world lift."""
    keyed = set()
    for name, spins in pose.items():
        if name == "ROOT_Z":
            pb = ARM.pose.bones[ROOT]
            pb.location = _bone_rest_inv(ROOT) @ Vector((0, 0, spins))
            pb.keyframe_insert("location", frame=frame)
            continue
        pb = ARM.pose.bones[name]
        q = Quaternion()
        up_bone = name in UP_BONES
        for axis, deg in spins:
            if up_bone and axis is X:
                deg = -deg
            q = rot(name, axis, deg) @ q
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        keyed.add(name)
    return keyed

def author_clip(name, keys, loop=False):
    """keys: list of (time_seconds, pose_dict). All bones used anywhere in the
    clip are keyed at every keyframe (unspecified = rest) so poses never bleed."""
    ARM.animation_data_create()
    action = bpy.data.actions.new(name)
    ARM.animation_data.action = action

    all_bones = set()
    for _, pose in keys:
        all_bones.update(k for k in pose if k != "ROOT_Z")
    uses_root = any("ROOT_Z" in pose for _, pose in keys)

    for t, pose in keys:
        frame = 1 + round(t * FPS)
        full = {b: pose.get(b, []) for b in all_bones}
        if uses_root:
            full["ROOT_Z"] = pose.get("ROOT_Z", 0.0)
        apply_pose(full, frame)

    if loop:  # enforce seamless loop: last key must equal first
        first_t, first_pose = keys[0]
        last_t = keys[-1][0]
        if keys[-1][1] is not first_pose:
            frame = 1 + round(last_t * FPS)
            full = {b: first_pose.get(b, []) for b in all_bones}
            if uses_root:
                full["ROOT_Z"] = first_pose.get("ROOT_Z", 0.0)
            apply_pose(full, frame)

    # Push to an NLA track named after the clip so the exporter emits one
    # glTF animation per track.
    ARM.animation_data.action = None
    track = ARM.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 1, action)
    return action

R = lambda deg: [(X, deg)]           # pitch (fwd negative)
BANK = lambda deg: [(Y, deg)]        # roll about forward axis
TWIST = lambda deg: [(Z, deg)]       # yaw twist

# ------------------------------------------------------------------- clips
# IDLE — 2.0s breathing-machine loop; vulnerable living-light stillness.
idle_a = {SPINE: R(1.5), ANTENNA: R(4), R_ARM: R(2), L_ARM: R(-2), HEAD: TWIST(2), "ROOT_Z": -0.008}
idle_b = {SPINE: R(-0.5), ANTENNA: R(-4), R_ARM: R(-2), L_ARM: R(2), HEAD: TWIST(-2), "ROOT_Z": 0.0}
author_clip("idle", [
    (0.0, {}),
    (0.5, idle_a),
    (1.0, {SPINE: R(2.0), "ROOT_Z": -0.012, ANTENNA: R(0)}),
    (1.5, idle_b),
    (2.0, {}),
], loop=True)

# RUN — 0.533s eager clanky patter (frames land on exact 30fps ticks; stays
# under the 0.6s "quick patter" cadence bar even with the exporter's one-frame
# sampling pad).
def run_contact(right_leads):
    s = 1 if right_leads else -1
    return {
        R_THIGH: R(-28 * s), R_SHIN: R(12 if right_leads else 40),
        L_THIGH: R(28 * s), L_SHIN: R(40 if right_leads else 12),
        R_ARM: R(24 * s), L_ARM: R(-24 * s),
        SPINE: R(-8) + BANK(3 * s),
        ANTENNA: R(12),
        HEAD: R(2),
        "ROOT_Z": -0.020,
    }

def run_pass(right_planted):
    s = 1 if right_planted else -1
    return {
        R_THIGH: R(-6 * s), R_SHIN: R(10 if right_planted else 55),
        L_THIGH: R(6 * s), L_SHIN: R(55 if right_planted else 10),
        R_ARM: R(6 * s), L_ARM: R(-6 * s),
        SPINE: R(-9),
        ANTENNA: R(16),
        HEAD: R(2),
        "ROOT_Z": 0.022,
    }

author_clip("run", [
    (0.0000, run_contact(True)),
    (0.1333, run_pass(True)),
    (0.2667, run_contact(False)),
    (0.4000, run_pass(False)),
    (0.5333, run_contact(True)),
], loop=True)

# ATTACK — 0.4s wrench swing: big anticipation, snap strike, overshoot, settle.
# Swings the Bone_023->019 arm chain: gizmo_animation_controller.gd mounts the
# wrench on Bone_019 when these authored clips graft (EXTERNAL_WEAPON_BONE), so
# the weapon rides the swinging hand. Keep clip arm and mount bone in lockstep.
author_clip("attack", [
    (0.00, {}),
    (0.10, {  # windup: weapon arm cocked back+up, torso twisted away
        R_ARM: R(70) + BANK(-15), R_FORE: R(20), R_CLAV: R(10),
        SPINE: TWIST(-16) + R(4), HEAD: TWIST(10),
        L_ARM: R(-12), ANTENNA: R(14), "ROOT_Z": 0.006,
    }),
    (0.18, {  # strike: full-body snap forward
        R_ARM: R(-85), R_FORE: R(-12), R_WRIST: R(-18), R_CLAV: R(-8),
        SPINE: TWIST(20) + R(-12), HEAD: TWIST(-8),
        L_ARM: R(18), ANTENNA: R(-18),
        R_THIGH: R(-10), L_THIGH: R(8), "ROOT_Z": -0.020,
    }),
    (0.26, {  # follow-through overshoot
        R_ARM: R(-98), R_FORE: R(-8), R_WRIST: R(-24),
        SPINE: TWIST(24) + R(-14), HEAD: TWIST(-10),
        L_ARM: R(22), ANTENNA: R(-26),
        R_THIGH: R(-10), L_THIGH: R(8), "ROOT_Z": -0.024,
    }),
    (0.40, {}),  # mechanical settle back to rest
])

# SPECIAL — 0.7s two-hand overhead slam: rise, hang, crash, crouch, recover.
author_clip("special", [
    (0.00, {}),
    (0.20, {  # raise both arms overhead, chest proud
        R_ARM: R(-150), L_ARM: R(-150), R_FORE: R(-15), L_FORE: R(-15),
        SPINE: R(10), HEAD: R(6), ANTENNA: R(18), "ROOT_Z": 0.020,
    }),
    (0.32, {  # apex hang (anticipation beat)
        R_ARM: R(-160), L_ARM: R(-160), R_FORE: R(-18), L_FORE: R(-18),
        SPINE: R(12), HEAD: R(8), ANTENNA: R(24), "ROOT_Z": 0.026,
    }),
    (0.42, {  # slam: arms crash down, body crouches into it
        R_ARM: R(-20), L_ARM: R(-20), R_FORE: R(12), L_FORE: R(12),
        SPINE: R(-24), HEAD: R(-10), ANTENNA: R(-30),
        R_THIGH: R(-24), L_THIGH: R(-24), R_SHIN: R(36), L_SHIN: R(36),
        "ROOT_Z": -0.095,
    }),
    (0.50, {  # overshoot: sink a hair deeper, antenna whips
        R_ARM: R(-8), L_ARM: R(-8),
        SPINE: R(-27), HEAD: R(-12), ANTENNA: R(-38),
        R_THIGH: R(-26), L_THIGH: R(-26), R_SHIN: R(40), L_SHIN: R(40),
        "ROOT_Z": -0.110,
    }),
    (0.70, {}),
])

# DASH — 0.3s forward lunge: instant lean, arms swept back, split stance.
dash_hold = {
    SPINE: R(-22), HEAD: R(6),
    R_ARM: R(38) + BANK(-6), L_ARM: R(38) + BANK(6),
    R_THIGH: R(-22), R_SHIN: R(8),
    L_THIGH: R(24), L_SHIN: R(34),
    ANTENNA: R(22), "ROOT_Z": -0.030,
}
author_clip("dash", [
    (0.00, {}),
    (0.06, dash_hold),
    (0.24, dash_hold),
    (0.30, {}),
])

# HIT — 0.25s recoil: head/torso snap back, antenna whips forward, fast settle.
author_clip("hit", [
    (0.00, {}),
    (0.06, {
        SPINE: R(15), HEAD: R(11), ANTENNA: R(-28),
        R_ARM: R(-16), L_ARM: R(-16), "ROOT_Z": -0.012,
    }),
    (0.14, {
        SPINE: R(6), HEAD: R(3), ANTENNA: R(10),
        R_ARM: R(-4), L_ARM: R(-4), "ROOT_Z": -0.004,
    }),
    (0.25, {}),
])

# DEATH — 1.2s power-down crumple; final pose holds (one-shot, no return key).
author_clip("death", [
    (0.00, {}),
    (0.15, {SPINE: R(10), ANTENNA: R(-20), HEAD: R(4), "ROOT_Z": -0.010}),
    (0.45, {  # the sag — spark failing
        SPINE: R(-15), HEAD: R(-10), ANTENNA: R(-10),
        R_ARM: R(-6), L_ARM: R(-6),
        R_THIGH: R(-20), L_THIGH: R(-20), R_SHIN: R(30), L_SHIN: R(30),
        "ROOT_Z": -0.055,
    }),
    (0.80, {  # collapse to knees
        SPINE: R(-35), HEAD: R(-22), ANTENNA: R(-35),
        R_ARM: R(-10), L_ARM: R(-10),
        R_THIGH: R(-60), L_THIGH: R(-60), R_SHIN: R(78), L_SHIN: R(78),
        "ROOT_Z": -0.300,
    }),
    (1.20, {  # final slump — held
        SPINE: R(-46), HEAD: R(-28), ANTENNA: R(-46),
        R_ARM: R(-12), L_ARM: R(-12),
        R_THIGH: R(-64), L_THIGH: R(-64), R_SHIN: R(82), L_SHIN: R(82),
        "ROOT_Z": -0.340,
    }),
])

# VICTORY — 1.6s rekindle: arms thrown skyward with overshoot, proud hold.
author_clip("victory", [
    (0.00, {}),
    (0.30, {
        R_ARM: R(-140), L_ARM: R(-140), SPINE: R(8), HEAD: R(8),
        ANTENNA: R(12), "ROOT_Z": 0.020,
    }),
    (0.45, {  # overshoot past the pose
        R_ARM: R(-156), L_ARM: R(-156), SPINE: R(11), HEAD: R(10),
        ANTENNA: R(-14), "ROOT_Z": 0.030,
    }),
    (0.60, {
        R_ARM: R(-146), L_ARM: R(-146), SPINE: R(9), HEAD: R(9),
        ANTENNA: R(8), "ROOT_Z": 0.024,
    }),
    (1.20, {
        R_ARM: R(-146), L_ARM: R(-146), SPINE: R(9), HEAD: R(9),
        ANTENNA: R(-6), "ROOT_Z": 0.024,
    }),
    (1.60, {
        R_ARM: R(-146), L_ARM: R(-146), SPINE: R(9), HEAD: R(9),
        ANTENNA: R(0), "ROOT_Z": 0.024,
    }),
])

print("AUTHORED CLIPS:", [t.name for t in ARM.animation_data.nla_tracks])

# ------------------------------------------------------- render validation
if RENDER_DIR:
    SCENE.render.engine = "BLENDER_WORKBENCH"
    SCENE.display.shading.light = "STUDIO"
    SCENE.display.shading.color_type = "TEXTURE"
    SCENE.render.resolution_x = 512
    SCENE.render.resolution_y = 512
    cam_data = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_data)
    SCENE.collection.objects.link(cam)
    SCENE.camera = cam
    center = Vector((0, 0, 1.0))
    cam.location = center + Vector((1.6, -3.4, 3.2))  # front-right high, Diablo-ish
    direction = center - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()

    shots = [("idle", 1.0), ("run", 0.0), ("run", 0.15), ("attack", 0.10),
             ("attack", 0.18), ("special", 0.32), ("special", 0.5),
             ("dash", 0.12), ("hit", 0.06), ("death", 1.2), ("victory", 0.45)]
    for track in ARM.animation_data.nla_tracks:
        track.mute = True
    for clip, t in shots:
        for track in ARM.animation_data.nla_tracks:
            track.mute = track.name != clip
        SCENE.frame_set(1 + round(t * FPS))
        SCENE.render.filepath = f"{RENDER_DIR}/{clip}_{int(t * 1000):04d}ms.png"
        bpy.ops.render.render(write_still=True)
        print("WROTE", SCENE.render.filepath)
    for track in ARM.animation_data.nla_tracks:
        track.mute = False

# ------------------------------------------------------------------ export
if DO_EXPORT:
    # Animation-only GLB: strip the mesh, keep the armature + NLA tracks.
    bpy.data.objects.remove(MESH, do_unlink=True)
    bpy.ops.export_scene.gltf(
        filepath=GLB_OUT,
        export_format="GLB",
        export_animations=True,
        export_animation_mode="NLA_TRACKS",
        export_force_sampling=True,
        export_optimize_animation_size=False,
        export_yup=True,
    )
    print("EXPORTED", GLB_OUT)
print("AUTHOR OK")
