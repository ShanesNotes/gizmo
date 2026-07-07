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
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

# 60fps keeps both code-owned attack windups exact on integer frames:
# bruiser 0.85s -> 51f, elite 1.05s -> 63f.
FPS = 60
BRUISER_STRIKE = 0.85
ELITE_STRIKE = 1.05

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def _arg(flag, default=""):
    return argv[argv.index(flag) + 1] if flag in argv else default


SRC_DIR = Path(_arg("--src-dir") or ".")
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
        frame = 1.0 + t * FPS
        full = {b: pose.get(b, []) for b in all_bones}
        if uses_root:
            full["HIPS_Z"] = pose.get("HIPS_Z", 0.0)
        apply_pose(full, frame)

    for t, pose in keys:
        key_at(t, pose)
    if loop and keys[-1][1] is not keys[0][1]:
        key_at(keys[-1][0], keys[0][1])

    for curve in getattr(action, "fcurves", []):
        for keyframe in curve.keyframe_points:
            keyframe.interpolation = "LINEAR"

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


def first_existing(candidates):
    for candidate in candidates:
        if candidate.exists():
            return candidate
    return None


def resolve_rigged(spec):
    rigged = first_existing([
        SRC_DIR / spec["rigged"],
        SRC_DIR / f"{spec['short']}_rigged" / spec["rigged"],
    ])
    if rigged is None:
        raise FileNotFoundError(f"missing rigged source for {spec['short']}: {spec['rigged']}")
    return rigged


def resolve_locomotion(spec, motion):
    return first_existing([
        SRC_DIR / f"{spec['stem']}_{motion}.glb",
        SRC_DIR / f"{spec['short']}_{motion}.glb",
        SRC_DIR / f"{spec['short']}_rigged" / f"{spec['short']}_{motion}.glb",
        SRC_DIR / f"{spec['short']}_rigged" / f"{spec['stem']}_{motion}.glb",
    ])


def set_clip_time(scene, t):
    frame = 1.0 + t * FPS
    whole = math.floor(frame)
    scene.frame_set(whole, subframe=frame - whole)


def author_bruiser_locomotion(clip_name):
    if clip_name == "walk":
        author_clip("walk", [  # heavy deliberate in-place lumber
            (0.00, {SPINE1: R(-5), R_ARM: R(-12), L_ARM: R(8),
                    R_THIGH: R(10), R_SHIN: R(-8), L_THIGH: R(-16), L_SHIN: R(18),
                    "HIPS_Z": -0.04}),
            (0.50, {SPINE1: R(-7), R_ARM: R(8), L_ARM: R(-12),
                    R_THIGH: R(-16), R_SHIN: R(18), L_THIGH: R(10), L_SHIN: R(-8),
                    "HIPS_Z": -0.08}),
            (1.00, {SPINE1: R(-5), R_ARM: R(-12), L_ARM: R(8),
                    R_THIGH: R(10), R_SHIN: R(-8), L_THIGH: R(-16), L_SHIN: R(18),
                    "HIPS_Z": -0.04}),
        ], loop=True)
        return
    author_clip("run", [  # not athletic; over-torqued forced march
        (0.00, {SPINE1: R(-9), SPINE2: R(-3), R_ARM: R(-18), L_ARM: R(12),
                R_THIGH: R(16), R_SHIN: R(-12), L_THIGH: R(-24), L_SHIN: R(28),
                "HIPS_Z": -0.07}),
        (0.36, {SPINE1: R(-11), SPINE2: R(-4), R_ARM: R(12), L_ARM: R(-18),
                R_THIGH: R(-24), R_SHIN: R(28), L_THIGH: R(16), L_SHIN: R(-12),
                "HIPS_Z": -0.12}),
        (0.72, {SPINE1: R(-9), SPINE2: R(-3), R_ARM: R(-18), L_ARM: R(12),
                R_THIGH: R(16), R_SHIN: R(-12), L_THIGH: R(-24), L_SHIN: R(28),
                "HIPS_Z": -0.07}),
    ], loop=True)


