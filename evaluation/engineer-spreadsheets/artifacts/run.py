#!/usr/bin/env python3
"""Bounded runtime qualification; never a model-behavior or native Excel score.

Python is an independent ZIP/XML reader, not a workbook author. All workbook
creation and mutation is performed by build.mjs through artifact-tool.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[2]
SKILL = PROJECT / "engineer-spreadsheets"
NS = {"s": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
PKG = "http://schemas.openxmlformats.org/package/2006/relationships"
PREVIEWS = ("typed-records.png", "roundtrip.png", "edit.png", "capacity-base.png",
            "capacity-missing-selected.png", "cf-probe.png", "cf-probe-roundtrip.png")


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tree_digest(root: Path) -> str:
    entries = [(p.relative_to(root).as_posix(), digest(p))
               for p in sorted(root.rglob("*")) if p.is_file()]
    return hashlib.sha256("".join(f"{p}\0{h}\n" for p, h in entries).encode()).hexdigest()


def write_json(path: Path, data: object) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False, allow_nan=False) + "\n")


def parse_cell(cell: ET.Element, shared_strings: list[str]) -> dict:
    kind = cell.get("t", "n")
    require(kind in {"s", "inlineStr", "d", "str", "e", "b", "n"}, "unknown cell type")
    value = cell.find("s:v", NS)
    raw = value.text if value is not None else None
    if kind == "s":
        parsed = shared_strings[int(raw)] if raw is not None else None
        normalized = "text"
    elif kind == "inlineStr":
        inline = cell.find("s:is", NS)
        parsed = "".join(inline.itertext()) if inline is not None else ""
        normalized = "text"
    elif kind == "d":
        parsed, normalized = raw, "date"
    elif kind in {"str", "e"}:
        parsed, normalized = raw, "text" if kind == "str" else "e"
    elif kind == "b":
        require(raw in {"0", "1"}, "invalid boolean cache")
        parsed, normalized = raw == "1", "boolean"
    elif raw is None:
        parsed, normalized = None, "empty"
    else:
        parsed, normalized = float(raw), "number"
        require(math.isfinite(parsed), "non-finite numeric cache")
    formula = cell.find("s:f", NS)
    return {"value": parsed, "type": normalized,
            "formula": formula.text if formula is not None else None,
            "style": cell.get("s", "0")}


class Workbook:
    """Read only OOXML facts independently from the producing runtime."""
    def __init__(self, path: Path):
        with zipfile.ZipFile(path) as archive:
            names = archive.namelist()
            if len(names) != len(set(names)):
                raise ValueError("duplicate ZIP members")
            if sum(item.file_size for item in archive.infolist()) > 16_000_000:
                raise ValueError("fixture exceeds bounded reader size")
            self.parts = {name: archive.read(name) for name in names}
        self.strings = []
        if "xl/sharedStrings.xml" in self.parts:
            self.strings = ["".join(si.itertext()) for si in self.xml("xl/sharedStrings.xml")]
        book = self.xml("xl/workbook.xml")
        props = book.find("s:workbookPr", NS)
        self.date1904 = props is not None and props.get("date1904") in {"1", "true"}
        rels = {r.get("Id"): r for r in self.xml("xl/_rels/workbook.xml.rels")}
        self.sheets = {}
        self.sheet_nodes = {}
        self.sheet_paths = {}
        self.sheet_states = []
        for sheet in book.find("s:sheets", NS):
            rel = rels[sheet.get(f"{{{R}}}id")]
            if rel.get("TargetMode") == "External":
                raise ValueError("external sheet relationship")
            target = rel.get("Target")
            member = target.lstrip("/") if target.startswith("/") else str(PurePosixPath("xl") / target)
            if ".." in PurePosixPath(member).parts:
                raise ValueError("unexpected parent traversal in sheet relationship")
            node = self.xml(member)
            self.sheet_paths[sheet.get("name")] = member
            self.sheet_nodes[sheet.get("name")] = node
            cells = {}
            for c in node.findall(".//s:sheetData/s:row/s:c", NS):
                cells[c.get("r")] = parse_cell(c, self.strings)
            name = sheet.get("name")
            self.sheets[name] = cells
            self.sheet_states.append((name, sheet.get("state", "visible")))

    def xml(self, member: str) -> ET.Element:
        return ET.fromstring(self.parts[member])

    def cell(self, sheet: str, address: str) -> dict:
        return self.sheets[sheet].get(address, {"value": None, "type": "empty", "formula": None, "style": "0"})

    def signature(self, member: str, node: ET.Element | None = None) -> object:
        """Compare relationship meaning, not writer-assigned relationship IDs."""
        part = PurePosixPath(member)
        relpath = str(part.parent / "_rels" / (part.name + ".rels"))
        relationships = {}
        if relpath in self.parts:
            for relationship in self.xml(relpath):
                relationships[relationship.get("Id")] = sorted(
                    (key, value) for key, value in relationship.attrib.items() if key != "Id")

        def visit(item):
            attrs = []
            for key, value in sorted(item.attrib.items()):
                if item.tag == f"{{{PKG}}}Relationship" and key == "Id":
                    continue
                if key.startswith(f"{{{R}}}"):
                    require(value in relationships, f"unresolved relationship {value} in {member}")
                    value = relationships[value]
                attrs.append((key, value))
            children = [visit(child) for child in item]
            if item.tag == f"{{{PKG}}}Relationships":
                children.sort(key=lambda value: json.dumps(value, sort_keys=True))
            return [item.tag, attrs, item.text or "", children]
        return visit(self.xml(member) if node is None else node)

    def error_cells(self) -> list[str]:
        return [f"{name}!{address}" for name, cells in self.sheets.items()
                for address, cell in cells.items() if cell["type"] == "e"]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def equal(actual: object, expected: object, label: str) -> None:
    if isinstance(expected, (int, float)) and not isinstance(expected, bool):
        require(isinstance(actual, (int, float)) and not isinstance(actual, bool)
                and math.isclose(actual, expected, rel_tol=1e-12, abs_tol=1e-9),
                f"{label}: expected {expected!r}, observed {actual!r}")
    else:
        require(type(actual) is type(expected) and actual == expected,
                f"{label}: expected {expected!r}, observed {actual!r}")


def check_records(path: Path, data: dict, edited: bool = False) -> dict:
    wb = Workbook(path)
    equal(wb.sheet_states, [("Records", "visible")], "sheet identity/order")
    require(not wb.error_cells(), f"formula errors: {wb.error_cells()}")
    for row, record in enumerate(data["records"], 5):
        for col, key in [("A", "id"), ("D", "active"), ("E", "note")]:
            cell = wb.cell("Records", f"{col}{row}")
            equal(cell["value"], record[key], f"literal {col}{row}")
            require(cell["formula"] is None, f"literal {col}{row} became a formula")
        require(wb.cell("Records", f"A{row}")["type"] == "text", "identifier is not text")
        amount = data["narrow_edit"]["amount"] if edited and row == 6 else record["amount"]
        equal(wb.cell("Records", f"B{row}")["value"], amount, f"amount B{row}")
        date_cell = wb.cell("Records", f"C{row}")
        if date_cell["type"] == "date":
            equal(dt.datetime.fromisoformat(date_cell["value"].replace("Z", "+00:00")).date().isoformat(), record["date"], f"date C{row}")
        else:
            require(date_cell["type"] == "number", f"date C{row} is untyped text")
            epoch = dt.date(1904, 1, 1) if wb.date1904 else dt.date(1899, 12, 30)
            serial = (dt.date.fromisoformat(record["date"]) - epoch).days
            equal(date_cell["value"], serial, f"date C{row}")
    expected_total = sum(row["amount"] for row in data["records"])
    if edited:
        expected_total += data["narrow_edit"]["amount"] - data["records"][1]["amount"]
    equal(wb.cell("Records", "B10")["value"], expected_total, "total cached result")
    equal(wb.cell("Records", "B11")["value"], len(data["records"]), "count cached result")
    equal(wb.cell("Records", "B10")["formula"], "SUM(B5:B8)", "total formula")
    equal(wb.cell("Records", "B11")["formula"], "COUNT(B5:B8)", "count formula")
    return {"records": len(data["records"]), "total": expected_total, "formula_errors": []}


def check_capacity(path: Path, data: dict, state: dict, *, empty_string_probe: bool = False) -> dict:
    wb = Workbook(path)
    require(not wb.error_cells(), f"formula errors: {wb.error_cells()}")
    model = data["capacity"]
    # Correct cached outputs are insufficient when inputs or formulas were changed.
    # This bounded fixture intentionally checks exact formulas, not equivalence.
    drivers = {"B5": state["selector"], "B8": model["minutes_per_item"],
               "B9": model["minutes_per_person"], "B11": state["base_volume"],
               "B12": state["peak_volume"], "B17": model["actual_volume"],
               "B18": model["actual_minutes"]}
    for addr, expected in drivers.items():
        cell = wb.cell("Capacity", addr)
        equal(cell["value"], expected, f"{state['id']} input {addr}")
        equal(cell["type"], "empty" if expected is None else "number", f"{addr} input type")
        require(cell["formula"] is None, f"{addr} input became a formula")
    formulas = {
        "B3": 'IF(ISNUMBER(B7),ROUNDUP(B4/B9,0),"Missing volume")',
        "B4": 'IF(ISNUMBER(B7),B7*B8,"Missing volume")',
        "B6": 'CHOOSE($B$5,"Base","Peak")',
        "B7": ('IF(CHOOSE($B$5,B11="",B12=""),"Missing volume",CHOOSE($B$5,B11,B12))'
               if empty_string_probe else
               'IF(CHOOSE($B$5,ISBLANK(B11),ISBLANK(B12)),"Missing volume",CHOOSE($B$5,B11,B12))'),
    }
    for addr, expected in formulas.items():
        equal(wb.cell("Capacity", addr)["formula"], expected, f"{addr} formula")
    selected = state["base_volume"] if state["selector"] == 1 else state["peak_volume"]
    work = selected * model["minutes_per_item"] if selected is not None else "Missing volume"
    people = math.ceil(work / model["minutes_per_person"]) if selected is not None else "Missing volume"
    for addr, expected in {"B3": people, "B4": work, "B5": state["selector"],
                           "B6": "Base" if state["selector"] == 1 else "Peak",
                           "B7": selected if selected is not None else "Missing volume",
                           "B17": model["actual_volume"], "B18": model["actual_minutes"]}.items():
        equal(wb.cell("Capacity", addr)["value"], expected, f"{state['id']} {addr}")
    return {"state": state["id"], "people": people, "minutes": work,
            "actuals_unchanged": True, "inputs_and_formulas_verified": True}


def check_preservation(source: Path, output: Path, edited: bool) -> dict:
    before, after = Workbook(source), Workbook(output)
    equal(after.sheet_states, before.sheet_states, "sheet identity/order/visibility")
    equal(set(after.parts), set(before.parts), "package member inventory")
    for sheet, cells in before.sheets.items():
        equal(set(after.sheets[sheet]), set(cells), "populated cell inventory")
        for address, cell in cells.items():
            observed = dict(after.cell(sheet, address))
            expected = dict(cell)
            if edited and sheet == "Records" and address in {"B6", "B10"}:
                observed.pop("value")
                expected.pop("value")
            equal(observed, expected, f"preserved {sheet}!{address}")
        a, b = before.sheet_nodes[sheet], after.sheet_nodes[sheet]
        equal([dict(row.attrib) for row in b.findall("s:sheetData/s:row", NS)],
              [dict(row.attrib) for row in a.findall("s:sheetData/s:row", NS)],
              f"preserved {sheet} row properties")
        for tag in ["sheetViews", "sheetFormatPr", "cols", "mergeCells", "dataValidations",
                    "conditionalFormatting", "tableParts", "drawing", "sheetProtection"]:
            equal([after.signature(after.sheet_paths[sheet], n) for n in b.findall(f"s:{tag}", NS)],
                  [before.signature(before.sheet_paths[sheet], n) for n in a.findall(f"s:{tag}", NS)], f"preserved {tag}")
    checked_parts = []
    for member in before.parts:
        if member == "xl/styles.xml" or member.startswith(("xl/tables/", "xl/drawings/", "xl/charts/")) or member.endswith(".rels"):
            require(after.signature(member) == before.signature(member), f"preserved {member}: semantic XML changed")
            checked_parts.append(member)
    return {"permitted_changed_cells": ["Records!B6", "Records!B10"] if edited else [],
            "preserved_package_members": len(before.parts), "verified_feature_parts": checked_parts}


def command(argv: list[str], cwd: Path, timeout: int = 180, env: dict | None = None) -> dict:
    result = subprocess.run(argv, cwd=cwd, text=True, capture_output=True, timeout=timeout, check=False, env=env)
    return {"argv": argv, "exit_code": result.returncode,
            "stdout": result.stdout[-20000:], "stderr": result.stderr[-20000:]}


def check_rendering(output: Path) -> dict:
    dimensions = {}
    for name in PREVIEWS:
        raw = (output / name).read_bytes()
        require(len(raw) >= 24 and raw[:8] == b"\x89PNG\r\n\x1a\n", f"{name} is not PNG")
        width, height = struct.unpack(">II", raw[16:24])
        require(width > 100 and height > 100, f"{name} is implausibly small")
        dimensions[name] = [width, height]
    return dimensions


def execute(output: Path, skip_libreoffice: bool = False) -> int:
    output.mkdir(parents=True, exist_ok=False)  # Never consume stale artifacts.
    initial_skill_hash = tree_digest(SKILL)
    inputs = json.loads((HERE / "inputs.json").read_text())
    report = {"schema_version": 1, "lane": "scripted-runtime-qualification",
              "scope": "Typed OOXML, capacity input perturbations, bounded no-op/narrow-edit preservation, rendered PNGs. Not agent efficacy or native Excel qualification.",
              "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
              "skill_tree_sha256": initial_skill_hash,
              "sources": {name: digest(HERE / name) for name in ["run.py", "build.mjs", "inputs.json"]},
              "engines": {}, "checks": [], "files": {}, "commands": []}

    def check(name: str, action) -> bool:
        try:
            detail = action()
            report["checks"].append({"id": name, "status": "PASS", "detail": detail})
            return True
        except Exception as error:
            report["checks"].append({"id": name, "status": "FAIL", "detail": f"{type(error).__name__}: {error}"})
            return False

    def finish() -> int:
        if tree_digest(SKILL) != initial_skill_hash:
            report["checks"].append({"id": "unchanged-skill-binding", "status": "FAIL", "detail": "Skill changed during execution"})
        for path in sorted(output.rglob("*")):
            if path.is_file() and path.name != "evidence.json":
                report["files"][path.relative_to(output).as_posix()] = digest(path)
        statuses = {c["status"] for c in report["checks"]}
        report["status"] = "FAIL" if "FAIL" in statuses else "BLOCKED" if "BLOCKED" in statuses else "PASS"
        write_json(output / "evidence.json", report)
        print(json.dumps({"status": report["status"], "checks": len(report["checks"]), "evidence": str(output / "evidence.json")}))
        return {"PASS": 0, "FAIL": 1, "BLOCKED": 2}[report["status"]]

    node = os.environ.get("CODEX_PRIMARY_RUNTIME_NODE")
    modules = os.environ.get("CODEX_PRIMARY_RUNTIME_NODE_MODULES")
    if not node or not modules or not Path(node).is_file() or not (Path(modules) / "@oai/artifact-tool/package.json").is_file():
        report["checks"].append({"id": "authoring-runtime", "status": "BLOCKED", "detail": "Set CODEX_PRIMARY_RUNTIME_NODE and CODEX_PRIMARY_RUNTIME_NODE_MODULES to the approved runtime; no fallback authoring library is used."})
        return finish()
    report["engines"]["artifact_tool"] = json.loads((Path(modules) / "@oai/artifact-tool/package.json").read_text())["version"]
    with tempfile.TemporaryDirectory(prefix="engineer-spreadsheets-artifacts-") as tmp:
        temp = Path(tmp)
        (temp / "node_modules").symlink_to(modules, target_is_directory=True)
        shutil.copy2(HERE / "build.mjs", temp / "build.mjs")
        builds = [[node, str(temp / "build.mjs"), "build", str(HERE / "inputs.json"), str(output)],
                  [node, str(temp / "build.mjs"), "roundtrip", str(output / "typed-records.xlsx"), str(output)],
                  [node, str(temp / "build.mjs"), "edit", str(output / "typed-records.xlsx"), str(output), str(inputs["narrow_edit"]["amount"])],
                  [node, str(temp / "build.mjs"), "cf-probe", str(output / "typed-records.xlsx"), str(output)],
                  [node, str(temp / "build.mjs"), "cf-probe-roundtrip", str(output / "cf-probe.xlsx"), str(output)]]
        for i, argv in enumerate(builds):
            try:
                result = command(argv, temp)
            except Exception as error:
                report["checks"].append({"id": f"authoring-{i}", "status": "FAIL", "detail": str(error)})
                return finish()
            report["commands"].append(result)
            if result["exit_code"] != 0:
                report["checks"].append({"id": f"authoring-{i}", "status": "FAIL", "detail": result["stderr"][-3000:]})
                return finish()
            if i == 1 and not check("no-op-preservation", lambda: check_preservation(output / "typed-records.xlsx", output / "roundtrip.xlsx", False)):
                return finish()  # Do not edit an unqualified round-trip path.
    check("typed-literals", lambda: check_records(output / "typed-records.xlsx", inputs))
    check("narrow-edit-values", lambda: check_records(output / "edit.xlsx", inputs, True))
    check("narrow-edit-preservation", lambda: check_preservation(output / "typed-records.xlsx", output / "edit.xlsx", True))
    check("solid-fill-no-op-probe", lambda: check_preservation(output / "cf-probe.xlsx", output / "cf-probe-roundtrip.xlsx", False))
    for state in inputs["capacity"]["states"]:
        check("capacity-" + state["id"], lambda state=state: check_capacity(output / f"capacity-{state['id']}.xlsx", inputs, state))
    zero = next(state for state in inputs["capacity"]["states"] if state["id"] == "zero")
    check("zero-empty-string-probe", lambda: check_capacity(output / "capacity-zero-empty-string-probe.xlsx", inputs, zero, empty_string_probe=True))

    check("rendered-previews", lambda: check_rendering(output))
    report["checks"].append({"id": "visual-review", "status": "BLOCKED", "detail": "Inspect all seven PNGs at readable zoom, then record PASS or FAIL with the review command. PNG existence alone is not visual quality evidence."})

    soffice = None if skip_libreoffice else shutil.which("soffice")
    if soffice:
        version = command([soffice, "--version"], output)
        report["engines"]["libreoffice"] = version["stdout"].strip()
        destination = output / "libreoffice"
        destination.mkdir()
        # This lane contains only our synthetic, code-free, link-free fixtures.
        with tempfile.TemporaryDirectory(prefix="engineer-spreadsheets-lo-") as profile:
            argv = [soffice, f"-env:UserInstallation={Path(profile).as_uri()}", "--headless", "--convert-to", "xlsx:Calc MS Excel 2007 XML", "--outdir", str(destination), str(output / "capacity-peak.xlsx")]
            try:
                cache = Path(profile) / "cache"
                cache.mkdir()
                result = command(argv, output, env={**os.environ, "XDG_CACHE_HOME": str(cache)})
                report["commands"].append(result)
                if result["exit_code"] in {-9, 137}:
                    report["checks"].append({"id": "libreoffice-read-back", "status": "BLOCKED", "detail": f"LibreOffice was killed before producing destination evidence (exit {result['exit_code']}). {result['stderr'][-1000:]}"})
                    return finish()
                require(result["exit_code"] == 0, "LibreOffice open/save failed")
                peak = next(s for s in inputs["capacity"]["states"] if s["id"] == "peak")
                check("libreoffice-read-back", lambda: check_capacity(destination / "capacity-peak.xlsx", inputs, peak))
            except Exception as error:
                report["checks"].append({"id": "libreoffice-read-back", "status": "FAIL", "detail": str(error)})
    else:
        reason = "LibreOffice was explicitly skipped; no destination qualification is claimed." if skip_libreoffice else "soffice is not available; no destination engine is substituted."
        report["checks"].append({"id": "libreoffice-read-back", "status": "BLOCKED", "detail": reason})
    report["limitations"] = ["LibreOffice open/save/read-back is not evidence of calculateAll or native Excel behavior.",
                             "Font-only conditional formatting and the solid-fill probe have separate gates. Do not infer preservation of a failing fill from a passing font-only case.",
                             "Preservation is qualified only for features present in these fixtures; macros, pivots, signatures and external connections are outside scope.",
                             "Scripted fixture success does not measure a model's ability to use the skill."]
    return finish()


def verify(output: Path) -> dict:
    report = json.loads((output / "evidence.json").read_text())
    require(report.get("schema_version") == 1, "invalid evidence schema")
    require(report["skill_tree_sha256"] == tree_digest(SKILL), "skill tree changed since run")
    for name, expected in report["sources"].items():
        require(name in {"run.py", "build.mjs", "inputs.json"}, "unknown source binding")
        require(digest(HERE / name) == expected, f"source changed: {name}")
    require(set(report["sources"]) == {"run.py", "build.mjs", "inputs.json"}, "missing source binding")
    actual_files = {p.relative_to(output).as_posix() for p in output.rglob("*") if p.is_file() and p.name != "evidence.json"}
    require(set(report["files"]) == actual_files, "artifact inventory differs from evidence manifest")
    for name, expected in report["files"].items():
        require(not Path(name).is_absolute() and ".." not in Path(name).parts, "unsafe evidence path")
        require(digest(output / name) == expected, f"artifact changed: {name}")
    checks = report["checks"]
    require(checks and len({c["id"] for c in checks}) == len(checks), "missing or duplicate checks")
    require(all(c["status"] in {"PASS", "FAIL", "BLOCKED"} for c in checks), "invalid check status")
    expected_status = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "BLOCKED" if any(c["status"] == "BLOCKED" for c in checks) else "PASS"
    require(report["status"] == expected_status, "summary status contradicts checks")
    inputs = json.loads((HERE / "inputs.json").read_text())
    if report["status"] == "PASS":
        expected = {"no-op-preservation", "typed-literals", "narrow-edit-values", "narrow-edit-preservation", "rendered-previews", "visual-review", "libreoffice-read-back", "solid-fill-no-op-probe", "zero-empty-string-probe"}
        expected |= {"capacity-" + s["id"] for s in inputs["capacity"]["states"]}
        require({c["id"] for c in checks} == expected, "PASS report lacks complete gate coverage")
    # Re-run declared successful semantic checks; hashes alone do not make
    # self-reported PASS labels trustworthy.
    actions = {
        "typed-literals": lambda: check_records(output / "typed-records.xlsx", inputs),
        "narrow-edit-values": lambda: check_records(output / "edit.xlsx", inputs, True),
        "no-op-preservation": lambda: check_preservation(output / "typed-records.xlsx", output / "roundtrip.xlsx", False),
        "narrow-edit-preservation": lambda: check_preservation(output / "typed-records.xlsx", output / "edit.xlsx", True),
        "solid-fill-no-op-probe": lambda: check_preservation(output / "cf-probe.xlsx", output / "cf-probe-roundtrip.xlsx", False),
        "zero-empty-string-probe": lambda: check_capacity(output / "capacity-zero-empty-string-probe.xlsx", inputs, next(s for s in inputs["capacity"]["states"] if s["id"] == "zero"), empty_string_probe=True),
        "libreoffice-read-back": lambda: check_capacity(output / "libreoffice/capacity-peak.xlsx", inputs, next(s for s in inputs["capacity"]["states"] if s["id"] == "peak")),
        "rendered-previews": lambda: check_rendering(output),
    }
    actions.update({"capacity-" + s["id"]: (lambda state=s: check_capacity(output / f"capacity-{state['id']}.xlsx", inputs, state)) for s in inputs["capacity"]["states"]})
    for check in checks:
        if check["status"] == "PASS" and check["id"] in actions:
            actions[check["id"]]()
        if check["id"] == "visual-review" and check["status"] in {"PASS", "FAIL"}:
            review = json.loads((output / "visual-review.json").read_text())
            equal(review["verdict"], check["status"], "visual verdict")
            images = {name: value for name, value in report["files"].items() if name.endswith(".png")}
            equal(review["images"], images, "visual evidence image bindings")
            require(set(images) == set(PREVIEWS) and review["observations"].strip() and review["reviewer"].strip(), "incomplete visual review")
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ["run", "verify", "review"]:
        item = sub.add_parser(name)
        item.add_argument("directory", type=Path)
        if name == "run":
            item.add_argument("--skip-libreoffice", action="store_true", help="Leave the destination gate BLOCKED; useful after a resource failure")
        if name == "review":
            item.add_argument("--reviewer", required=True)
            item.add_argument("--observations", required=True, help="Specific observations after inspecting every PNG")
            item.add_argument("--verdict", choices=["PASS", "FAIL"], required=True)
    args = parser.parse_args()
    output = args.directory.resolve()
    if args.command == "run":
        return execute(output, args.skip_libreoffice)
    report = verify(output)
    if args.command == "review":
        gate = next(c for c in report["checks"] if c["id"] == "visual-review")
        require(gate["status"] == "BLOCKED", "visual review was already recorded")
        review = {"reviewer": args.reviewer, "observations": args.observations, "verdict": args.verdict,
                  "recorded_at": dt.datetime.now(dt.timezone.utc).isoformat(),
                  "prior_evidence_sha256": digest(output / "evidence.json"),
                  "images": {name: value for name, value in report["files"].items() if name.endswith(".png")}}
        require(set(review["images"]) == set(PREVIEWS) and args.observations.strip(), "review requires all seven images and specific observations")
        write_json(output / "visual-review.json", review)
        report["files"]["visual-review.json"] = digest(output / "visual-review.json")
        gate.update(status=args.verdict, detail="Recorded visual inspection; see hash-bound visual-review.json. This is reviewer evidence, not an automated aesthetic score.")
        statuses = {c["status"] for c in report["checks"]}
        report["status"] = "FAIL" if "FAIL" in statuses else "BLOCKED" if "BLOCKED" in statuses else "PASS"
        write_json(output / "evidence.json", report)
        report = verify(output)
    print(json.dumps({"status": report["status"], "evidence_integrity": "PASS", "checks": len(report["checks"])}))
    return {"PASS": 0, "FAIL": 1, "BLOCKED": 2}[report["status"]]


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (AssertionError, ValueError, KeyError, OSError, zipfile.BadZipFile) as error:
        print(f"artifact lane: {error}", file=sys.stderr)
        raise SystemExit(1)
