"""Procedurally generate clockwork-observatory floating-island geometry.

Run headless:
  blender --background --python tools/blender/gen_floating_islands.py

Produces GLBs in godot/assets/world_kits/clockwork_observatory/ and a preview PNG
at /tmp/island_preview.png. Built Z-up; the glTF exporter converts to Y-up for Godot,
so the island's flat top lands at Godot y=0 (where the arena tiles sit).
"""
import bpy, bmesh, math
from mathutils import Vector, noise

OUT = "/home/ark/gizmo/godot/assets/world_kits/clockwork_observatory"
PREVIEW = "/tmp/island_preview.png"


def clear():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras):
        for b in list(coll):
            coll.remove(b)


def mat(name, rgb, rough=0.9, metal=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    b.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    return m


def fbm(p, off):
    return (noise.noise(p * 2.2 + off) * 0.6
            + noise.noise(p * 4.5 + off) * 0.3
            + noise.noise(p * 9.0 + off) * 0.1)


def make_rock(name, R, depth, seed, flatten_top=True, craggy=1.0, sub=4):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
    off = Vector((seed * 7.3, seed * 3.1, seed * 5.7))
    for v in bm.verts:
        d = v.co.normalized()
        hr = math.hypot(d.x, d.y)
        ang = math.atan2(d.y, d.x)
        outline = 0.74 + 0.34 * noise.noise(Vector((math.cos(ang), math.sin(ang), seed)) * 1.6)
        n = fbm(d, off)
        nhi = noise.noise(d * 14.0 + off)
        if flatten_top and d.z >= 0.0:
            # broad ragged plateau, gently raised toward the middle, near-flat at the rim
            v.co.x = d.x * R * outline
            v.co.y = d.y * R * outline
            v.co.z = n * 0.30 + max(0.0, 0.45 - hr) * 0.9
        else:
            t = max(1.0 + d.z, 0.0) ** 0.7                 # 1 at rim -> 0 at bottom
            width = R * outline * (0.12 + 0.88 * t) * (0.72 + 0.45 * abs(n))
            if hr > 1e-6:
                v.co.x = d.x / hr * width
                v.co.y = d.y / hr * width
            else:
                v.co.x = n * 0.4
                v.co.y = nhi * 0.4
            z = -depth * (max(-d.z, 0.0) ** 0.8)
            z += n * craggy + nhi * 0.5 * craggy
            if d.z < -0.25 and nhi > 0.45:                 # occasional hanging spikes
                z -= craggy * 1.5 * (nhi - 0.45)
            v.co.z = z
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    me.materials.append(mat(name + "_top", (0.48, 0.40, 0.28), rough=0.82))   # warm brass-stone
    me.materials.append(mat(name + "_rock", (0.15, 0.14, 0.19), rough=0.95))  # dark cool rock
    for p in me.polygons:
        p.use_smooth = True
        p.material_index = 0 if p.normal.z > 0.45 else 1   # up-facing -> stone top, else rock
    return obj


def export(obj, path):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True)
    print("EXPORTED", path)


clear()
island = make_rock("clockwork_island_base_01", R=9.0, depth=7.5, seed=1, flatten_top=True, craggy=1.1, sub=5)
export(island, OUT + "/clockwork_island_base_01.glb")
deb1 = make_rock("clockwork_debris_01", R=1.7, depth=2.6, seed=4, flatten_top=False, craggy=0.8)
export(deb1, OUT + "/clockwork_debris_01.glb")
deb2 = make_rock("clockwork_debris_02", R=1.1, depth=1.9, seed=7, flatten_top=False, craggy=0.7)
export(deb2, OUT + "/clockwork_debris_02.glb")
print("ISLAND_DIMS", tuple(round(x, 2) for x in island.dimensions))

# ---- preview render (best-effort), steep Diablo-ish angle ----
try:
    deb1.location = (12, 4, -2)
    deb2.location = (-11, -3, -4)
    cam_d = bpy.data.cameras.new("cam")
    cam = bpy.data.objects.new("cam", cam_d)
    bpy.context.collection.objects.link(cam)
    cam.location = (13, -13, 17)
    cam.rotation_euler = (Vector((0, 0, -2.0)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.camera = cam
    sd = bpy.data.lights.new("sun", 'SUN')
    sd.energy = 3.2
    sd.color = (1.0, 0.85, 0.6)
    sun = bpy.data.objects.new("sun", sd)
    bpy.context.collection.objects.link(sun)
    sun.rotation_euler = (math.radians(55), math.radians(12), math.radians(35))
    w = bpy.data.worlds.new("w")
    bpy.context.scene.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.05, 0.04, 0.11, 1)
    sc = bpy.context.scene
    sc.render.resolution_x = 960
    sc.render.resolution_y = 640
    sc.render.filepath = PREVIEW
    for eng in ('BLENDER_EEVEE_NEXT', 'BLENDER_EEVEE', 'CYCLES'):
        try:
            sc.render.engine = eng
            break
        except Exception:
            pass
    if sc.render.engine == 'CYCLES':
        sc.cycles.samples = 24
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_DONE", sc.render.engine)
except Exception as e:
    print("PREVIEW_FAILED", repr(e))
