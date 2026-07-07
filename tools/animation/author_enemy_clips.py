# Author enemy clip sets on the Meshy-rigged bruiser/elite skeletons (24-bone
# standard humanoid: Hips/Spine/Spine01/Spine02/neck/Head + limbs).
#
# Route (docs/asset-lab/animation-ledger.md, enemy lane 2026-07-06): meshy_rig
# produced the skeleton + free walk/run clips; custom clips are hand-keyed here
# (zero credits — meshy_animate action ids are uncatalogued and no-retry-spend
# forbids blind guesses). Output is ONE GLB per archetype carrying mesh + rig +
# the full clip contract; enemy_animation_controller.gd guarantees any clip a
# reimport loses with code-built poses (two-tier idiom, as gizmo_animation_controller).
#
# Usage:
#   blender --background --python tools/animation/author_enemy_clips.py -- \
#       --src-dir <dir with {name}_rigged.glb,{name}_walking.glb,{name}_running.glb> \
#       [--only bruiser|elite] [--render-dir <dir>] [--no-export]
#
# Movement thesis (hyperscalers): frictionless, economical, WRONG — no wasted
# motion because nothing in them feels. Telegraphs are slow and total; strikes
# are instant; deaths are power-cuts, not agony.
import math
import sys

import bpy
from mathutils import Quaternion, Vector

FPS = 30

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def _arg(flag, default=""):
    return argv[argv.index(flag) + 1] if flag in argv else default


SRC_DIR = _arg("--src-dir")
ONLY = _arg("--only")
RENDER_DIR = _arg("--render-dir")
DO_EXPORT = "--no-export" not in argv

# Meshy 24-bone rig, shared by both archetypes (audited 2026-07-06).
HIPS = "Hips"
SPINE, SPINE1, SPINE2 = "Spine", "Spine01", "Spine02"
NECK, HEAD = "neck", "Head"
R_SHOULDER, R_ARM, R_FORE, R_HAND = "RightShoulder", "RightArm", "RightForeArm", "RightHand"
L_SHOULDER, L_ARM, L_FORE, L_HAND = "LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand"
R_THIGH, R_SHIN, R_FOOT = "RightUpLeg", "RightLeg", "RightFoot"
L_THIGH, L_SHIN, L_FOOT = "LeftUpLeg", "LeftLeg", "LeftFoot"

X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
UP_BONES = {SPINE, SPINE1, SPINE2, NECK, HEAD}

R = lambda deg: [(X, deg)]      # pitch about world X (sign audited per pose render)
BANK = lambda deg: [(Y, deg)]   # roll
TWIST = lambda deg: [(Z, deg)]  # yaw

ARM = None
_LOCAL_CACHE = {}


def _bone_rest_inv(name):
    if name not in _LOCAL_CACHE:
        _LOCAL_CACHE[name] = ARM.pose.bones[name].bone.matrix_local.to_3x3().inverted()
    return _LOCAL_CACHE[name]


def rot(name, axis_world, deg):
    axis_local = (_bone_rest_inv(name) @ axis_world).normalized()
    return Quaternion(axis_local, math.radians(deg))


def apply_pose(pose, frame):
    for name, spins in pose.items():
        if name == "HIPS_Z":
            pb = ARM.pose.bones[HIPS]
            pb.location = _bone_rest_inv(HIPS) @ Vector((0, 0, spins))
            pb.keyframe_insert("location", frame=frame)
            continue
        pb = ARM.pose.bones.get(name)
        if pb is None:
            continue
        q = Quaternion()
        up_bone = name in UP_BONES
        for axis, deg in spins:
            if up_bone and axis is X:
                deg = -deg
            q = rot(name, axis, deg) @ q
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=frame)


def author_clip(name, keys, loop=False):
    ARM.animation_data_create()
    action = bpy.data.actions.new(name)
    ARM.animation_data.action = action

    all_bones = set()
    for _, pose in keys:
        all_bones.update(k for k in pose if k != "HIPS_Z")
    uses_root = any("HIPS_Z" in pose for _, pose in keys)

    def key_at(t, pose):
        frame = 1 + round(t * FPS)
        full = {b: pose.get(b, []) for b in all_bones}
        if uses_root:
            full["HIPS_Z"] = pose.get("HIPS_Z", 0.0)
        apply_pose(full, frame)

    for t, pose in keys:
        key_at(t, pose)
    if loop and keys[-1][1] is not keys[0][1]:
        key_at(keys[-1][0], keys[0][1])

    ARM.animation_data.action = None
    track = ARM.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 1, action)
    return action


def steal_locomotion(glb_path, clip_name):
    """Import a Meshy withSkin animation GLB and re-home its action onto ARM
    as an NLA track (identical skeleton, so tracks map 1:1 by bone name)."""
    before_objects = set(bpy.data.objects)
    before_actions = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=glb_path)
    new_actions = [a for a in bpy.data.actions if a not in before_actions]
    action = new_actions[0]
    action.name = clip_name
    ARM.animation_data_create()
    track = ARM.animation_data.nla_tracks.new()
    track.name = clip_name
    track.strips.new(clip_name, 1, action)
    for obj in set(bpy.data.objects) - before_objects:
        bpy.data.objects.remove(obj, do_unlink=True)


