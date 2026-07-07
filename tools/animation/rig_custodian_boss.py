"""Rig and author clips for the unrigged Custodian boss GLB.

derived from asset pipeline canon; do not edit as source

Usage (the in-repo custodian_boss.glb is ALREADY the rigged output; restore the
unrigged meshy source from git before re-running):
  git show <pre-2026-07-07 ref>:godot/assets/enemies/custodian_boss.glb > /tmp/custodian_boss_source.glb
  blender --background --python tools/animation/rig_custodian_boss.py -- \
      --src /tmp/custodian_boss_source.glb --out godot/assets/enemies/custodian_boss.glb \
      --render-dir /tmp/custodian-clip-renders/

The source mesh is a dense Meshy reconstruction with many disconnected islands,
so this script uses a deliberately simple broad-motion rig and rigid-ish vertex
group assignment by anatomical region.
"""
import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Quaternion, Vector

FPS = 60

SOURCE = Path("godot/assets/enemies/custodian_boss.glb")
OUTPUT = Path("godot/assets/enemies/custodian_boss_rigged.glb")
DEFAULT_RENDER_DIR = Path("/tmp/custodian-clip-renders")

ROOT = "root"
CORE_LOWER = "core_lower"
CORE_UPPER = "core_upper"
HEAD = "head"
HALO = "halo"
LEFT_ARM = "left_arm"
RIGHT_ARM = "right_arm"
LEFT_LEG = "left_leg"
RIGHT_LEG = "right_leg"

BONES = [
    ROOT,
    CORE_LOWER,
    CORE_UPPER,
    HEAD,
    HALO,
    LEFT_ARM,
    RIGHT_ARM,
    LEFT_LEG,
    RIGHT_LEG,
]

X = Vector((1.0, 0.0, 0.0))
Y = Vector((0.0, 1.0, 0.0))
Z = Vector((0.0, 0.0, 1.0))

R = lambda deg: [(X, deg)]
BANK = lambda deg: [(Y, deg)]
TWIST = lambda deg: [(Z, deg)]

ROOT_Z = "__root_z__"
HALO_SCALE = "__halo_scale__"

# BossBrain uses per-attack telegraph_seconds as the windup/commit timing.
OVERREACH_SLAM_STRIKE = 1.20
AUDIT_SWEEP_STRIKE = 0.90

argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []


def _arg(flag: str, default: str = "") -> str:
    return argv[argv.index(flag) + 1] if flag in argv else default


SRC = Path(_arg("--src", str(SOURCE)))
OUT = Path(_arg("--out", str(OUTPUT)))
RENDER_DIR_ARG = _arg("--render-dir", str(DEFAULT_RENDER_DIR))
RENDER_DIR = Path(RENDER_DIR_ARG) if RENDER_DIR_ARG else None
DO_EXPORT = "--no-export" not in argv
DO_RENDER = "--no-render" not in argv

ARM = None
REST_INV = {}
BOUNDS = {}


def clear_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def import_source() -> list:
    if not SRC.exists():
        raise FileNotFoundError(f"missing source GLB: {SRC}")
    bpy.ops.import_scene.gltf(filepath=str(SRC))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"no meshes imported from {SRC}")
    for obj in bpy.context.scene.objects:
        if obj.type == "ARMATURE":
            raise RuntimeError(f"{SRC} already contains an armature: {obj.name}")
    return meshes


def decimate_meshes(meshes: list, target_faces: int = 140000) -> None:
    """Settle the lab's decimation debt (meshy source is 1.35M faces / 44MB):
    collapse-decimate to ~target_faces before skinning so the shipped rigged
    GLB carries a sane boss budget. Deterministic (fixed ratio per source)."""
    total = sum(len(obj.data.polygons) for obj in meshes)
    if total <= target_faces:
        print(f"DECIMATE: skipped ({total} faces <= {target_faces})")
        return
    ratio = target_faces / total
    for obj in meshes:
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = ratio
        mod.use_collapse_triangulate = True
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    after = sum(len(obj.data.polygons) for obj in meshes)
    print(f"DECIMATE: {total} -> {after} faces (ratio {ratio:.4f})")


