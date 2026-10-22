#!/usr/bin/env python3
"""Reader and evidence regressions; no spreadsheet engine or third-party import."""
import importlib.util
import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location("artifact_lane", Path(__file__).with_name("run.py"))
lane = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lane)


class CellEvidenceTests(unittest.TestCase):
    def parse(self, content, kind="n"):
        node = ET.fromstring(f'<c xmlns="{lane.NS["s"]}" r="A1" t="{kind}">{content}</c>')
        return lane.parse_cell(node, [])

    def test_missing_formula_cache_cannot_become_zero(self):
        cell = self.parse("<f>SUM(B1:B3)</f>")
        self.assertIsNone(cell["value"])
        self.assertEqual(cell["formula"], "SUM(B1:B3)")
        with self.assertRaises(AssertionError):
            lane.equal(cell["value"], 0, "cached result")

    def test_invalid_numeric_cache_is_rejected(self):
        for value in ["not-a-number", "NaN", "Infinity"]:
            with self.subTest(value=value), self.assertRaises((AssertionError, ValueError)):
                self.parse(f"<f>SUM(B1:B3)</f><v>{value}</v>")

    def test_exact_identifier_survives_without_numeric_coercion(self):
        value = "00012345678901234567890"
        cell = self.parse(f"<v>{value}</v>", "str")
        self.assertEqual(cell["type"], "text")
        lane.equal(cell["value"], value, "identifier")
        with self.assertRaises(AssertionError):
            lane.equal(float(value), value, "rounded identifier")

    def test_boolean_cannot_satisfy_numeric_assertion(self):
        with self.assertRaises(AssertionError):
            lane.equal(self.parse("<v>1</v>", "b")["value"], 1, "numeric result")

    def test_text_looking_like_formula_stays_literal(self):
        cell = self.parse("<v>=1+1</v>", "str")
        self.assertEqual(cell["value"], "=1+1")
        self.assertIsNone(cell["formula"])


class SemanticEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(Path(__file__).with_name("inputs.json").read_text())
        self.state = self.data["capacity"]["states"][0]
        values = {"B3": 4, "B4": 4800, "B5": 1, "B6": "Base", "B7": 1200,
                  "B8": 4, "B9": 1500, "B11": 1200, "B12": 1700,
                  "B17": 1000, "B18": 4200}
        self.cells = {address: {"value": value, "formula": None,
                               "type": "text" if isinstance(value, str) else "number"}
                      for address, value in values.items()}
        for address, formula in {
            "B3": 'IF(ISNUMBER(B7),ROUNDUP(B4/B9,0),"Missing volume")',
            "B4": 'IF(ISNUMBER(B7),B7*B8,"Missing volume")',
            "B6": 'CHOOSE($B$5,"Base","Peak")',
            "B7": 'IF(CHOOSE($B$5,ISBLANK(B11),ISBLANK(B12)),"Missing volume",CHOOSE($B$5,B11,B12))',
        }.items():
            self.cells[address]["formula"] = formula

    def check(self, cells=None, state=None, **kwargs):
        cells = self.cells if cells is None else cells
        book = SimpleNamespace(cell=lambda sheet, address: cells[address], error_cells=lambda: [])
        with patch.object(lane, "Workbook", return_value=book):
            return lane.check_capacity(Path("unused.xlsx"), self.data, state or self.state, **kwargs)

    def test_valid_capacity_fixture_passes(self):
        self.assertTrue(self.check()["inputs_and_formulas_verified"])

    def test_correct_caches_cannot_hide_changed_drivers(self):
        for address in ["B5", "B8", "B9", "B11", "B12", "B17", "B18"]:
            changed = copy.deepcopy(self.cells)
            changed[address]["value"] += 1
            with self.subTest(address=address), self.assertRaisesRegex(AssertionError, "input"):
                self.check(changed)

    def test_correct_caches_cannot_hide_wrong_formulas(self):
        for address in ["B3", "B4", "B6", "B7"]:
            changed = copy.deepcopy(self.cells)
            changed[address]["formula"] = "1+1"
            with self.subTest(address=address), self.assertRaisesRegex(AssertionError, "formula"):
                self.check(changed)

    def test_driver_formula_or_text_type_cannot_pass_with_numeric_cache(self):
        for modification in [{"formula": "2+2"}, {"type": "text"}]:
            changed = copy.deepcopy(self.cells)
            changed["B8"].update(modification)
            with self.subTest(modification=modification), self.assertRaisesRegex(AssertionError, "input"):
                self.check(changed)

    def test_empty_string_probe_still_tests_zero_semantics(self):
        changed = copy.deepcopy(self.cells)
        changed["B11"]["value"] = 0
        changed["B7"]["formula"] = 'IF(CHOOSE($B$5,B11="",B12=""),"Missing volume",CHOOSE($B$5,B11,B12))'
        for address in ["B3", "B4", "B7"]:
            changed[address].update(value="Missing volume", type="text")
        state = next(s for s in self.data["capacity"]["states"] if s["id"] == "zero")
        with self.assertRaisesRegex(AssertionError, "expected 0, observed 'Missing volume'"):
            self.check(changed, state, empty_string_probe=True)

    def test_preservation_detects_lost_row_properties(self):
        def book(attributes):
            # In-memory reader facts; no workbook authoring runtime is involved.
            item = object.__new__(lane.Workbook)
            node = ET.fromstring(f'<worksheet xmlns="{lane.NS["s"]}"><sheetData><row {attributes}/></sheetData></worksheet>')
            item.sheet_states = [("Records", "visible")]
            item.parts = {"xl/worksheets/sheet1.xml": b""}
            item.sheets = {"Records": {}}
            item.sheet_nodes = {"Records": node}
            item.sheet_paths = {"Records": "xl/worksheets/sheet1.xml"}
            return item

        for property_name, value in [("ht", "31"), ("customHeight", "1"), ("hidden", "1"),
                                     ("s", "2"), ("customFormat", "1"), ("outlineLevel", "1")]:
            before, after = book(f'r="1" {property_name}="{value}"'), book('r="1"')
            with self.subTest(property_name=property_name), patch.object(lane, "Workbook", side_effect=[before, after]):
                with self.assertRaisesRegex(AssertionError, "row properties"):
                    lane.check_preservation(Path("before.xlsx"), Path("after.xlsx"), False)


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.sources, self.skill, self.output = root / "sources", root / "skill", root / "run"
        for folder in [self.sources, self.skill, self.output]:
            folder.mkdir()
        (self.skill / "SKILL.md").write_text("test skill")
        (self.sources / "run.py").write_text("test runner")
        (self.sources / "build.mjs").write_text("test builder")
        (self.sources / "inputs.json").write_text(json.dumps({"capacity": {"states": []}}))
        (self.output / "proof.txt").write_text("observed evidence")
        self.report = {"schema_version": 1, "skill_tree_sha256": lane.tree_digest(self.skill),
                       "sources": {name: lane.digest(self.sources / name) for name in ["run.py", "build.mjs", "inputs.json"]},
                       "files": {"proof.txt": lane.digest(self.output / "proof.txt")},
                       "checks": [{"id": "authoring-runtime", "status": "BLOCKED"}], "status": "BLOCKED"}
        self.patches = [patch.object(lane, "HERE", self.sources), patch.object(lane, "SKILL", self.skill)]
        for change in self.patches:
            change.start()

    def tearDown(self):
        for change in reversed(self.patches):
            change.stop()
        self.tmp.cleanup()

    def write(self):
        lane.write_json(self.output / "evidence.json", self.report)

    def test_blocked_run_remains_blocked(self):
        self.write()
        self.assertEqual(lane.verify(self.output)["status"], "BLOCKED")

    def test_modified_artifact_is_detected(self):
        self.write()
        (self.output / "proof.txt").write_text("changed after grading")
        with self.assertRaisesRegex(AssertionError, "artifact changed"):
            lane.verify(self.output)

    def test_omitted_artifact_binding_is_detected(self):
        self.report["files"] = {}
        self.write()
        with self.assertRaisesRegex(AssertionError, "inventory"):
            lane.verify(self.output)

    def test_modified_skill_cannot_reuse_old_evidence(self):
        self.write()
        (self.skill / "SKILL.md").write_text("new candidate")
        with self.assertRaisesRegex(AssertionError, "skill tree changed"):
            lane.verify(self.output)

    def test_pass_summary_cannot_mask_blocked_gate(self):
        self.report["status"] = "PASS"
        self.write()
        with self.assertRaisesRegex(AssertionError, "contradicts"):
            lane.verify(self.output)

    def test_forged_incomplete_pass_is_rejected(self):
        self.report["status"] = "PASS"
        self.report["checks"][0]["status"] = "PASS"
        self.write()
        with self.assertRaisesRegex(AssertionError, "coverage"):
            lane.verify(self.output)


if __name__ == "__main__":
    unittest.main()