# ---------------------------------------------------------------- clip sets
def author_bruiser():
    """Heavy line-breaker. Weight is the read: total slow telegraph, one
    instant smash, a timber-fall death."""
    author_clip("idle", [  # near-still mass; one slow mechanical weight shift
        (0.0, {}),
        (1.0, {SPINE1: R(2) + BANK(1.5), R_ARM: R(2), L_ARM: R(-2), HEAD: R(-2), "HIPS_Z": -0.015}),
        (2.0, {}),
    ], loop=True)

    # attack: brain windup 0.85s (damage lands at 0.85), then held recovery.
    author_clip("attack", [
        (0.00, {}),
        (0.60, {  # both arms grind overhead — slow, total, unmistakable
            R_ARM: R(-155), L_ARM: R(-155), R_FORE: R(-12), L_FORE: R(-12),
            SPINE1: R(10), SPINE2: R(6), HEAD: R(8), "HIPS_Z": 0.05,
        }),
        (0.82, {  # apex hang: the frozen beat before it falls
            R_ARM: R(-165), L_ARM: R(-165), R_FORE: R(-15), L_FORE: R(-15),
            SPINE1: R(13), SPINE2: R(8), HEAD: R(9), "HIPS_Z": 0.07,
        }),
        (0.92, {  # smash: instant, whole mass drops into it
            R_ARM: R(-25), L_ARM: R(-25), R_FORE: R(18), L_FORE: R(18),
            SPINE1: R(-26), SPINE2: R(-12), HEAD: R(-10),
            R_THIGH: R(-22), L_THIGH: R(-22), R_SHIN: R(32), L_SHIN: R(32),
            "HIPS_Z": -0.16,
        }),
        (1.25, {  # ground hold — recovery starts here (brain: 1.85s)
            R_ARM: R(-18), L_ARM: R(-18), R_FORE: R(14), L_FORE: R(14),
            SPINE1: R(-18), SPINE2: R(-8), HEAD: R(-6),
            R_THIGH: R(-16), L_THIGH: R(-16), R_SHIN: R(24), L_SHIN: R(24),
            "HIPS_Z": -0.10,
        }),
    ])

    author_clip("hit", [  # barely registers — mass absorbs it
        (0.00, {}),
        (0.07, {SPINE1: R(5), SPINE2: R(3), HEAD: R(4), "HIPS_Z": -0.01}),
        (0.25, {}),
    ])

    author_clip("death", [  # timber: knees buckle, mass pitches forward, held
        (0.00, {}),
        (0.20, {SPINE1: R(6), HEAD: R(5), "HIPS_Z": -0.04}),
        (0.55, {
            SPINE1: R(-30), SPINE2: R(-14), HEAD: R(-18),
            R_ARM: R(-15), L_ARM: R(-15),
            R_THIGH: R(-45), L_THIGH: R(-45), R_SHIN: R(60), L_SHIN: R(60),
            "HIPS_Z": -0.55,
        }),
        (0.90, {
            SPINE1: R(-52), SPINE2: R(-22), HEAD: R(-26),
            R_ARM: R(-20), L_ARM: R(-20),
            R_THIGH: R(-70), L_THIGH: R(-70), R_SHIN: R(85), L_SHIN: R(85),
            "HIPS_Z": -0.95,
        }),
    ])


def author_elite():
    """The thesis made flesh: frictionless, economical, wrong. It never
    hurries, never flourishes, never suffers."""
    author_clip("idle", [  # dead-still stance; only the head surveys
        (0.0, {}),
        (0.9, {HEAD: TWIST(14), NECK: TWIST(6)}),
        (1.5, {HEAD: TWIST(14), NECK: TWIST(6)}),  # hold the look — locked on
        (2.4, {HEAD: TWIST(-12), NECK: TWIST(-5)}),
        (3.0, {}),
    ], loop=True)

    # attack: brain windup 1.05s. Blade arm rises with machine patience,
    # then one instant thrust. No follow-through — economical.
    author_clip("attack", [
        (0.00, {}),
        (0.85, {
            R_ARM: R(-95) + BANK(-10), R_FORE: R(-25),
            SPINE1: TWIST(-10), HEAD: R(4), "HIPS_Z": 0.02,
        }),
        (1.02, {  # frozen apex — the wrongness is the stillness
            R_ARM: R(-100) + BANK(-10), R_FORE: R(-28),
            SPINE1: TWIST(-12), HEAD: R(4), "HIPS_Z": 0.02,
        }),
        (1.10, {  # thrust: single frame of violence
            R_ARM: R(-35), R_FORE: R(8), R_HAND: R(-10),
            SPINE1: TWIST(16) + R(-8), HEAD: R(-3),
            R_THIGH: R(-8), L_THIGH: R(6), "HIPS_Z": -0.04,
        }),
        (1.35, {  # already recomposed — no settle wobble
            R_ARM: R(-12), SPINE1: TWIST(4), "HIPS_Z": 0.0,
        }),
    ])

    author_clip("hit", [  # a tick of the head; nothing in it feels
        (0.00, {}),
        (0.05, {HEAD: R(4) + TWIST(-5), NECK: R(2)}),
        (0.20, {}),
    ])

    author_clip("death", [  # power-cut: fold straight down, then hard list
        (0.00, {}),
        (0.12, {HEAD: R(-6), "HIPS_Z": -0.08}),
        (0.40, {  # vertical collapse, torso eerily level
            R_THIGH: R(-70), L_THIGH: R(-70), R_SHIN: R(95), L_SHIN: R(95),
            SPINE1: R(-6), HEAD: R(-10), R_ARM: R(-8), L_ARM: R(-8),
            "HIPS_Z": -1.05,
        }),
        (0.80, {  # the list — a machine tipped off its axis, held
            R_THIGH: R(-75), L_THIGH: R(-75), R_SHIN: R(100), L_SHIN: R(100),
            SPINE1: R(-10) + BANK(28), SPINE2: BANK(10), HEAD: R(-12) + BANK(8),
            R_ARM: R(-10), L_ARM: R(-12),
            "HIPS_Z": -1.20,
        }),
    ])