def cap_textures(max_size: int = 1024) -> None:
    """Enforce the 1K texture cap on any packed image."""
    for image in bpy.data.images:
        w, h = image.size
        if w > max_size or h > max_size:
            scale = max_size / max(w, h)
            image.scale(int(w * scale), int(h * scale))
            print(f"TEXTURE CAP: {image.name} {w}x{h} -> {image.size[0]}x{image.size[1]}")


def world_bounds(objects: list) -> tuple[Vector, Vector, Vector, Vector]:
    points = []
    for obj in objects:
        points.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    mn = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    mx = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return mn, mx, (mn + mx) * 0.5, mx - mn


def connected_components(obj) -> list[dict]:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    seen = set()
    components = []
    for face in bm.faces:
        if face.index in seen:
            continue
        stack = [face]
        seen.add(face.index)
        faces = []
        verts = set()
        while stack:
            current = stack.pop()
            faces.append(current)
            verts.update(current.verts)
            for edge in current.edges:
                for linked in edge.link_faces:
                    if linked.index not in seen:
                        seen.add(linked.index)
                        stack.append(linked)
        points = [obj.matrix_world @ vert.co for vert in verts]
        mn = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
        mx = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
        components.append(
            {
                "faces": len(faces),
                "verts": {vert.index for vert in verts},
                "vert_count": len(verts),
                "min": mn,
                "max": mx,
                "center": (mn + mx) * 0.5,
                "dims": mx - mn,
            }
        )
    bm.free()
    components.sort(key=lambda item: item["faces"], reverse=True)
    return components


def describe_mesh(meshes: list, components_by_obj: dict) -> dict:
    mn, mx, center, dims = world_bounds(meshes)
    print("MESH ANATOMY")
    print(
        " source=%s bounds min=(%.3f,%.3f,%.3f) max=(%.3f,%.3f,%.3f) dims=(%.3f,%.3f,%.3f)"
        % (SRC, mn.x, mn.y, mn.z, mx.x, mx.y, mx.z, dims.x, dims.y, dims.z)
    )
    for obj in meshes:
        mats = [slot.material.name if slot.material else "<none>" for slot in obj.material_slots]
        face_by_mat = {}
        for poly in obj.data.polygons:
            face_by_mat[poly.material_index] = face_by_mat.get(poly.material_index, 0) + 1
        comps = components_by_obj[obj.name]
        print(
            " mesh=%s verts=%d faces=%d materials=%s material_faces=%s loose_components=%d"
            % (obj.name, len(obj.data.vertices), len(obj.data.polygons), mats, face_by_mat, len(comps))
        )
        for index, comp in enumerate(comps[:24]):
            c = comp["center"]
            d = comp["dims"]
            print(
                "  comp%02d faces=%d verts=%d center=(%.3f,%.3f,%.3f) dims=(%.3f,%.3f,%.3f)"
                % (index, comp["faces"], comp["vert_count"], c.x, c.y, c.z, d.x, d.y, d.z)
            )
    return {"min": mn, "max": mx, "center": center, "dims": dims}


def is_halo_component(component: dict, bounds: dict) -> bool:
    mn = bounds["min"]
    mx = bounds["max"]
    dims = bounds["dims"]
    center = bounds["center"]
    comp_center = component["center"]
    comp_dims = component["dims"]
    high_enough = comp_center.z > mn.z + dims.z * 0.90 or component["max"].z > mx.z - dims.z * 0.035
    behind_head = comp_center.y < center.y - dims.y * 0.10
    thin_back_arc = comp_dims.y < dims.y * 0.28 and comp_dims.z > dims.z * 0.015
    return high_enough and behind_head and thin_back_arc


def rel_z_value(z: float, bounds: dict) -> float:
    mn = bounds["min"]
    dims = bounds["dims"]
    return (z - mn.z) / max(dims.z, 0.0001)


