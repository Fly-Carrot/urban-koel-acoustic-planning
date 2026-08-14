#!/usr/bin/env python3
"""Fail-closed checks for the public manuscript supplementary-material bundle."""

from __future__ import annotations

import csv
import hashlib
import re
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "supplementary-materials"

EXPECTED_TABLES = [BASE / "tables" / f"Table_S{i:02d}.xlsx" for i in range(1, 18)]
EXPECTED_FIGURES = [BASE / "figures" / f"Figure_S{i:02d}.pdf" for i in range(1, 11)]
EXPECTED_PREVIEWS = [BASE / "figures" / "previews" / f"Figure_S{i:02d}.png" for i in range(1, 11)]
EXPECTED_INFORMATION = [BASE / "supplementary-information" / "Supplementary_Information.pdf"]
EXPECTED_ASSETS = EXPECTED_INFORMATION + EXPECTED_TABLES + EXPECTED_FIGURES + EXPECTED_PREVIEWS

FORBIDDEN_TEXT = re.compile(
    rb"/Users/|/Volumes/|[A-Za-z]:\\Users\\|HEX250_|e22556|David[ ]+Chen|"
    rb"113\.[0-9]{3,}|114\.[0-9]{3,}",
    re.IGNORECASE,
)
PRIVATE_XLSX_TERMS = re.compile(
    r"\b(longitude|latitude|lon|lat|lng|site_x|site_y|wkt)\b|HEX250_|"
    r"/Users/|/Volumes/|e22556|David[ ]+Chen",
    re.IGNORECASE,
)


def fail(message: str) -> None:
    raise RuntimeError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def relative(path: Path) -> str:
    return path.relative_to(BASE).as_posix()


def validate_inventory() -> None:
    missing = [relative(path) for path in EXPECTED_ASSETS if not path.is_file()]
    if missing:
        fail("Missing supplementary assets: " + ", ".join(missing))

    actual_tables = sorted((BASE / "tables").glob("Table_S*.xlsx"))
    actual_figures = sorted((BASE / "figures").glob("Figure_S*.pdf"))
    actual_previews = sorted((BASE / "figures" / "previews").glob("Figure_S*.png"))
    if actual_tables != EXPECTED_TABLES:
        fail("The public table inventory is not exactly Table_S01-Table_S17.")
    if actual_figures != EXPECTED_FIGURES:
        fail("The public figure inventory is not exactly Figure_S01-Figure_S10.")
    if actual_previews != EXPECTED_PREVIEWS:
        fail("The public preview inventory is not exactly Figure_S01-Figure_S10.")

    oversized = [relative(path) for path in EXPECTED_ASSETS if path.stat().st_size >= 50 * 1024 * 1024]
    if oversized:
        fail("A supplementary asset is 50 MB or larger: " + ", ".join(oversized))


def validate_workbooks() -> None:
    for path in EXPECTED_TABLES:
        with zipfile.ZipFile(path) as workbook:
            names = workbook.namelist()
            if any("comments" in name.lower() or "externallink" in name.lower() for name in names):
                fail(f"Workbook contains comments or external links: {relative(path)}")
            text_parts: list[str] = []
            for name in names:
                lower = name.lower()
                if lower.endswith((".xml", ".rels", ".txt")):
                    text_parts.append(workbook.read(name).decode("utf-8", errors="ignore"))
            joined = "\n".join(text_parts)
            if PRIVATE_XLSX_TERMS.search(joined):
                fail(f"Workbook contains a private coordinate, identifier or workstation term: {relative(path)}")

            core = workbook.read("docProps/core.xml").decode("utf-8", errors="ignore") if "docProps/core.xml" in names else ""
            if re.search(r"<(?:dc:creator|cp:lastModifiedBy)>\s*[^<\s]", core):
                fail(f"Workbook contains personal author metadata: {relative(path)}")


def validate_binary_strings() -> None:
    for path in EXPECTED_INFORMATION + EXPECTED_FIGURES:
        content = path.read_bytes()
        if FORBIDDEN_TEXT.search(content):
            fail(f"PDF contains a private path, identifier or coordinate string: {relative(path)}")
    for path in EXPECTED_PREVIEWS:
        if FORBIDDEN_TEXT.search(path.read_bytes()):
            fail(f"Preview contains a private string: {relative(path)}")


def validate_manifest() -> None:
    manifest_path = BASE / "manifests" / "supplementary_artifacts.csv"
    with manifest_path.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))
    if len(rows) != 38:
        fail(f"Expected 38 supplementary artifact rows; found {len(rows)}.")
    ids = [row["artifact_id"] for row in rows]
    if len(ids) != len(set(ids)):
        fail("Supplementary artifact IDs are not unique.")
    if any(row["privacy_status"] != "public_redacted" for row in rows):
        fail("Every public supplementary artifact must declare public_redacted privacy status.")
    if any(row["license"] != "CC-BY-4.0" for row in rows):
        fail("Every project-owned supplementary artifact must declare CC-BY-4.0.")

    by_name = {path.name: path for path in EXPECTED_ASSETS}
    for row in rows:
        path = by_name.get(row["public_filename"])
        if path is None:
            fail("Manifest names an unexpected asset: " + row["public_filename"])
        if sha256(path).lower() != row["sha256"].lower():
            fail("Supplementary artifact checksum changed: " + relative(path))
        if path.stat().st_size != int(row["size_bytes"]):
            fail("Supplementary artifact size changed: " + relative(path))

    checksum_path = BASE / "manifests" / "checksums.sha256"
    recorded: dict[str, str] = {}
    for line in checksum_path.read_text(encoding="utf-8").splitlines():
        digest, name = line.split("  ", 1)
        recorded[name] = digest
    expected_files = sorted(path for path in BASE.rglob("*") if path.is_file() and path != checksum_path)
    expected_names = {relative(path) for path in expected_files}
    if set(recorded) != expected_names:
        fail("The supplementary checksum inventory does not match the public files.")
    for path in expected_files:
        if recorded[relative(path)].lower() != sha256(path).lower():
            fail("Supplementary collection checksum changed: " + relative(path))


def main() -> int:
    validate_inventory()
    validate_workbooks()
    validate_binary_strings()
    validate_manifest()
    print("Supplementary-material contract PASS: 1 complete PDF, 17 tables, 10 figure PDFs, 10 previews and verified checksums.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # fail closed with one clear CI message
        print(f"Supplementary-material contract FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
