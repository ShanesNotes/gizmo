# Blender headless rig inspection for godot/assets/gizmo.glb.
# Usage: blender --background --python tools/animation/inspect_gizmo_rig.py -- <out_dir>
# Prints armature/bone axes and renders rest-pose stills from a fixed
# Diablo-style camera so pose authoring can be visually verified.
import math
import sys

import bpy
from mathutils import Vector

GLB = "/home/ark/gizmo-hades/godot/assets/gizmo.glb"
OUT_DIR = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "/tmp"

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=GLB)

arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
print("ARMATURE:", arm.name, "object rotation:", tuple(round(a, 3) for a in arm.rotation_euler))
print("object matrix_world translation:", tuple(round(v, 3) for v in arm.matrix_world.translation))

KEY_BONES = [
    "Bone_000", "Bone_001", "Bone_002", "Bone_005",
    "Bone_016", "Bone_017", "Bone_018",
    "Bone_023", "Bone_022", "Bone_021", "Bone_020", "Bone_019",
    "Bone_028", "Bone_027", "Bone_026", "Bone_025", "Bone_024",
    "Bone_010", "Bone_009", "Bone_008", "Bone_007",
    "Bone_015", "Bone_014", "Bone_013", "Bone_012",
]
for name in KEY_BONES:
    b = arm.data.bones[name]
    head = arm.matrix_world @ b.head_local
    tail = arm.matrix_world @ b.tail_local
    ydir = (tail - head).normalized() if (tail - head).length > 1e-6 else Vector((0, 0, 0))
    print(f"{name}: head=({head.x:+.3f},{head.y:+.3f},{head.z:+.3f}) "
          f"tail=({tail.x:+.3f},{tail.y:+.3f},{tail.z:+.3f}) "
          f"y_axis=({ydir.x:+.2f},{ydir.y:+.2f},{ydir.z:+.2f}) len={b.length:.3f}")

# Bounds of the mesh for framing
mesh = next(o for o in bpy.data.objects if o.type == "MESH")
bb = [mesh.matrix_world @ Vector(c) for c in mesh.bound_box]
lo = Vector((min(v.x for v in bb), min(v.y for v in bb), min(v.z for v in bb)))
hi = Vector((max(v.x for v in bb), max(v.y for v in bb), max(v.z for v in bb)))
print("MESH bounds lo:", tuple(round(v, 3) for v in lo), "hi:", tuple(round(v, 3) for v in hi))

# --- render rest pose from front-high (Diablo-ish) and side ---
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.light = "STUDIO"
scene.display.shading.color_type = "TEXTURE"
scene.render.resolution_x = 640
scene.render.resolution_y = 640

center = (lo + hi) / 2
size = max(hi.z - lo.z, 1.0)

cam_data = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam

def render(name, offset):
    cam.location = center + offset
    direction = center - cam.location
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    scene.render.filepath = f"{OUT_DIR}/{name}.png"
    bpy.ops.render.render(write_still=True)
    print("WROTE", scene.render.filepath)

d = size * 2.2
render("rest_front_high", Vector((0, -d, d * 0.9)))   # Blender forward is -Y for glTF chars
render("rest_side", Vector((d, 0, size * 0.3)))
print("INSPECT OK")
