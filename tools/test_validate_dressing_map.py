"""Tests for validate_dressing_map: the grammar must ACCEPT a lawful dressing
map and REJECT each class of bad map its promoted rules name."""
from __future__ import annotations

import copy
import unittest

from validate_dressing_map import Report, load_grammar, validate_grammar, validate_map


def good_room() -> dict:
    """A lawful combat_small room in BRASS: entry south (-z), landmark far-west,
    debris x2 (mid band), one cover in core, one vertical on the perimeter."""
    return {
        "id": "room_good",
        "room_archetype": "combat_small",
        "region": "BRASS",
        "doors": [{"nx": 0.0, "nz": -1.0}, {"nx": 1.0, "nz": 0.2}],
        "entry_door": {"nx": 0.0, "nz": -1.0},
        "spawn": {"nx": 0.0, "nz": -0.6},
        "placements": [
            {"cluster_archetype": "landmark_anchor", "asset": "spire_01",
             "nx": -0.9, "nz": 0.3, "height_class": "tall", "accent": "gold brass"},
            {"cluster_archetype": "debris_scatter", "asset": "debris_cluster_01",
             "nx": 0.7, "nz": -0.4, "height_class": "low"},
            {"cluster_archetype": "debris_scatter", "asset": "scrap_cluster_01",
             "nx": -0.7, "nz": -0.3, "height_class": "low"},
            {"cluster_archetype": "cover_block", "asset": "scrap_cluster_01",
             "nx": 0.3, "nz": 0.2, "height_class": "mid"},
            {"cluster_archetype": "vertical_punctuation", "asset": "gear_ring_01",
             "nx": 0.9, "nz": -0.7, "height_class": "mid"},
            {"cluster_archetype": "threshold_frame", "asset": "gear_gate_01",
             "nx": 0.05, "nz": -0.95, "height_class": "tall"},
        ],
    }


def run(dressing_map: dict) -> Report:
    report = Report()
    grammar = load_grammar()
    validate_grammar(grammar, report)
    validate_map(dressing_map, grammar, report)
    return report


class GrammarSelfCheck(unittest.TestCase):
    def test_shipped_grammar_is_internally_consistent(self) -> None:
        report = Report()
        validate_grammar(load_grammar(), report)
        self.assertTrue(report.passed, report.errors)


class DressingMapAcceptance(unittest.TestCase):
    def test_lawful_map_is_accepted(self) -> None:
        report = run({"rooms": [good_room()]})
        self.assertTrue(report.passed, report.errors)

    def assert_rejects(self, room: dict, fragment: str) -> None:
        report = run({"rooms": [room]})
        self.assertFalse(report.passed)
        self.assertTrue(any(fragment in e for e in report.errors), report.errors)

    def test_rejects_scatter_in_combat_core(self) -> None:
        room = good_room()
        room["placements"][1]["nx"] = 0.1
        room["placements"][1]["nz"] = 0.1
        self.assert_rejects(room, "inside combat_core")

    def test_rejects_cover_over_budget(self) -> None:
        room = good_room()
        for nx in (0.1, -0.2, 0.2):
            room["placements"].append(
                {"cluster_archetype": "cover_block", "asset": "platform_small_01",
                 "nx": nx, "nz": 0.0, "height_class": "mid"})
        self.assert_rejects(room, "exceeds budget")

    def test_rejects_dressing_in_door_apron(self) -> None:
        room = good_room()
        room["placements"][1]["nx"] = 0.95
        room["placements"][1]["nz"] = 0.25
        self.assert_rejects(room, "apron")

    def test_rejects_threshold_frame_faking_a_crossing(self) -> None:
        room = good_room()
        room["placements"][5]["nx"] = -0.5
        room["placements"][5]["nz"] = 0.5
        self.assert_rejects(room, "fakes a crossing")

    def test_rejects_missing_landmark(self) -> None:
        room = good_room()
        del room["placements"][0]
        self.assert_rejects(room, "exactly 1 landmark_anchor")

    def test_rejects_second_landmark(self) -> None:
        room = good_room()
        second = copy.deepcopy(room["placements"][0])
        second["nx"] = 0.9
        second["nz"] = -0.9
        room["placements"].append(second)
        self.assert_rejects(room, "exactly 1 landmark_anchor")

    def test_rejects_landmark_on_entry_half(self) -> None:
        room = good_room()
        room["placements"][0]["nx"] = -0.9
        room["placements"][0]["nz"] = -0.85
        self.assert_rejects(room, "entry half")

    def test_rejects_tall_on_camera_arc(self) -> None:
        room = good_room()
        room["placements"][0]["nz"] = 0.9
        self.assert_rejects(room, "camera-near arc")

    def test_rejects_beacon_outside_null(self) -> None:
        room = good_room()
        room["placements"][0]["asset"] = "beacon_01"
        self.assert_rejects(room, "beacon_01 outside the NULL region")

    def test_rejects_rest_alcove_without_sanctuary(self) -> None:
        room = good_room()
        room["room_archetype"] = "rest_alcove"
        room["placements"] = [room["placements"][0]]  # spire landmark only
        self.assert_rejects(room, "landmark must be sanctuary_01")

    def test_rejects_teal_accent_on_dressing(self) -> None:
        room = good_room()
        room["placements"][0]["accent"] = "sky teal"
        self.assert_rejects(room, "teal-family accent")

    def test_rejects_accent_outside_region_palette(self) -> None:
        room = good_room()
        room["placements"][0]["accent"] = "hot pink"
        self.assert_rejects(room, "not in BRASS palette")

    def test_rejects_density_outside_band(self) -> None:
        room = good_room()
        room["placements"] = [p for p in room["placements"]
                              if p["cluster_archetype"] != "debris_scatter"]
        self.assert_rejects(room, "outside band")

    def test_rejects_unknown_region_and_archetype(self) -> None:
        room = good_room()
        room["region"] = "ATLANTIS"
        self.assert_rejects(room, "unknown region")
        room = good_room()
        room["placements"][0]["cluster_archetype"] = "confetti"
        self.assert_rejects(room, "unknown cluster archetype")

    def test_rejects_asset_not_in_archetype(self) -> None:
        room = good_room()
        room["placements"][1]["asset"] = "spire_01"
        self.assert_rejects(room, "not a member")


if __name__ == "__main__":
    unittest.main()
