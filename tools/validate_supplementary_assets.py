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

TABLE_STEMS = [
    "Table_S01_Monitoring_Station_Sampling_Coverage_Koel_Detections_and_Spatial_Validation_Folds",
    "Table_S02_Detection_History_Reconciliation",
    "Table_S03_Acoustic_Identification_Workflow_and_Validation_Evidence",
    "Table_S04_Candidate_Daily_Detection_Models",
    "Table_S05_Detection_Model_Audits",
    "Table_S06_Master_Analytical_Variable_Dictionary",
    "Table_S07_External_Datasets_and_Geoprocessing",
    "Table_S08_Potential_Host_Candidates_and_Validation",
    "Table_S09_Koel_Model_Development_and_Model_Roles",
    "Table_S10_Transfer_Scale_and_Spatial_Diagnostics",
    "Table_S11_Joint_Model_Definitions_and_Estimands",
    "Table_S12_Joint_Model_Results_and_Exposure_Summaries",
    "Table_S13_City_Projection_and_Prediction_Interpretation_Domain",
    "Table_S14_Area_of_Applicability_and_Prediction_Support_Classes",
    "Table_S15_Planning_Sensitive_Places_and_Urban_Functions",
    "Table_S16_Adaptive_Monitoring_Design",
    "Table_S17_Software_Model_Provenance_and_Availability",
]
FIGURE_STEMS = [
    "Figure_S01_Monitoring_Network_and_Recording_Effort",
    "Figure_S02_Whole_Station_Daily_Detection_Validation",
    "Figure_S03_Potential_Host_Opportunity_Validation",
    "Figure_S04_Host_Associations_and_Propagated_Uncertainty",
    "Figure_S05_Transfer_Scale_and_Residual_Spatial_Diagnostics",
    "Figure_S06_Joint_Acoustic_Activity_Model_and_Derived_Exposure",
    "Figure_S07_City_Prediction_and_Prediction_Support_Classes",
    "Figure_S08_Planning_Sensitive_Places_and_Urban_Function_Overlap",
    "Figure_S09_Monitoring_Priority_Surfaces",
    "Figure_S10_Sequential_Coverage_Expansion_and_Prediction_Validation_Candidates",
]

EXPECTED_TABLES = [BASE / "tables" / f"{stem}.xlsx" for stem in TABLE_STEMS]
EXPECTED_FIGURES = [BASE / "figures" / f"{stem}.pdf" for stem in FIGURE_STEMS]
EXPECTED_PREVIEWS = [BASE / "figures" / "previews" / f"{stem}.png" for stem in FIGURE_STEMS]
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
        fail("The public table inventory does not match the approved descriptive Table S01-S17 filenames.")
    if actual_figures != EXPECTED_FIGURES:
        fail("The public figure inventory does not match the approved descriptive Figure S01-S10 filenames.")
    if actual_previews != EXPECTED_PREVIEWS:
        fail("The public preview inventory does not match the approved descriptive Figure S01-S10 filenames.")

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

    required_redactions = {
        "FS01": ("ST01", "exact coordinates"),
        "FS01-PREVIEW": ("ST01", "exact coordinates"),
        "FS10": ("candidate-HEX identifiers removed",),
        "FS10-PREVIEW": ("candidate-HEX identifiers removed",),
    }
    rows_by_id = {row["artifact_id"]: row for row in rows}
    for artifact_id, phrases in required_redactions.items():
        row = rows_by_id.get(artifact_id)
        if row is None:
            fail(f"Manifest is missing public-redaction evidence for {artifact_id}.")
        redactions = row["redactions"]
        if any(phrase not in redactions for phrase in phrases):
            fail(f"Manifest does not attest the approved visual redaction for {artifact_id}.")

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