ARCHETYPES = {
    "bruiser": {"stem": "bruiser", "author": author_bruiser,
                "out": "/home/ark/gizmo-hades/godot/assets/enemies/bruiser_unit_rigged.glb"},
    "elite": {"stem": "elite", "author": author_elite,
              "out": "/home/ark/gizmo-hades/godot/assets/enemies/elite_enforcer_rigged.glb"},
}

RENDER_SHOTS = {
    "bruiser": [("idle", 1.0), ("walk", 0.4), ("attack", 0.82), ("attack", 0.92),
                ("hit", 0.07), ("death", 0.9)],
    "elite": [("idle", 0.9), ("walk", 0.4), ("attack", 1.02), ("attack", 1.10),
              ("hit", 0.05), ("death", 0.8)],
}

for key, spec in ARCHETYPES.items():
    if ONLY and key != ONLY:
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    stem = spec["stem"]
    rigged = f"{SRC_DIR}/{stem}_rigged/{ARCHETYPES[key]['out'].rsplit('/', 1)[1]}"
    bpy.ops.import_scene.gltf(filepath=rigged)
    # Meshy ships a stray Icosphere alongside the character — strip it.
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and "char" not in obj.name.lower():
            bpy.data.objects.remove(obj, do_unlink=True)
    ARM = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    _LOCAL_CACHE = {}
    bpy.context.scene.render.fps = FPS

    # Free Meshy locomotion first (RIG BEFORE AUTHORING is satisfied: the rig
    # op already happened upstream; these carry no hand-keyed tracks to lose).
    steal_locomotion(f"{SRC_DIR}/{stem}_rigged/{stem}_walking.glb", "walk")
    steal_locomotion(f"{SRC_DIR}/{stem}_rigged/{stem}_running.glb", "run")
    spec["author"]()
    # The rigged GLB ships its own bind/baselayer action as an NLA track —
    # drop everything that isn't part of the clip contract.
    contract = {"walk", "run", "idle", "attack", "hit", "death"}
    for track in list(ARM.animation_data.nla_tracks):
        if track.name not in contract:
            ARM.animation_data.nla_tracks.remove(track)
    print(f"AUTHORED {key}:", [t.name for t in ARM.animation_data.nla_tracks])

    if RENDER_DIR:
        scene = bpy.context.scene
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.color_type = "TEXTURE"
        scene.render.resolution_x = 512
        scene.render.resolution_y = 512
        cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
        scene.collection.objects.link(cam)
        scene.camera = cam
        height = max((o.dimensions.z for o in bpy.data.objects if o.type == "MESH"), default=2.0)
        center = Vector((0, 0, height * 0.45))
        cam.location = center + Vector((2.2, -4.6, 4.4))  # Diablo-ish angle
        cam.rotation_euler = (center - cam.location).to_track_quat("-Z", "Y").to_euler()
        for clip, t in RENDER_SHOTS[key]:
            for track in ARM.animation_data.nla_tracks:
                track.mute = track.name != clip
            scene.frame_set(1 + round(t * FPS))
            scene.render.filepath = f"{RENDER_DIR}/{key}_{clip}_{int(t * 1000):04d}ms.png"
            bpy.ops.render.render(write_still=True)
            print("WROTE", scene.render.filepath)
        for track in ARM.animation_data.nla_tracks:
            track.mute = False
        bpy.data.objects.remove(cam, do_unlink=True)

    if DO_EXPORT:
        bpy.ops.export_scene.gltf(
            filepath=spec["out"],
            export_format="GLB",
            export_animations=True,
            export_animation_mode="NLA_TRACKS",
            export_force_sampling=True,
            export_optimize_animation_size=False,
            export_yup=True,
        )
        print("EXPORTED", spec["out"])

print("AUTHOR OK")