def arm_component_is_safe(component: dict, bounds: dict) -> bool:
    center = bounds["center"]
    dims = bounds["dims"]
    mx = bounds["max"]
    comp_center = component["center"]
    comp_dims = component["dims"]
    shoulder_z = mx.z - dims.z * 0.28
    rel_center_z = rel_z_value(comp_center.z, bounds)
    abs_center_x = abs(comp_center.x - center.x)

    behind_body = comp_center.y < center.y - dims.y * 0.08
    below_shoulder = comp_center.z < shoulder_z
    low_side_band = rel_center_z < 0.39
    broad_back_plate = behind_body and comp_dims.z > dims.z * 0.07 and comp_dims.x > dims.x * 0.06
    near_core_side = abs_center_x < dims.x * 0.34
    if below_shoulder and (low_side_band or (behind_body and near_core_side) or broad_back_plate):
        return False
    return True


def classify_vertex_group(vertex_world: Vector, component: dict, halo_verts: set, vertex_index: int, bounds: dict) -> str:
    center = bounds["center"]
    dims = bounds["dims"]
    rel_z = rel_z_value(vertex_world.z, bounds)
    abs_x = abs(vertex_world.x - center.x)
    signed_x = vertex_world.x - center.x
    front_enough = vertex_world.y > center.y - dims.y * 0.13
    outer_side = abs_x > dims.x * 0.36

    if vertex_index in halo_verts:
        return HALO
    if rel_z > 0.78 and abs_x < dims.x * 0.23:
        return HEAD
    if abs_x > dims.x * 0.27 and 0.39 < rel_z < 0.83 and arm_component_is_safe(component, bounds):
        if front_enough or outer_side:
            return LEFT_ARM if signed_x < 0.0 else RIGHT_ARM
        return CORE_UPPER
    if rel_z < 0.42 and abs_x > dims.x * 0.055:
        return LEFT_LEG if signed_x < 0.0 else RIGHT_LEG
    if rel_z < 0.50:
        return CORE_LOWER
    return CORE_UPPER


def boundary_blend_weights(primary: str, vertex_world: Vector, bounds: dict) -> tuple[tuple[str, float], ...]:
    rel_z = rel_z_value(vertex_world.z, bounds)
    if primary in {LEFT_ARM, RIGHT_ARM}:
        return ((primary, 0.72), (CORE_UPPER, 0.28))
    if primary in {LEFT_LEG, RIGHT_LEG}:
        if rel_z > 0.34:
            return ((primary, 0.78), (CORE_LOWER, 0.14), (CORE_UPPER, 0.08))
        return ((primary, 0.84), (CORE_LOWER, 0.16))
    if primary == HEAD:
        return ((HEAD, 0.84), (CORE_UPPER, 0.16))
    if primary == HALO:
        return ((HALO, 0.90), (HEAD, 0.10))
    if primary == CORE_LOWER and rel_z > 0.40:
        return ((CORE_LOWER, 0.84), (CORE_UPPER, 0.16))
    if primary == CORE_UPPER and rel_z < 0.56:
        return ((CORE_UPPER, 0.86), (CORE_LOWER, 0.14))
    return ((primary, 1.0),)


def smooth_vertex_group_boundaries(obj, groups: dict, primary_by_vertex: dict, bounds: dict) -> None:
    buckets = {}
    for vertex in obj.data.vertices:
        primary = primary_by_vertex[vertex.index]
        world = obj.matrix_world @ vertex.co
        weights = boundary_blend_weights(primary, world, bounds)
        buckets.setdefault(weights, []).append(vertex.index)

    for weights, indices in buckets.items():
        for group_name, weight in weights:
            groups[group_name].add(indices, weight, "REPLACE")
    print("BOUNDARY_WEIGHT_BUCKETS", obj.name, len(buckets))


