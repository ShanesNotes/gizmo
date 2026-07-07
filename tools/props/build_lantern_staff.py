# derived from asset pipeline canon; do not edit as source
"""Build lantern_staff_01 as a deterministic procedural Blender asset."""

from __future__ import annotations

import json
import math
from datetime import date
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


ASSET_ID = "lantern_staff_01"
ROOT = Path(__file__).resolve().parents[2]
GLB_PATH = ROOT / "godot" / "assets" / "weapons" / f"{ASSET_ID}.glb"
PROVENANCE_PATH = GLB_PATH.with_suffix(".provenance.json")
RENDER_DIR = Path("/tmp/lantern-staff-renders")


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0


def make_material(
    name: str,
    base_color: tuple[float, float, float, float],
    *,
    metallic: float = 0.0,
    roughness: float = 0.7,
    emission: tuple[float, float, float, float] | None = None,
    emission_strength: float = 0.0,
    alpha: float | None = None,
) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = base_color
    mat.use_nodes = True
    mat.use_backface_culling = False

    if alpha is not None:
        mat.diffuse_color = (base_color[0], base_color[1], base_color[2], alpha)
        mat.blend_method = "BLEND"
        mat.use_screen_refraction = True

    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        inputs = bsdf.inputs
        if inputs.get("Base Color") is not None:
            inputs["Base Color"].default_value = mat.diffuse_color
        if inputs.get("Metallic") is not None:
            inputs["Metallic"].default_value = metallic
        if inputs.get("Roughness") is not None:
            inputs["Roughness"].default_value = roughness
        if alpha is not None and inputs.get("Alpha") is not None:
            inputs["Alpha"].default_value = alpha
        if emission is not None:
            if inputs.get("Emission Color") is not None:
                inputs["Emission Color"].default_value = emission
            elif inputs.get("Emission") is not None:
                inputs["Emission"].default_value = emission
        if emission_strength and inputs.get("Emission Strength") is not None:
            inputs["Emission Strength"].default_value = emission_strength

    return mat


def materials() -> dict[str, bpy.types.Material]:
    return {
        "aged_brass": make_material(
            "aged_brass",
            (0.72, 0.52, 0.25, 1.0),
            metallic=0.75,
            roughness=0.58,
        ),
        "brass_highlight": make_material(
            "worn_brass_edges",
            (0.94, 0.70, 0.32, 1.0),
            metallic=0.65,
            roughness=0.52,
        ),
        "deep_bronze": make_material(
            "deep_bronze_shadow",
            (0.17, 0.105, 0.055, 1.0),
            metallic=0.65,
            roughness=0.68,
        ),
        "dark_gouache": make_material(
            "dark_gouache_wash",
            (0.08, 0.065, 0.045, 1.0),
            metallic=0.15,
            roughness=0.9,
        ),
        "spark_core": make_material(
            "warm_ivory_emissive_core",
            (1.0, 0.80, 0.32, 1.0),
            metallic=0.0,
            roughness=0.08,
            emission=(1.0, 0.88, 0.52, 1.0),
            emission_strength=5.5,
        ),
    }


def assign_material(obj: bpy.types.Object, mat: bpy.types.Material) -> None:
    obj.data.materials.append(mat)


def smooth(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_smooth()
    obj.select_set(False)


def add_weighted_normals(obj: bpy.types.Object) -> None:
    mod = obj.modifiers.new("weighted_normals", "WEIGHTED_NORMAL")
    mod.keep_sharp = True


def cylinder_between(
    name: str,
    a: tuple[float, float, float],
    b: tuple[float, float, float],
    radius: float,
    verts: int,
    mat: bpy.types.Material,
) -> bpy.types.Object:
    start = Vector(a)
    end = Vector(b)
    direction = end - start
    length = direction.length
    if length <= 0.0:
        raise ValueError(f"{name} has zero length")

    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts,
        radius=radius,
        depth=length,
        end_fill_type="NGON",
        location=start + direction * 0.5,
        rotation=direction.to_track_quat("Z", "Y").to_euler(),
    )
    obj = bpy.context.object
    obj.name = name
    assign_material(obj, mat)
    smooth(obj)
    add_weighted_normals(obj)
    return obj


