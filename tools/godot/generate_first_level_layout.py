#!/usr/bin/env python3
"""Historical arena-block generator for the old world-kit staging pass.

Do not run this as current Path A tooling without first refreshing it against
docs/path-a-shattered-meridian-spec.md and the asset-pipeline queue. It references
world-kit wrapper paths that are not present in the active game checkout.

This keeps the scene static for Godot, but makes the large first-level layout
reproducible from a small set of procedural coordinates: central plaza, approach
spine, side alcoves, beacon dais, landing dais, perimeter landmarks, and debris.
"""
from __future__ import annotations

from pathlib import Path
import re

MAIN = Path("godot/scenes/main.tscn")
ARENA_BEGIN_MARKER = "; BEGIN GENERATED FIRST LEVEL ARENA - regenerate with tools/godot/generate_first_level_layout.py"
ARENA_END_MARKER = "; END GENERATED FIRST LEVEL ARENA"
ARENA_NODE_HEADER = '[node name="ArenaTiles" type="Node3D" parent="."]'
GIZMO_NODE_PREFIX = '[node name="Gizmo" parent="."'

ROTATIONS = {
    0: "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y}, {z})",
    90: "Transform3D(-4.37114e-08, 0, -1, 0, 1, 0, 1, 0, -4.37114e-08, {x}, {y}, {z})",
    180: "Transform3D(-1, 0, -8.74228e-08, 0, 1, 0, 8.74228e-08, 0, -1, {x}, {y}, {z})",
    270: "Transform3D(-4.37114e-08, 0, 1, 0, 1, 0, -1, 0, -4.37114e-08, {x}, {y}, {z})",
}


def axis_name(value: int) -> str:
    if value == 0:
        return "Zero"
    return ("Neg" if value < 0 else "Pos") + str(abs(value))


def transform(x: float, y: float, z: float, rotation: int = 0, scale: float = 1.0) -> str:
    if scale == 1.0:
        return ROTATIONS[rotation % 360].format(x=fmt(x), y=fmt(y), z=fmt(z))
    # Scale with yaw only where visual detail pieces do not need exact collision math.
    if rotation % 360 == 0:
        return f"Transform3D({fmt(scale)}, 0, 0, 0, {fmt(scale)}, 0, 0, 0, {fmt(scale)}, {fmt(x)}, {fmt(y)}, {fmt(z)})"
    s = fmt(scale)
    ns = fmt(-scale)
    if rotation % 360 == 90:
        return f"Transform3D(0, 0, {ns}, 0, {s}, 0, {s}, 0, 0, {fmt(x)}, {fmt(y)}, {fmt(z)})"
    if rotation % 360 == 180:
        return f"Transform3D({ns}, 0, 0, 0, {s}, 0, 0, 0, {ns}, {fmt(x)}, {fmt(y)}, {fmt(z)})"
    return f"Transform3D(0, 0, {s}, 0, {s}, 0, {ns}, 0, 0, {fmt(x)}, {fmt(y)}, {fmt(z)})"


def fmt(value: float | int) -> str:
    if isinstance(value, str):
        return value
    if abs(float(value) - int(value)) < 1e-6:
        return str(int(value))
    return ("%.3f" % float(value)).rstrip("0").rstrip(".")


def tile_coordinates() -> list[tuple[int, int]]:
    coords: set[tuple[int, int]] = set()

    # Central workshop: enough room for combat readability around Gizmo.
    for x in range(-4, 5, 2):
        for z in range(-4, 5, 2):
            coords.add((x, z))

    # North observatory approach and beacon dais.
    for z in (-6, -8, -10):
        for x in (-2, 0, 2):
            coords.add((x, z))
    for z, xs in {
        -12: (-4, -2, 0, 2, 4),
        -14: (-2, 0, 2),
    }.items():
        for x in xs:
            coords.add((x, z))

    # South landing/spawn runway: gives the player a calmer entry ramp.
    for z in (6, 8, 10):
        for x in (-2, 0, 2):
            coords.add((x, z))
    for z, xs in {
        12: (-4, -2, 0, 2, 4),
        14: (-2, 0, 2),
    }.items():
        for x in xs:
            coords.add((x, z))

    # East/west side alcoves for enemy paths, pickups, and future landmarks.
    for x in (-6, -8, -10):
        for z in (-2, 0, 2):
            coords.add((x, z))
    coords.update({(-12, 0), (-12, -2), (-12, 2)})
    for x in (6, 8, 10):
        for z in (-2, 0, 2):
            coords.add((x, z))
    coords.update({(12, 0), (12, -2), (12, 2)})

    # Broken diagonal pads: visible negative space between central plaza and corners.
    coords.update({
        (-6, -6), (-8, -6), (6, -6), (8, -6),
        (-6, 6), (-8, 6), (6, 6), (8, 6),
    })
    return sorted(coords, key=lambda item: (item[1], item[0]))