def build_armature(bounds: dict):
    global ARM, REST_INV
    mn = bounds["min"]
    mx = bounds["max"]
    center = bounds["center"]
    dims = bounds["dims"]
    bottom = mn.z
    top = mx.z
    width = dims.x

    bpy.ops.object.armature_add(enter_editmode=True, align="WORLD", location=(0.0, 0.0, 0.0))
    ARM = bpy.context.object
    ARM.name = "CustodianBossRig"
    ARM.data.name = "CustodianBossArmature"

    root = ARM.data.edit_bones[0]
    root.name = ROOT
    root.head = (0.0, 0.0, bottom)
    root.tail = (0.0, 0.0, bottom + dims.z * 0.13)

    def add_bone(name: str, head: tuple, tail: tuple, parent: str):
        bone = ARM.data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        bone.parent = ARM.data.edit_bones[parent]
        bone.use_connect = False
        return bone

    lower_top = center.z - dims.z * 0.04
    upper_top = top - dims.z * 0.27
    shoulder_z = top - dims.z * 0.28
    hip_z = bottom + dims.z * 0.44
    hand_z = bottom + dims.z * 0.23
    foot_z = bottom + dims.z * 0.07
    arm_x = width * 0.35
    leg_x = width * 0.13

    add_bone(CORE_LOWER, (0.0, 0.0, bottom + dims.z * 0.12), (0.0, 0.0, lower_top), ROOT)
    add_bone(CORE_UPPER, (0.0, 0.0, lower_top), (0.0, 0.0, upper_top), CORE_LOWER)
    add_bone(HEAD, (0.0, center.y - dims.y * 0.05, upper_top), (0.0, center.y - dims.y * 0.11, top - dims.z * 0.05), CORE_UPPER)
    add_bone(HALO, (0.0, center.y - dims.y * 0.20, top - dims.z * 0.16), (0.0, center.y - dims.y * 0.20, top + dims.z * 0.06), HEAD)
    add_bone(LEFT_ARM, (-arm_x, center.y, shoulder_z), (-arm_x * 0.95, center.y + dims.y * 0.03, hand_z), CORE_UPPER)
    add_bone(RIGHT_ARM, (arm_x, center.y, shoulder_z), (arm_x * 0.95, center.y + dims.y * 0.03, hand_z), CORE_UPPER)
    add_bone(LEFT_LEG, (-leg_x, center.y, hip_z), (-leg_x * 1.35, center.y + dims.y * 0.02, foot_z), CORE_LOWER)
    add_bone(RIGHT_LEG, (leg_x, center.y, hip_z), (leg_x * 1.35, center.y + dims.y * 0.02, foot_z), CORE_LOWER)

    bpy.ops.object.mode_set(mode="OBJECT")
    ARM.show_in_front = True
    REST_INV = {name: ARM.pose.bones[name].bone.matrix_local.to_3x3().inverted() for name in BONES}
    print("BONES", BONES)
    return ARM


def assign_vertex_groups(meshes: list, components_by_obj: dict, bounds: dict) -> dict:
    assignments_total = {name: 0 for name in BONES}
    for obj in meshes:
        groups = {name: obj.vertex_groups.new(name=name) for name in BONES}
        halo_verts = set()
        for component in components_by_obj[obj.name]:
            if is_halo_component(component, bounds):
                halo_verts.update(component["verts"])

        by_group = {name: [] for name in BONES}
        primary_by_vertex = {}
        for component in components_by_obj[obj.name]:
            for vertex_index in component["verts"]:
                vertex = obj.data.vertices[vertex_index]
                world = obj.matrix_world @ vertex.co
                group_name = classify_vertex_group(world, component, halo_verts, vertex.index, bounds)
                primary_by_vertex[vertex.index] = group_name
                by_group[group_name].append(vertex.index)

        for name, indices in by_group.items():
            if indices:
                groups[name].add(indices, 1.0, "ADD")
                assignments_total[name] += len(indices)
        smooth_vertex_group_boundaries(obj, groups, primary_by_vertex, bounds)

        obj.parent = ARM
        modifier = obj.modifiers.new("CustodianBossArmature", "ARMATURE")
        modifier.object = ARM
        modifier.use_vertex_groups = True

    print("VERTEX_GROUP_ASSIGNMENTS", assignments_total)
    return assignments_total