def cone_between(
    name: str,
    a: tuple[float, float, float],
    b: tuple[float, float, float],
    radius1: float,
    radius2: float,
    verts: int,
    mat: bpy.types.Material,
) -> bpy.types.Object:
    start = Vector(a)
    end = Vector(b)
    direction = end - start
    length = direction.length
    bpy.ops.mesh.primitive_cone_add(
        vertices=verts,
        radius1=radius1,
        radius2=radius2,
        depth=length,
        end_fill_type="NGON",
        location=start + direction * 0.5,
        rotation=direction.to_track_quat("Z", "Y").to_euler(),
    )
    obj = bpy.context.object
    obj.name = name
    assign_material(obj, mat)
    smooth(obj)
    add_weighted_normals(obj)
    return obj


def box(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    mat: bpy.types.Material,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    bevel: float = 0.0,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, mat)
    if bevel > 0.0:
        mod = obj.modifiers.new("softened_chunk_edges", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    add_weighted_normals(obj)
    return obj


def ico(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    mat: bpy.types.Material,
    scale: tuple[float, float, float] = (1.0, 1.0, 1.0),
    subdivisions: int = 2,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=subdivisions,
        radius=radius,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, mat)
    add_weighted_normals(obj)
    return obj


def hex_points(x: float, radius: float) -> list[Vector]:
    jitters = [-0.006, 0.004, -0.002, 0.006, -0.004, 0.002]
    points: list[Vector] = []
    for i in range(6):
        angle = math.radians(30.0 + i * 60.0)
        r = radius + jitters[i]
        y = math.cos(angle) * r
        z = math.sin(angle) * r
        points.append(Vector((x, y, z)))
    return points


def add_arc(
    name: str,
    x: float,
    radius: float,
    bar_radius: float,
    start_deg: float,
    end_deg: float,
    segments: int,
    mat: bpy.types.Material,
) -> list[bpy.types.Object]:
    out: list[bpy.types.Object] = []
    points = []
    for i in range(segments + 1):
        t = start_deg + (end_deg - start_deg) * i / segments
        angle = math.radians(t)
        points.append((x, math.cos(angle) * radius, math.sin(angle) * radius))
    for i in range(segments):
        out.append(
            cylinder_between(
                f"{name}_{i + 1:02d}",
                points[i],
                points[i + 1],
                bar_radius,
                8,
                mat,
            )
        )
    return out


def build_staff(mats: dict[str, bpy.types.Material]) -> list[bpy.types.Object]:
    objects: list[bpy.types.Object] = []

    # Raw model convention: long axis is local X. Crown is on -X; wrapper rotates
    # local -X to Godot +Y, matching brass_winding_wrench.tscn.
    pole_path = [
        (0.355, -0.004, -0.001),
        (0.115, 0.003, 0.004),
        (-0.18, -0.003, 0.002),
        (-0.47, 0.002, -0.003),
    ]
    for idx, (a, b) in enumerate(zip(pole_path, pole_path[1:]), start=1):
        objects.append(
            cylinder_between(
                f"PoleSegment{idx:02d}",
                a,
                b,
                0.024 + (0.002 if idx == 2 else 0.0),
                12,
                mats["aged_brass"],
            )
        )

    objects.append(
        cylinder_between(
            "DeepBronzeGripSleeve",
            (0.088, 0.0, 0.0),
            (-0.085, 0.0, 0.0),
            0.038,
            14,
            mats["deep_bronze"],
        )
    )
    for i, x in enumerate((0.112, 0.074, -0.073, -0.111), start=1):
        objects.append(
            cylinder_between(
                f"GripBrassBand{i:02d}",
                (x + 0.012, 0.0, 0.0),
                (x - 0.012, 0.0, 0.0),
                0.043,
                12,
                mats["brass_highlight"],
            )
        )

    for i, (x, y, z, rz) in enumerate(
        [
            (0.025, 0.0, 0.041, 0.05),
            (-0.028, 0.0, -0.041, -0.04),
            (0.0, 0.040, 0.0, 0.0),
        ],
        start=1,
    ):
        objects.append(
            box(
                f"GripGouachePatch{i:02d}",
                (x, y, z),
                (0.058, 0.012, 0.024),
                mats["dark_gouache"],
                rotation=(0.0, 0.0, rz),
                bevel=0.004,
            )
        )

    objects.append(
        cylinder_between(
            "FerruleWeightedCore",
            (0.35, 0.0, 0.0),
            (0.475, 0.0, 0.0),
            0.056,
            12,
            mats["aged_brass"],
        )
    )
    objects.append(
        cone_between(
            "FerruleBluntNose",
            (0.475, 0.0, 0.0),
            (0.515, 0.0, 0.0),
            0.044,
            0.022,
            12,
            mats["deep_bronze"],
        )
    )
    objects.append(
        cylinder_between(
            "FerruleInnerWeight",
            (0.39, 0.0, 0.0),
            (0.445, 0.0, 0.0),
            0.071,
            12,
            mats["brass_highlight"],
        )
    )
    objects.extend(
        add_arc(
            "FerruleSwingArc",
            0.427,
            0.086,
            0.012,
            35.0,
            325.0,
            10,
            mats["aged_brass"],
        )
    )

    cage_bottom_x = -0.486
    cage_top_x = -0.665
    cage_radius = 0.108
    bottom = hex_points(cage_bottom_x, cage_radius)
    top = hex_points(cage_top_x, cage_radius * 1.03)

    objects.append(
        cylinder_between(
            "LanternLowerHexCollar",
            (cage_bottom_x + 0.026, 0.0, 0.0),
            (cage_bottom_x - 0.010, 0.0, 0.0),
            0.086,
            6,
            mats["deep_bronze"],
        )
    )
    objects.append(
        cylinder_between(
            "LanternUpperHexCollar",
            (cage_top_x + 0.010, 0.0, 0.0),
            (cage_top_x - 0.030, 0.0, 0.0),
            0.088,
            6,
            mats["aged_brass"],
        )
    )

    for i in range(6):
        j = (i + 1) % 6
        objects.append(
            cylinder_between(
                f"LanternLowerRail{i + 1:02d}",
                tuple(bottom[i]),
                tuple(bottom[j]),
                0.013,
                8,
                mats["aged_brass"],
            )
        )
        objects.append(
            cylinder_between(
                f"LanternUpperRail{i + 1:02d}",
                tuple(top[i]),
                tuple(top[j]),
                0.0135,
                8,
                mats["brass_highlight" if i in (0, 3) else "aged_brass"],
            )
        )
        objects.append(
            cylinder_between(
                f"LanternCagePost{i + 1:02d}",
                tuple(bottom[i]),
                tuple(top[i]),
                0.014 + (0.002 if i == 2 else 0.0),
                8,
                mats["aged_brass"],
            )
        )

    objects.append(
        ico(
            "SparkGlassFacetedCore",
            (-0.575, 0.0, 0.0),
            0.074,
            mats["spark_core"],
            scale=(1.08, 0.92, 1.02),
            subdivisions=2,
        )
    )
    for i, angle in enumerate((0.0, 120.0, 240.0), start=1):
        y = math.cos(math.radians(angle)) * 0.032
        z = math.sin(math.radians(angle)) * 0.032
        objects.append(
            cylinder_between(
                f"CoreIvoryShard{i:02d}",
                (-0.615, y * 0.45, z * 0.45),
                (-0.535, y, z),
                0.009,
                6,
                mats["spark_core"],
            )
        )

    objects.append(
        box(
            "ChunkyBronzeLatchPlate",
            (-0.574, 0.112, 0.018),
            (0.066, 0.020, 0.045),
            mats["deep_bronze"],
            rotation=(0.0, 0.0, 0.02),
            bevel=0.005,
        )
    )
    objects.append(
        cylinder_between(
            "LanternCrownFinialBase",
            (cage_top_x - 0.028, 0.0, 0.0),
            (cage_top_x - 0.062, 0.0, 0.0),
            0.047,
            12,
            mats["brass_highlight"],
        )
    )
    objects.append(
        cone_between(
            "LanternCrownBluntPoint",
            (cage_top_x - 0.060, 0.0, 0.0),
            (-0.712, 0.0, 0.0),
            0.036,
            0.009,
            12,
            mats["aged_brass"],
        )
    )

    return objects


def create_uvs(objects: list[bpy.types.Object]) -> None:
    for obj in objects:
        if obj.type != "MESH":
            continue
        bpy.ops.object.mode_set(mode="OBJECT")
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        if not obj.data.uv_layers:
            obj.data.uv_layers.new(name="UVMap")
        try:
            bpy.ops.object.mode_set(mode="EDIT")
            bpy.ops.mesh.select_all(action="SELECT")
            bpy.ops.uv.smart_project(angle_limit=1.15192, island_margin=0.02)
        finally:
            bpy.ops.object.mode_set(mode="OBJECT")
            obj.select_set(False)


def bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    coords = [
        obj.matrix_world @ Vector(corner)
        for obj in objects
        if obj.type == "MESH"
        for corner in obj.bound_box
    ]
    low = Vector((min(v.x for v in coords), min(v.y for v in coords), min(v.z for v in coords)))
    high = Vector((max(v.x for v in coords), max(v.y for v in coords), max(v.z for v in coords)))
    return low, high


def normalize_long_axis(objects: list[bpy.types.Object], target_length: float = 1.10) -> None:
    low, high = bounds(objects)
    current_length = high.x - low.x
    if current_length <= 0.0:
        raise RuntimeError("Cannot normalize zero-length staff")
    factor = target_length / current_length
    scale_x = Matrix.Diagonal((factor, 1.0, 1.0, 1.0))
    for obj in objects:
        obj.matrix_world = scale_x @ obj.matrix_world


def triangle_count(objects: list[bpy.types.Object]) -> int:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    tris = 0
    for obj in objects:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        tris += len(mesh.loop_triangles)
        evaluated.to_mesh_clear()
    return tris


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_render_scene() -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.resolution_x = 1280
    scene.render.resolution_y = 720
    scene.render.film_transparent = False
    scene.world = bpy.data.worlds.new("gouache_cosmos_world")
    scene.world.color = (0.035, 0.032, 0.046)

    try:
        scene.render.engine = "BLENDER_WORKBENCH"
        scene.display.shading.light = "STUDIO"
        scene.display.shading.color_type = "MATERIAL"
        scene.display.shading.show_cavity = True
        scene.display.shading.cavity_valley_factor = 0.8
        scene.display.shading.cavity_ridge_factor = 0.45
    except Exception:
        scene.render.engine = "BLENDER_EEVEE_NEXT"

    bpy.ops.object.light_add(type="AREA", location=(0.2, -1.8, 1.2))
    key = bpy.context.object
    key.name = "WarmProofKeyLight"
    key.data.energy = 450.0
    key.data.size = 4.0

    bpy.ops.object.camera_add(location=(0.0, -1.7, 0.12))
    camera = bpy.context.object
    camera.name = "ProofCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 1.28
    scene.camera = camera
    return camera


def render_proofs(camera: bpy.types.Object) -> dict[str, str]:
    RENDER_DIR.mkdir(parents=True, exist_ok=True)

    renders = {
        "front": RENDER_DIR / "lantern_staff_01_front.png",
        "three_quarter_high": RENDER_DIR / "lantern_staff_01_3q_high.png",
    }

    camera.location = (0.0, -1.72, 0.13)
    camera.data.ortho_scale = 1.27
    look_at(camera, (-0.08, 0.0, 0.02))
    bpy.context.scene.render.filepath = str(renders["front"])
    bpy.ops.render.render(write_still=True)

    camera.location = (1.05, -1.35, 0.72)
    camera.data.ortho_scale = 1.30
    look_at(camera, (-0.10, 0.0, 0.015))
    bpy.context.scene.render.filepath = str(renders["three_quarter_high"])
    bpy.ops.render.render(write_still=True)

    return {key: str(path) for key, path in renders.items()}


def export_glb(objects: list[bpy.types.Object]) -> None:
    GLB_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_cameras=False,
        export_lights=False,
        export_animations=False,
        export_yup=True,
        export_apply=True,
    )


