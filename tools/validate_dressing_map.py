#!/usr/bin/env python3
"""Validate a baked dressing map against the promoted dressing grammar.

Enforces canon/dressing-grammar.yaml (gates L4/L8/L9/L10/L11) via its derived
machine handoff witnesses/dressing-grammar.handoff.json. Two modes:

    python3 validators/validate_dressing_map.py            # grammar self-check only
    python3 validators/validate_dressing_map.py MAP.json   # self-check + reject a bad map

Stdlib only (ADR 0003). Returns a report; exit 0 = accept, 1 = reject.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GRAMMAR_PATH = ROOT / "docs" / "reference" / "dressing-grammar.json"

TEAL_WORDS = ("teal", "cyan")


class Report:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.oks: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def ok(self, message: str) -> None:
        self.oks.append(message)

    @property
    def passed(self) -> bool:
        return not self.errors


def load_grammar(path: Path = GRAMMAR_PATH) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


# ── grammar self-check ────────────────────────────────────────────────────────

def validate_grammar(grammar: dict, report: Report) -> None:
    for key in ("bands", "cluster_archetypes", "room_archetypes", "regions", "accent_rules"):
        if key not in grammar:
            report.error(f"grammar missing section: {key}")
    if not report.passed:
        return

    archetypes = grammar["cluster_archetypes"]
    for name, spec in archetypes.items():
        if not spec.get("members"):
            report.error(f"cluster archetype {name} has no members")
        if spec.get("height_class") not in grammar.get("height_classes", []):
            report.error(f"cluster archetype {name} has unknown height_class")

    for name, policy in grammar["room_archetypes"].items():
        for counted in ("debris_scatter", "vertical_punctuation"):
            band = policy.get(counted)
            if not (isinstance(band, list) and len(band) == 2 and band[0] <= band[1]):
                report.error(f"room archetype {name}: bad density band for {counted}")
        if policy.get("cover_budget", -1) < 0:
            report.error(f"room archetype {name}: missing cover_budget")

    # Defacement must be monotonic with threat (design-system B-face ladder).
    deface_at_threat: dict[int, int] = {}
    for region in grammar["regions"].values():
        deface_at_threat.setdefault(region["threat"], region["defacement"])
    ordered = sorted(deface_at_threat.items())
    for (t1, d1), (t2, d2) in zip(ordered, ordered[1:]):
        if d2 < d1:
            report.error(f"defacement not monotonic with threat ({t1}:{d1} -> {t2}:{d2})")
    if report.passed:
        report.ok(
            f"grammar self-check: {len(archetypes)} archetypes, "
            f"{len(grammar['room_archetypes'])} room archetypes, {len(grammar['regions'])} regions"
        )


# ── dressing map checks ───────────────────────────────────────────────────────

def _band(nx: float, nz: float, bands: dict) -> str:
    r = max(abs(nx), abs(nz))
    if r <= bands["combat_core"]["r_max"]:
        return "combat_core"
    if r <= bands["mid_band"]["r_max"]:
        return "mid_band"
    return "perimeter_band"


def _in_apron(nx: float, nz: float, points: list[dict], radius: float) -> bool:
    return any(
        max(abs(nx - p["nx"]), abs(nz - p["nz"])) <= radius for p in points
    )


def _is_teal(accent: str) -> bool:
    lowered = accent.lower()
    return any(word in lowered for word in TEAL_WORDS)


def validate_room(room: dict, grammar: dict, report: Report) -> None:
    rid = room.get("id", "<room>")
    bands = grammar["bands"]
    archetypes = grammar["cluster_archetypes"]

    room_archetype = grammar["room_archetypes"].get(room.get("room_archetype"))
    if room_archetype is None:
        report.error(f"{rid}: unknown room archetype {room.get('room_archetype')!r}")
        return
    region = grammar["regions"].get(room.get("region"))
    if region is None:
        report.error(f"{rid}: unknown region {room.get('region')!r}")
        return

    apron_points = list(room.get("doors", []))
    if room.get("spawn"):
        apron_points.append(room["spawn"])
    apron_radius = bands["door_apron_radius"]

    counts: dict[str, int] = {}
    core_cover = 0
    landmarks: list[dict] = []

    for placement in room.get("placements", []):
        arch_name = placement.get("cluster_archetype")
        spec = archetypes.get(arch_name)
        where = f"{rid}:{placement.get('asset', '?')}"
        if spec is None:
            report.error(f"{where}: unknown cluster archetype {arch_name!r}")
            continue
        counts[arch_name] = counts.get(arch_name, 0) + 1

        if placement.get("asset") not in spec["members"]:
            report.error(f"{where}: asset is not a member of archetype {arch_name}")
        if placement.get("height_class") != spec["height_class"]:
            report.error(f"{where}: height_class must be {spec['height_class']}")

        nx, nz = float(placement.get("nx", 0.0)), float(placement.get("nz", 0.0))
        in_apron = _in_apron(nx, nz, apron_points, apron_radius)
        band = _band(nx, nz, bands)

        # door_aprons_stay_clear
        if in_apron and arch_name != "threshold_frame":
            report.error(f"{where}: non-threshold placement inside a door/spawn apron")
        if arch_name == "threshold_frame" and not in_apron:
            report.error(f"{where}: threshold_frame outside any door apron (fakes a crossing)")

        # dressing_never_blocks_combat_core
        if band == "combat_core" and not in_apron:
            if arch_name == "cover_block":
                core_cover += 1
            elif arch_name != "ground_read":
                report.error(f"{where}: {arch_name} inside combat_core")
            if spec["height_class"] == "tall":
                report.error(f"{where}: tall piece inside combat_core")

        # band licensing (thresholds handled by the apron clause above)
        if arch_name != "threshold_frame" and band not in spec["allowed_bands"] and not in_apron:
            report.error(f"{where}: {arch_name} not licensed in {band}")

        # camera_arc_stays_low
        if nz > bands["camera_near_arc_nz"]:
            if spec["height_class"] == "tall":
                report.error(f"{where}: tall piece on the camera-near arc (nz={nz})")
            elif spec["height_class"] == "mid" and abs(nx) <= bands["perimeter_corner_nx"]:
                report.error(f"{where}: mid piece on the camera-near arc outside a perimeter corner")

        # region_palette_is_bound
        accent = placement.get("accent")
        if accent is not None:
            if accent not in region["palette"]:
                report.error(f"{where}: accent {accent!r} not in {room['region']} palette")
            if _is_teal(accent) and placement.get("asset") not in grammar["accent_rules"]["teal_exception_assets"]:
                report.error(f"{where}: teal-family accent on dressing (reserved by design-system B-light)")

        if arch_name == "landmark_anchor":
            landmarks.append(placement)
            if placement.get("asset") == "beacon_01" and room.get("region") != "NULL":
                report.error(f"{where}: beacon_01 outside the NULL region")
            if placement.get("asset") == "sanctuary_01" and room.get("room_archetype") != "rest_alcove":
                report.error(f"{where}: sanctuary_01 outside a rest_alcove room")

    # one_landmark_anchor_per_room
    if len(landmarks) != 1:
        report.error(f"{rid}: expected exactly 1 landmark_anchor, found {len(landmarks)}")
    else:
        landmark = landmarks[0]
        entry = room.get("entry_door")
        if entry is not None:
            # far half along the entry door's dominant axis
            if abs(entry["nx"]) >= abs(entry["nz"]):
                axis, sign = "nx", entry["nx"]
            else:
                axis, sign = "nz", entry["nz"]
            if float(landmark.get(axis, 0.0)) * sign > 0:
                report.error(f"{rid}: landmark_anchor on the entry half, not the far arc")
        must_be = room_archetype.get("landmark_must_be")
        if must_be and landmark.get("asset") != must_be:
            report.error(f"{rid}: landmark must be {must_be}, found {landmark.get('asset')!r}")

    # density_stays_inside_the_band
    for counted in ("debris_scatter", "vertical_punctuation"):
        low, high = room_archetype[counted]
        n = counts.get(counted, 0)
        if not (low <= n <= high):
            report.error(f"{rid}: {counted} count {n} outside band [{low}, {high}]")
    if core_cover > room_archetype["cover_budget"]:
        report.error(f"{rid}: cover in combat_core {core_cover} exceeds budget {room_archetype['cover_budget']}")


def validate_map(dressing_map: dict, grammar: dict, report: Report) -> None:
    rooms = dressing_map.get("rooms")
    if not isinstance(rooms, list) or not rooms:
        report.error("dressing map has no rooms")
        return
    for room in rooms:
        validate_room(room, grammar, report)
    if report.passed:
        report.ok(f"dressing map accepted: {len(rooms)} rooms")


def main(argv: list[str]) -> int:
    report = Report()
    grammar = load_grammar()
    validate_grammar(grammar, report)
    if report.passed and len(argv) > 1:
        dressing_map = json.loads(Path(argv[1]).read_text(encoding="utf-8"))
        validate_map(dressing_map, grammar, report)
    for message in report.oks:
        print(f"ok: {message}")
    for message in report.errors:
        print(f"REJECT: {message}")
    print("RESULT:", "ACCEPT" if report.passed else "REJECT")
    return 0 if report.passed else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