def author_elite_locomotion(clip_name):
    duration = 1.20 if clip_name == "walk" else 0.90
    lean = -2 if clip_name == "walk" else -5
    author_clip(clip_name, [  # glide loop: legs imply balance correction, not steps
        (0.00, {SPINE1: R(lean), HEAD: TWIST(3), R_ARM: R(-4), L_ARM: R(-4),
                R_THIGH: R(-3), L_THIGH: R(3), "HIPS_Z": 0.010}),
        (duration * 0.50, {SPINE1: R(lean) + BANK(1.5), HEAD: TWIST(-3),
                           R_ARM: R(-5), L_ARM: R(-5),
                           R_THIGH: R(3), L_THIGH: R(-3), "HIPS_Z": 0.025}),
        (duration, {SPINE1: R(lean), HEAD: TWIST(3), R_ARM: R(-4), L_ARM: R(-4),
                    R_THIGH: R(-3), L_THIGH: R(3), "HIPS_Z": 0.010}),
    ], loop=True)


def add_locomotion(spec):
    missing = []
    for clip_name, motion in (("walk", "walking"), ("run", "running")):
        source = resolve_locomotion(spec, motion)
        if source:
            steal_locomotion(str(source), clip_name)
            continue
        spec["fallback_locomotion"](clip_name)
        missing.append(motion)
    if missing:
        print(f"FALLBACK {spec['short']} locomotion:", ", ".join(missing))