def rot(name: str, axis_world: Vector, deg: float) -> Quaternion:
    axis_local = (REST_INV[name] @ axis_world).normalized()
    return Quaternion(axis_local, math.radians(deg))


def reset_pose_bone(pb) -> None:
    pb.rotation_mode = "QUATERNION"
    pb.rotation_quaternion = Quaternion()
    pb.location = Vector((0.0, 0.0, 0.0))
    pb.scale = Vector((1.0, 1.0, 1.0))


def apply_pose(pose: dict, frame: float, keyed_bones: set[str], uses_root_z: bool, uses_halo_scale: bool) -> None:
    for name in keyed_bones:
        pb = ARM.pose.bones[name]
        reset_pose_bone(pb)
        q = Quaternion()
        for axis, deg in pose.get(name, []):
            q = rot(name, axis, deg) @ q
        pb.rotation_quaternion = q
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        if uses_halo_scale and name == HALO:
            scale_value = float(pose.get(HALO_SCALE, 1.0))
            pb.scale = Vector((scale_value, scale_value, scale_value))
            pb.keyframe_insert("scale", frame=frame)
        if uses_root_z and name == ROOT:
            pb.location = REST_INV[ROOT] @ Vector((0.0, 0.0, float(pose.get(ROOT_Z, 0.0))))
            pb.keyframe_insert("location", frame=frame)


def author_clip(name: str, keys: list, loop: bool = False):
    ARM.animation_data_create()
    action = bpy.data.actions.new(name)
    ARM.animation_data.action = action
    keyed_bones = set()
    uses_root_z = False
    uses_halo_scale = False
    for _, pose in keys:
        keyed_bones.update(key for key in pose if key in BONES)
        uses_root_z = uses_root_z or ROOT_Z in pose
        uses_halo_scale = uses_halo_scale or HALO_SCALE in pose
    if uses_root_z:
        keyed_bones.add(ROOT)
    if uses_halo_scale:
        keyed_bones.add(HALO)

    def key_at(t: float, pose: dict) -> None:
        frame = 1.0 + t * FPS
        apply_pose(pose, frame, keyed_bones, uses_root_z, uses_halo_scale)

    for t, pose in keys:
        key_at(t, pose)
    if loop:
        key_at(keys[-1][0], keys[0][1])

    for curve in getattr(action, "fcurves", []):
        for keyframe in curve.keyframe_points:
            keyframe.interpolation = "SINE" if name in {"idle"} else "LINEAR"

    ARM.animation_data.action = None
    track = ARM.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 1, action)
    return action