def tile_node(x: int, z: int, index: int) -> str:
    name = f"TileX{axis_name(x)}Z{axis_name(z)}"
    rotation = [0, 90, 180, 270][(x * 3 + z * 5 + index) % 4]
    variant = (abs(x // 2) + abs(z // 2) + index) % 3
    return f'''[node name="{name}" parent="ArenaTiles" instance=ExtResource("3_floor")]
transform = {transform(x, 0, z, rotation)}
visual_variant = {variant}
'''


def simple_node(name: str, parent: str, x: float, y: float, z: float) -> str:
    return f'''[node name="{name}" type="Node3D" parent="{parent}"]
transform = {transform(x, y, z)}
'''


def pylon_nodes() -> list[str]:
    pylons = [
        ("NorthBeaconPylon", 0, -18.6, 180),
        ("NorthWestWatchPylon", -6, -15, 90),
        ("NorthEastWatchPylon", 6, -15, 270),
        ("WestGatePylon", -15, 0, 90),
        ("EastGatePylon", 15, 0, 270),
        ("SouthLandingPylon", 0, 16, 0),
        ("SouthWestLandingPylon", -6, 15, 90),
        ("SouthEastLandingPylon", 6, 15, 270),
        ("NorthWestCornerPylon", -10, -8, 90),
        ("NorthEastCornerPylon", 10, -8, 270),
        ("SouthWestCornerPylon", -10, 8, 90),
        ("SouthEastCornerPylon", 10, 8, 270),
        ("WestAlcovePylon", -16, -2, 90),
        ("EastAlcovePylon", 16, 2, 270),
    ]
    return [f'''[node name="{name}" parent="ArenaTiles" instance=ExtResource("4_pylon")]
transform = {transform(x, 0, z, rot)}
''' for name, x, z, rot in pylons]


def debris_nodes() -> list[str]:
    debris = [
        ("DebrisNorthWestLarge", "12_debris_a", -10.5, -0.25, -12.4, 270, 0.82),
        ("DebrisNorthEastSmall", "13_debris_b", 10.8, -0.18, -12.0, 90, 0.92),
        ("DebrisWestBrokenGear", "12_debris_a", -14.0, -0.22, -5.8, 180, 0.68),
        ("DebrisEastBrokenGear", "13_debris_b", 14.2, -0.16, 5.8, 0, 0.86),
        ("DebrisSouthWestSmall", "13_debris_b", -9.5, -0.18, 12.8, 270, 0.78),
        ("DebrisSouthEastLarge", "12_debris_a", 9.8, -0.24, 12.6, 90, 0.72),
        ("DebrisWestAlcoveShard", "13_debris_b", -13.2, -0.12, 3.8, 180, 0.62),
        ("DebrisEastAlcoveShard", "13_debris_b", 13.4, -0.12, -3.8, 0, 0.62),
        ("DebrisNorthDaisLeft", "13_debris_b", -4.8, -0.12, -16.8, 90, 0.58),
        ("DebrisNorthDaisRight", "13_debris_b", 4.8, -0.12, -16.8, 270, 0.58),
        ("DebrisSouthLandingLeft", "12_debris_a", -4.8, -0.24, 16.8, 90, 0.52),
        ("DebrisSouthLandingRight", "12_debris_a", 4.8, -0.24, 16.8, 270, 0.52),
    ]
    return [f'''[node name="{name}" parent="ArenaTiles" instance=ExtResource("{res}")]
transform = {transform(x, y, z, rot, scale)}
''' for name, res, x, y, z, rot, scale in debris]


def build_arena_block() -> str:
    lines = [ARENA_BEGIN_MARKER + "\n", ARENA_NODE_HEADER + "\n"]
    lines.append('''[node name="IslandFoundation" parent="ArenaTiles" instance=ExtResource("11_island")]
transform = Transform3D(1.25, 0, 0, 0, 1.25, 0, 0, 0, 1.25, 0, -0.42, 0)
''')
    lines.append('''[node name="NorthDestinationBeacon" parent="ArenaTiles" instance=ExtResource("14_beacon")]
transform = Transform3D(0.72, 0, 0, 0, 0.72, 0, 0, 0, 0.72, 0, 0, -16.2)
''')
    lines.append('''[node name="LevelZones" type="Node3D" parent="ArenaTiles"]
''')
    for name, x, z in [
        ("SouthLandingZone", 0, 12),
        ("CentralGearPlazaZone", 0, 0),
        ("NorthBeaconDaisZone", 0, -13),
        ("WestScrapAlcoveZone", -10, 0),
        ("EastGearAlcoveZone", 10, 0),
    ]:
        lines.append(simple_node(name, "ArenaTiles/LevelZones", x, 0, z))
    for i, (x, z) in enumerate(tile_coordinates()):
        lines.append(tile_node(x, z, i))
    lines.extend(pylon_nodes())
    lines.extend(debris_nodes())
    lines.append(ARENA_END_MARKER + "\n")
    return "\n".join(lines).rstrip() + "\n"


def ensure_ext_resource(text: str, line: str, before: str) -> str:
    if line in text:
        return text
    return text.replace(before, line + "\n" + before)


def update_load_steps(text: str, load_steps: int) -> str:
    return re.sub(r"\[gd_scene load_steps=\d+ ", f"[gd_scene load_steps={load_steps} ", text, count=1)


def replace_arena_block(text: str, arena_block: str) -> str:
    if ARENA_BEGIN_MARKER in text and ARENA_END_MARKER in text:
        start = text.index(ARENA_BEGIN_MARKER)
        end = text.index(ARENA_END_MARKER, start) + len(ARENA_END_MARKER)
        if end < len(text) and text[end] == "\n":
            end += 1
        return text[:start] + arena_block + text[end:]

    if ARENA_NODE_HEADER not in text:
        raise ValueError(f"Missing arena node header: {ARENA_NODE_HEADER}")
    if GIZMO_NODE_PREFIX not in text:
        raise ValueError(f"Missing Gizmo node anchor: {GIZMO_NODE_PREFIX}")
    start = text.index(ARENA_NODE_HEADER)
    end = text.index(GIZMO_NODE_PREFIX, start)
    return text[:start] + arena_block + text[end:]


def main() -> None:
    text = MAIN.read_text()
    text = update_load_steps(text, 19)
    text = ensure_ext_resource(text, '[ext_resource type="PackedScene" path="res://scenes/world_kits/clockwork_observatory/clockwork_island_base_01.tscn" id="11_island"]', '[ext_resource type="Shader" path="res://shaders/cosmos_sky.gdshader" id="5_sky"]')
    text = ensure_ext_resource(text, '[ext_resource type="PackedScene" path="res://scenes/world_kits/clockwork_observatory/clockwork_debris_01.tscn" id="12_debris_a"]', '[ext_resource type="Shader" path="res://shaders/cosmos_sky.gdshader" id="5_sky"]')
    text = ensure_ext_resource(text, '[ext_resource type="PackedScene" path="res://scenes/world_kits/clockwork_observatory/clockwork_debris_02.tscn" id="13_debris_b"]', '[ext_resource type="Shader" path="res://shaders/cosmos_sky.gdshader" id="5_sky"]')
    text = ensure_ext_resource(text, '[ext_resource type="PackedScene" path="res://scenes/world_kits/clockwork_observatory/clockwork_north_beacon_01.tscn" id="14_beacon"]', '[ext_resource type="Shader" path="res://shaders/cosmos_sky.gdshader" id="5_sky"]')
    text = text.replace("size = Vector2(20, 20)", "size = Vector2(48, 48)", 1)
    text = replace_arena_block(text, build_arena_block())
    MAIN.write_text(text)
    print(f"wrote {MAIN} with {len(tile_coordinates())} floor tiles, 14 pylons, 12 debris pieces")


if __name__ == "__main__":
    main()