# ---------------------------------------------------------------- clip sets
def author_bruiser():
    """Heavy line-breaker. Weight is the read: total slow telegraph, one
    instant smash, a timber-fall death."""
    author_clip("idle", [  # near-still mass; one slow mechanical weight shift
        (0.0, {}),
        (1.0, {SPINE1: R(2) + BANK(1.5), R_ARM: R(2), L_ARM: R(-2), HEAD: R(-2), "HIPS_Z": -0.015}),
        (2.0, {}),
    ], loop=True)

    # attack: brain windup 0.85s (damage lands exactly at BRUISER_STRIKE).
    author_clip("attack", [
        (0.00, {}),
        (0.58, {  # both arms grind overhead — slow, total, unmistakable
            R_ARM: R(-150), L_ARM: R(-150), R_FORE: R(-10), L_FORE: R(-10),
            SPINE1: R(9), SPINE2: R(5), HEAD: R(7), "HIPS_Z": 0.045,
        }),
        (0.84, {  # apex hang: the frozen beat before it falls
            R_ARM: R(-168), L_ARM: R(-168), R_FORE: R(-18), L_FORE: R(-18),
            SPINE1: R(14), SPINE2: R(9), HEAD: R(10), "HIPS_Z": 0.075,
        }),
        (BRUISER_STRIKE, {  # STRIKE: one-frame power-drop at the brain windup
            R_ARM: R(-24), L_ARM: R(-24), R_FORE: R(20), L_FORE: R(20),
            SPINE1: R(-30), SPINE2: R(-14), HEAD: R(-12),
            R_THIGH: R(-26), L_THIGH: R(-26), R_SHIN: R(36), L_SHIN: R(36),
            "HIPS_Z": -0.18,
        }),
        (1.08, {  # ground hold — recovery starts here (brain: 1.85s)
            R_ARM: R(-16), L_ARM: R(-16), R_FORE: R(16), L_FORE: R(16),
            SPINE1: R(-22), SPINE2: R(-9), HEAD: R(-7),
            R_THIGH: R(-18), L_THIGH: R(-18), R_SHIN: R(26), L_SHIN: R(26),
            "HIPS_Z": -0.12,
        }),
        (1.30, {  # mechanical settle, still low
            R_ARM: R(-8), L_ARM: R(-8), R_FORE: R(8), L_FORE: R(8),
            SPINE1: R(-6), SPINE2: R(-3), HEAD: R(-3), "HIPS_Z": -0.035,
        }),
    ])

    author_clip("hit", [  # barely registers — mass absorbs it
        (0.00, {}),
        (0.07, {SPINE1: R(5), SPINE2: R(3), HEAD: R(4), "HIPS_Z": -0.01}),
        (0.25, {}),
    ])

    author_clip("hit_front", [  # front impact: mass snaps back, then relocks
        (0.00, {}),
        (0.06, {
            SPINE1: R(16), SPINE2: R(8), HEAD: R(11),
            R_ARM: R(12), L_ARM: R(12), R_FORE: R(-8), L_FORE: R(-8),
            R_THIGH: R(-10), L_THIGH: R(-10), "HIPS_Z": -0.04,
        }),
        (0.25, {}),
    ])

    author_clip("hit_back", [  # rear impact: torso pitches into a dead stumble
        (0.00, {}),
        (0.06, {
            SPINE1: R(-18), SPINE2: R(-8), HEAD: R(-10),
            R_ARM: R(-12), L_ARM: R(-12), R_FORE: R(8), L_FORE: R(8),
            R_THIGH: R(8), L_THIGH: R(8), "HIPS_Z": -0.05,
        }),
        (0.25, {}),
    ])

    stagger_a = {
        SPINE1: R(-22), SPINE2: R(-10), HEAD: R(-14),
        R_ARM: R(-34), L_ARM: R(-34), R_FORE: R(18), L_FORE: R(18),
        R_THIGH: R(-42), L_THIGH: R(-42), R_SHIN: R(56), L_SHIN: R(56),
        "HIPS_Z": -0.42,
    }
    stagger_b = {
        SPINE1: R(-24) + BANK(2), SPINE2: R(-11), HEAD: R(-15) + BANK(-3),
        R_ARM: R(-38), L_ARM: R(-32), R_FORE: R(20), L_FORE: R(16),
        R_THIGH: R(-44), L_THIGH: R(-40), R_SHIN: R(58), L_SHIN: R(54),
        "HIPS_Z": -0.45,
    }
    author_clip("stagger", [
        (0.00, stagger_a),
        (0.45, stagger_b),
        (0.90, stagger_a),
    ], loop=True)

    author_clip("spawn", [
        (0.00, {  # folded packet: crouched, arms wrapped, spine locked
            SPINE1: R(-36), SPINE2: R(-22), HEAD: R(-22),
            R_ARM: R(-72) + BANK(-26), L_ARM: R(-72) + BANK(26),
            R_FORE: R(-54), L_FORE: R(-54),
            R_THIGH: R(-66), L_THIGH: R(-66), R_SHIN: R(88), L_SHIN: R(88),
            "HIPS_Z": -0.72,
        }),
        (0.42, {  # unfold overshoots, then locks
            SPINE1: R(4), SPINE2: R(3), HEAD: R(3),
            R_ARM: R(-8), L_ARM: R(-8), R_FORE: R(4), L_FORE: R(4),
            R_THIGH: R(-8), L_THIGH: R(-8), R_SHIN: R(12), L_SHIN: R(12),
            "HIPS_Z": 0.025,
        }),
        (0.60, {}),
    ])

    author_clip("death", [  # decommission: arms cut, spine cuts, then mass drops
        (0.00, {}),
        (0.14, {  # arms die first
            R_ARM: R(-44), L_ARM: R(-44), R_FORE: R(22), L_FORE: R(22),
            HEAD: R(2), "HIPS_Z": -0.03,
        }),
        (0.38, {  # spine power drops out
            SPINE1: R(-28), SPINE2: R(-14), HEAD: R(-20),
            R_ARM: R(-48), L_ARM: R(-48), R_FORE: R(26), L_FORE: R(26),
            R_THIGH: R(-38), L_THIGH: R(-38), R_SHIN: R(50), L_SHIN: R(50),
            "HIPS_Z": -0.46,
        }),
        (0.72, {  # final breaker trip
            SPINE1: R(-48), SPINE2: R(-22), HEAD: R(-30),
            R_ARM: R(-54), L_ARM: R(-54), R_FORE: R(28), L_FORE: R(28),
            R_THIGH: R(-66), L_THIGH: R(-66), R_SHIN: R(84), L_SHIN: R(84),
            "HIPS_Z": -0.94,
        }),
        (1.05, {
            SPINE1: R(-56), SPINE2: R(-24), HEAD: R(-32),
            R_ARM: R(-58), L_ARM: R(-58), R_FORE: R(30), L_FORE: R(30),
            R_THIGH: R(-74), L_THIGH: R(-74), R_SHIN: R(92), L_SHIN: R(92),
            "HIPS_Z": -1.08,
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
    # then one instant thrust. Follow-through is clipped and precise.
    author_clip("attack", [
        (0.00, {}),
        (0.82, {
            R_ARM: R(-90) + BANK(-8), R_FORE: R(-22),
            SPINE1: TWIST(-8), HEAD: R(3), "HIPS_Z": 0.018,
        }),
        (1.03, {  # frozen apex — the wrongness is the stillness
            R_ARM: R(-104) + BANK(-10), R_FORE: R(-30),
            SPINE1: TWIST(-12), HEAD: R(4), "HIPS_Z": 0.022,
        }),
        (ELITE_STRIKE, {  # STRIKE: exact brain-windup contact
            R_SHOULDER: R(-6) + BANK(-18),
            R_ARM: R(-54) + BANK(-56), R_FORE: R(28), R_HAND: R(-16) + BANK(-8),
            L_ARM: R(-6),
            SPINE1: TWIST(24) + R(-8), SPINE2: TWIST(8), HEAD: R(-3),
            R_THIGH: R(-7), L_THIGH: R(5), "HIPS_Z": -0.045,
        }),
        (1.24, {  # blade already retracting; no flourish
            R_ARM: R(-16), R_FORE: R(4), SPINE1: TWIST(5), "HIPS_Z": -0.01,
        }),
        (1.50, {  # recomposed — no settle wobble
            R_ARM: R(-4), SPINE1: TWIST(1), "HIPS_Z": 0.0,
        }),
    ])

    author_clip("hit", [  # a tick of the head; nothing in it feels
        (0.00, {}),
        (0.05, {HEAD: R(4) + TWIST(-5), NECK: R(2)}),
        (0.20, {}),
    ])

    author_clip("hit_front", [  # front impact: a clean backward tick
        (0.00, {}),
        (0.05, {SPINE1: R(9), SPINE2: R(4), HEAD: R(7), R_ARM: R(5), L_ARM: R(5),
                "HIPS_Z": -0.025}),
        (0.25, {}),
    ])

    author_clip("hit_back", [  # rear impact: precise forward pitch, then reset
        (0.00, {}),
        (0.05, {SPINE1: R(-11), SPINE2: R(-5), HEAD: R(-7), R_ARM: R(-5), L_ARM: R(-5),
                "HIPS_Z": -0.030}),
        (0.25, {}),
    ])

    stagger_a = {
        SPINE1: R(-12), SPINE2: R(-7), HEAD: R(-9),
        R_ARM: R(-18), L_ARM: R(-18), R_FORE: R(10), L_FORE: R(10),
        R_THIGH: R(-48), L_THIGH: R(-48), R_SHIN: R(70), L_SHIN: R(70),
        "HIPS_Z": -0.58,
    }
    stagger_b = {
        SPINE1: R(-13) + BANK(-2), SPINE2: R(-7), HEAD: R(-10) + BANK(2),
        R_ARM: R(-20), L_ARM: R(-17), R_FORE: R(11), L_FORE: R(9),
        R_THIGH: R(-49), L_THIGH: R(-47), R_SHIN: R(71), L_SHIN: R(69),
        "HIPS_Z": -0.60,
    }
    author_clip("stagger", [
        (0.00, stagger_a),
        (0.45, stagger_b),
        (0.90, stagger_a),
    ], loop=True)

    author_clip("spawn", [
        (0.00, {  # compact folded silhouette, poised even at boot
            SPINE1: R(-24), SPINE2: R(-16), HEAD: R(-16),
            R_ARM: R(-58) + BANK(-20), L_ARM: R(-58) + BANK(20),
            R_FORE: R(-42), L_FORE: R(-42),
            R_THIGH: R(-70), L_THIGH: R(-70), R_SHIN: R(92), L_SHIN: R(92),
            "HIPS_Z": -0.78,
        }),
        (0.36, {
            SPINE1: R(2), SPINE2: R(1), HEAD: R(2),
            R_ARM: R(-5), L_ARM: R(-5), R_FORE: R(2), L_FORE: R(2),
            R_THIGH: R(-8), L_THIGH: R(-8), R_SHIN: R(12), L_SHIN: R(12),
            "HIPS_Z": 0.018,
        }),
        (0.60, {}),
    ])

    author_clip("death", [  # power-cut: arms, spine, then vertical collapse/list
        (0.00, {}),
        (0.10, {R_ARM: R(-20), L_ARM: R(-20), HEAD: R(-4), "HIPS_Z": -0.04}),
        (0.28, {  # spine loses authority before the legs fold
            SPINE1: R(-10), SPINE2: R(-6), HEAD: R(-12),
            R_ARM: R(-22), L_ARM: R(-22), R_FORE: R(12), L_FORE: R(12),
            "HIPS_Z": -0.22,
        }),
        (0.58, {  # vertical collapse, torso eerily controlled
            R_THIGH: R(-72), L_THIGH: R(-72), R_SHIN: R(98), L_SHIN: R(98),
            SPINE1: R(-12), HEAD: R(-14), R_ARM: R(-24), L_ARM: R(-24),
            R_FORE: R(14), L_FORE: R(14), "HIPS_Z": -1.08,
        }),
        (0.92, {  # the list — tipped off-axis, held
            R_THIGH: R(-78), L_THIGH: R(-78), R_SHIN: R(104), L_SHIN: R(104),
            SPINE1: R(-14) + BANK(30), SPINE2: BANK(12), HEAD: R(-16) + BANK(9),
            R_ARM: R(-26), L_ARM: R(-28), R_FORE: R(16), L_FORE: R(16),
            "HIPS_Z": -1.22,
        }),
    ])


ARCHETYPES = {
    "bruiser": {"short": "bruiser", "stem": "bruiser_unit", "rigged": "bruiser_unit_rigged.glb",
                "author": author_bruiser, "fallback_locomotion": author_bruiser_locomotion},
    "elite": {"short": "elite", "stem": "elite_enforcer", "rigged": "elite_enforcer_rigged.glb",
              "author": author_elite, "fallback_locomotion": author_elite_locomotion},
}

RENDER_SHOTS = {
    "bruiser": [
        ("idle", 1.0), ("walk", 0.4),
        ("attack", 0.84), ("attack", BRUISER_STRIKE), ("attack", 1.08),
        ("hit", 0.07), ("hit_front", 0.06), ("hit_back", 0.06),
        ("stagger", 0.0), ("stagger", 0.45),
        ("spawn", 0.0), ("spawn", 0.42), ("spawn", 0.60),
        ("death", 0.14), ("death", 0.38), ("death", 1.05),
    ],
    "elite": [
        ("idle", 0.9), ("walk", 0.4),
        ("attack", 1.03), ("attack", ELITE_STRIKE), ("attack", 1.24),
        ("hit", 0.05), ("hit_front", 0.05), ("hit_back", 0.05),
        ("stagger", 0.0), ("stagger", 0.45),
        ("spawn", 0.0), ("spawn", 0.36), ("spawn", 0.60),
        ("death", 0.10), ("death", 0.58), ("death", 0.92),
    ],
}

for key, spec in ARCHETYPES.items():
    if ONLY and key != ONLY:
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    rigged = resolve_rigged(spec)
    bpy.ops.import_scene.gltf(filepath=str(rigged))
    # Meshy ships a stray Icosphere alongside the character — strip it.
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and "char" not in obj.name.lower():
            bpy.data.objects.remove(obj, do_unlink=True)
    ARM = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    _LOCAL_CACHE = {}
    bpy.context.scene.render.fps = FPS
    ARM.animation_data_create()
    ARM.animation_data.action = None
    for track in list(ARM.animation_data.nla_tracks):
        ARM.animation_data.nla_tracks.remove(track)

    # Free Meshy locomotion first (RIG BEFORE AUTHORING is satisfied: the rig
    # op already happened upstream; these carry no hand-keyed tracks to lose).
    add_locomotion(spec)
    spec["author"]()
    # The rigged GLB ships its own bind/baselayer action as an NLA track —
    # drop everything that isn't part of the clip contract.
    contract = {"walk", "run", "idle", "attack", "hit", "hit_front", "hit_back",
                "stagger", "spawn", "death"}
    for track in list(ARM.animation_data.nla_tracks):
        if track.name not in contract:
            ARM.animation_data.nla_tracks.remove(track)
    print(f"AUTHORED {key}:", [t.name for t in ARM.animation_data.nla_tracks])

    if RENDER_DIR:
        Path(RENDER_DIR).mkdir(parents=True, exist_ok=True)
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
            set_clip_time(scene, t)
            scene.render.filepath = f"{RENDER_DIR}/{key}_{clip}_{int(t * 1000):04d}ms.png"
            bpy.ops.render.render(write_still=True)
            print("WROTE", scene.render.filepath)
        for track in ARM.animation_data.nla_tracks:
            track.mute = False
        bpy.data.objects.remove(cam, do_unlink=True)

    if DO_EXPORT:
        bpy.ops.export_scene.gltf(
            filepath=str(rigged),
            export_format="GLB",
            export_animations=True,
            export_animation_mode="NLA_TRACKS",
            export_force_sampling=False,
            export_optimize_animation_size=False,
            export_yup=True,
        )
        print("EXPORTED", rigged)

print("AUTHOR OK")