def author_clips() -> None:
    ARM.animation_data_create()
    ARM.animation_data.action = None
    for track in list(ARM.animation_data.nla_tracks):
        ARM.animation_data.nla_tracks.remove(track)

    author_clip(
        "idle",
        [
            (0.0, {ROOT_Z: 0.000, CORE_UPPER: R(0) + BANK(0), HEAD: TWIST(0), HALO: TWIST(0) + BANK(0), HALO_SCALE: 1.0}),
            (1.2, {ROOT_Z: 0.040, CORE_UPPER: R(2.0) + BANK(1.2), HEAD: TWIST(2.0), HALO: TWIST(7.0) + BANK(2.0), HALO_SCALE: 1.02}),
            (2.6, {ROOT_Z: -0.018, CORE_UPPER: R(-1.4) + BANK(-1.0), HEAD: TWIST(-1.5), HALO: TWIST(15.0) + BANK(-1.0), HALO_SCALE: 0.99}),
            (4.0, {ROOT_Z: 0.000, CORE_UPPER: R(0) + BANK(0), HEAD: TWIST(0), HALO: TWIST(0) + BANK(0), HALO_SCALE: 1.0}),
        ],
        loop=True,
    )

    author_clip(
        "phase_shift",
        [
            (0.00, {ROOT_Z: 0.00, CORE_LOWER: R(0), CORE_UPPER: R(0), HEAD: TWIST(0), HALO: TWIST(0), HALO_SCALE: 1.00}),
            (0.35, {ROOT_Z: 0.10, CORE_LOWER: R(-4), CORE_UPPER: R(-8), HEAD: R(-4), HALO: TWIST(28) + BANK(6), HALO_SCALE: 1.12}),
            (0.48, {ROOT_Z: 0.08, CORE_UPPER: R(-5) + TWIST(-5), HEAD: TWIST(-7), HALO: TWIST(-20) + BANK(-8), HALO_SCALE: 0.78}),
            (0.58, {ROOT_Z: 0.13, CORE_UPPER: R(-10) + TWIST(4), HEAD: TWIST(4), HALO: TWIST(42) + BANK(10), HALO_SCALE: 1.18}),
            (0.72, {ROOT_Z: 0.10, CORE_UPPER: R(-6) + TWIST(-3), HEAD: TWIST(-3), HALO: TWIST(-12) + BANK(-5), HALO_SCALE: 0.86}),
            (1.10, {ROOT_Z: 0.17, CORE_LOWER: R(-3), CORE_UPPER: R(-7), HEAD: R(-3), HALO: TWIST(18) + BANK(4), HALO_SCALE: 1.04}),
            (1.60, {ROOT_Z: 0.09, CORE_LOWER: R(-1), CORE_UPPER: R(-3), HEAD: R(-1), HALO: TWIST(6), HALO_SCALE: 1.0}),
        ],
    )

    author_clip(
        "attack",
        [
            (0.00, {ROOT_Z: 0.04, CORE_LOWER: R(0), CORE_UPPER: R(0), HEAD: R(0), LEFT_ARM: R(0), RIGHT_ARM: R(0), HALO: TWIST(0)}),
            (0.70, {ROOT_Z: 0.20, CORE_LOWER: R(-1), CORE_UPPER: R(-17), HEAD: R(-8), LEFT_ARM: R(-26) + BANK(-10), RIGHT_ARM: R(-26) + BANK(10), HALO: TWIST(15) + BANK(5)}),
            (1.16, {ROOT_Z: 0.26, CORE_LOWER: R(-2), CORE_UPPER: R(-26), HEAD: R(-12), LEFT_ARM: R(-42) + BANK(-14), RIGHT_ARM: R(-42) + BANK(14), HALO: TWIST(24) + BANK(8)}),
            (
                OVERREACH_SLAM_STRIKE,
                {
                    ROOT_Z: -0.15,
                    CORE_LOWER: R(2),
                    CORE_UPPER: R(44),
                    HEAD: R(16),
                    LEFT_ARM: R(38) + BANK(8),
                    RIGHT_ARM: R(38) + BANK(-8),
                    LEFT_LEG: R(0),
                    RIGHT_LEG: R(0),
                    HALO: TWIST(-18) + BANK(-12),
                },
            ),
            (1.43, {ROOT_Z: -0.11, CORE_LOWER: R(1), CORE_UPPER: R(27), HEAD: R(10), LEFT_ARM: R(24), RIGHT_ARM: R(24), HALO: TWIST(-10) + BANK(-4)}),
            (1.85, {ROOT_Z: 0.03, CORE_LOWER: R(0), CORE_UPPER: R(-3), HEAD: R(-1), LEFT_ARM: R(2), RIGHT_ARM: R(2), HALO: TWIST(0)}),
        ],
    )

    author_clip(
        "attack_sweep",
        [
            (0.00, {ROOT_Z: 0.03, CORE_LOWER: TWIST(0), CORE_UPPER: TWIST(0), HEAD: TWIST(0), LEFT_ARM: R(0), RIGHT_ARM: R(0), HALO: TWIST(0)}),
            (0.52, {ROOT_Z: 0.13, CORE_LOWER: TWIST(-8) + BANK(-2), CORE_UPPER: TWIST(-18) + R(6), HEAD: TWIST(-10), LEFT_ARM: R(-18) + BANK(16), RIGHT_ARM: R(-34) + BANK(-20), HALO: TWIST(-22) + BANK(-5)}),
            (0.86, {ROOT_Z: 0.17, CORE_LOWER: TWIST(-12), CORE_UPPER: TWIST(-29) + R(8), HEAD: TWIST(-15), LEFT_ARM: R(-22) + BANK(20), RIGHT_ARM: R(-45) + BANK(-26), HALO: TWIST(-34) + BANK(-7)}),
            (
                AUDIT_SWEEP_STRIKE,
                {
                    ROOT_Z: 0.02,
                    CORE_LOWER: TWIST(20) + BANK(3),
                    CORE_UPPER: TWIST(44) + R(-10),
                    HEAD: TWIST(18) + R(-4),
                    LEFT_ARM: R(16) + BANK(-30),
                    RIGHT_ARM: R(32) + BANK(34),
                    LEFT_LEG: BANK(-4),
                    RIGHT_LEG: BANK(4),
                    HALO: TWIST(38) + BANK(9),
                },
            ),
            (1.18, {ROOT_Z: -0.02, CORE_LOWER: TWIST(13), CORE_UPPER: TWIST(28) + R(-8), HEAD: TWIST(11), LEFT_ARM: R(10) + BANK(-16), RIGHT_ARM: R(18) + BANK(20), HALO: TWIST(24) + BANK(3)}),
            (1.45, {ROOT_Z: 0.02, CORE_LOWER: TWIST(0), CORE_UPPER: TWIST(2), HEAD: TWIST(0), LEFT_ARM: R(0), RIGHT_ARM: R(0), HALO: TWIST(0)}),
        ],
    )

    author_clip(
        "death",
        [
            (0.00, {ROOT_Z: 0.03, CORE_LOWER: R(0), CORE_UPPER: R(0), HEAD: R(0), HALO: TWIST(0), HALO_SCALE: 1.00}),
            (0.28, {ROOT_Z: 0.02, CORE_UPPER: R(4), HEAD: R(3), HALO: TWIST(18) + BANK(9), HALO_SCALE: 1.10}),
            (0.42, {ROOT_Z: 0.00, CORE_UPPER: R(6), HEAD: R(4), HALO: TWIST(-26) + BANK(-18), HALO_SCALE: 0.58}),
            (0.62, {ROOT_Z: -0.04, CORE_UPPER: R(8), HEAD: R(5), HALO: TWIST(14) + BANK(16), HALO_SCALE: 0.86}),
            (0.82, {ROOT_Z: -0.09, CORE_UPPER: R(12), HEAD: R(7), HALO: TWIST(-12) + BANK(-20), HALO_SCALE: 0.42}),
            (1.05, {ROOT_Z: -0.08, CORE_LOWER: R(5), CORE_UPPER: R(18), HEAD: R(12), HALO: TWIST(7) + BANK(23), HALO_SCALE: 0.62}),
            (
                1.45,
                {
                    ROOT_Z: -0.10,  # settle only; node sink lives in custodian_visual.gd
                    CORE_LOWER: R(3),
                    CORE_UPPER: R(34),
                    HEAD: R(22),
                    LEFT_ARM: R(14),
                    RIGHT_ARM: R(14),
                    LEFT_LEG: R(0),
                    RIGHT_LEG: R(0),
                    HALO: TWIST(-5) + BANK(32),
                    HALO_SCALE: 0.26,
                },
            ),
            (
                2.50,
                {
                    ROOT_Z: -0.12,  # held settle; procedural layer owns the burial sink
                    CORE_LOWER: R(4),
                    CORE_UPPER: R(48),
                    HEAD: R(30),
                    LEFT_ARM: R(22),
                    RIGHT_ARM: R(20),
                    LEFT_LEG: R(0),
                    RIGHT_LEG: R(0),
                    HALO: TWIST(-2) + BANK(46),
                    HALO_SCALE: 0.12,
                },
            ),
        ],
    )

    print("CLIPS", [track.name for track in ARM.animation_data.nla_tracks])


