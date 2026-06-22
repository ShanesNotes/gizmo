"""Decimate + texture-downscale heavy Meshy GLBs for game use.

Run headless:
  blender --background --python tools/blender/optimize_glb.py

Meshy outputs are huge (dense mesh + 4K texture). This collapses the mesh and
downscales embedded textures, re-exporting a lean GLB while keeping the painted look.
"""
import bpy, os

JOBS = [
    # (src, dst, decimate_ratio, tex_max)
    ("/home/ark/gizmo/godot/assets/world_kits/clockwork_observatory/platform_island_01.glb",
     "/home/ark/gizmo/godot/assets/world_kits/clockwork_observatory/platform_island_01_opt.glb", 0.22, 2048),
    ("/home/ark/game-assets/spark.glb",
     "/home/ark/gizmo/godot/assets/world_kits/clockwork_observatory/spark_crystal_01.glb", 0.30, 1024),
]


def optimize(src, dst, ratio, tex_max):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    tris_before = 0
    for obj in list(bpy.data.objects):
        if obj.type == 'MESH':
            tris_before += len(obj.data.polygons)
            bpy.context.view_layer.objects.active = obj
            m = obj.modifiers.new("dec", 'DECIMATE')
            m.decimate_type = 'COLLAPSE'
            m.ratio = ratio
            bpy.ops.object.modifier_apply(modifier=m.name)
    for img in bpy.data.images:
        if img.has_data and max(img.size) > tex_max:
            w, h = img.size
            s = tex_max / float(max(w, h))
            img.scale(int(w * s), int(h * s))
    bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB')
    tris_after = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == 'MESH')
    sb = os.path.getsize(src) / 1e6
    da = os.path.getsize(dst) / 1e6
    print(f"OPT {os.path.basename(dst)}: {sb:.1f}MB->{da:.1f}MB  tris {tris_before}->{tris_after}")


for src, dst, ratio, tex in JOBS:
    if os.path.exists(src):
        try:
            optimize(src, dst, ratio, tex)
        except Exception as e:
            print("OPT_FAIL", src, repr(e))
    else:
        print("OPT_MISSING", src)
print("OPT_DONE")