def write_provenance(tris: int, renders: dict[str, str]) -> None:
    data = {
        "asset_id": ASSET_ID,
        "asset": f"{ASSET_ID}.glb",
        "asset_class": "weapon",
        "generator_script": "tools/props/build_lantern_staff.py",
        "blender_version": bpy.app.version_string,
        "date": date.today().isoformat(),
        "method": "procedural-bpy zero-spend",
        "source_brief": "Brief B - Lantern-staff weapon: procedural bpy model + wrapper",
        "output": "godot/assets/weapons/lantern_staff_01.glb",
        "triangles": tris,
        "texture_policy": "none; flat procedural PBR materials only",
        "materials": [
            "aged_brass",
            "worn_brass_edges",
            "deep_bronze_shadow",
            "dark_gouache_wash",
            "warm_ivory_emissive_core",
        ],
        "orientation": "raw local -X is crown direction; Godot wrapper rotates raw -X to +Y",
        "grip_origin": "0,0,0 at balance grip",
        "render_proofs": renders,
    }
    PROVENANCE_PATH.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    reset_scene()
    mats = materials()
    objects = build_staff(mats)
    normalize_long_axis(objects)
    create_uvs(objects)
    tris = triangle_count(objects)
    if tris > 4000:
        raise RuntimeError(f"{ASSET_ID} triangle budget exceeded: {tris} > 4000")
    camera = setup_render_scene()
    renders = render_proofs(camera)
    export_glb(objects)
    write_provenance(tris, renders)
    print(f"{ASSET_ID}: exported {GLB_PATH}")
    print(f"{ASSET_ID}: triangles {tris}")
    print(f"{ASSET_ID}: renders {renders}")


if __name__ == "__main__":
    main()