def set_clip_time(scene, t: float) -> None:
    frame = 1.0 + t * FPS
    whole = math.floor(frame)
    scene.frame_set(whole, subframe=frame - whole)


def setup_render_camera(bounds: dict) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.light = "STUDIO"
    scene.display.shading.color_type = "TEXTURE"
    scene.render.resolution_x = 760
    scene.render.resolution_y = 760
    scene.view_settings.view_transform = "Standard"
    scene.world = scene.world or bpy.data.worlds.new("World")
    scene.world.color = (0.0, 0.0, 0.0)

    center = bounds["center"]
    dims = bounds["dims"]
    camera = bpy.data.objects.new("ProofCamera", bpy.data.cameras.new("ProofCamera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.location = center + Vector((dims.x * 2.3, -dims.y * 4.9, dims.z * 1.85))
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.lens = 68


RENDER_SHOTS = [
    ("idle", 0.00, "loop_start"),
    ("idle", 1.20, "breath_rise"),
    ("idle", 2.60, "halo_drift"),
    ("phase_shift", 0.35, "rear_up"),
    ("phase_shift", 0.48, "flicker_1"),
    ("phase_shift", 0.58, "flicker_2"),
    ("phase_shift", 1.60, "taller_settle"),
    ("attack", 1.16, "apex"),
    ("attack", OVERREACH_SLAM_STRIKE, "strike"),
    ("attack", 1.43, "ground_hold"),
    ("attack_sweep", 0.86, "coil"),
    ("attack_sweep", AUDIT_SWEEP_STRIKE, "strike"),
    ("attack_sweep", 1.18, "followthrough"),
    ("death", 0.28, "halo_flicker_1"),
    ("death", 0.62, "halo_flicker_2"),
    ("death", 1.05, "halo_flicker_3"),
    ("death", 1.45, "sink"),
    ("death", 2.50, "hold"),
]


def render_proofs(bounds: dict) -> None:
    if RENDER_DIR is None:
        return
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    setup_render_camera(bounds)
    scene = bpy.context.scene
    for clip, t, label in RENDER_SHOTS:
        for track in ARM.animation_data.nla_tracks:
            track.mute = track.name != clip
        set_clip_time(scene, t)
        scene.render.filepath = str(RENDER_DIR / f"custodian_{clip}_{label}_{int(t * 1000):04d}ms.png")
        bpy.ops.render.render(write_still=True)
        print("WROTE", scene.render.filepath)
    for track in ARM.animation_data.nla_tracks:
        track.mute = False


def export_glb() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUT),
        export_format="GLB",
        export_animations=True,
        export_animation_mode="NLA_TRACKS",
        export_force_sampling=False,
        export_optimize_animation_size=False,
        export_yup=True,
    )
    print("EXPORTED", OUT)


def main() -> None:
    global BOUNDS
    clear_scene()
    bpy.context.scene.render.fps = FPS
    meshes = import_source()
    cap_textures()
    components_by_obj = {obj.name: connected_components(obj) for obj in meshes}
    BOUNDS = describe_mesh(meshes, components_by_obj)
    build_armature(BOUNDS)
    assign_vertex_groups(meshes, components_by_obj, BOUNDS)
    # Decimate AFTER skinning: group assignment is component-based and tuned on
    # the full mesh; the collapse modifier preserves vertex-group weights.
    decimate_meshes(meshes)
    author_clips()
    if DO_RENDER:
        render_proofs(BOUNDS)
    if DO_EXPORT:
        export_glb()
    print("CUSTODIAN RIG OK")


if __name__ == "__main__":
    main()
