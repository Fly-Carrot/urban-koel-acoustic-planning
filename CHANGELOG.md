# Changelog

## 2026-10-15

- Aligned dated fitting terms, PID/AOA classes, sequential monitoring rules and dawn summaries with the retained analysis.
- Added actual de-identified model inputs, fixed folds and selected posterior draws, plus model-refit and retained-result calculation scripts.
- Updated all SA supplementary materials, main figures and Table 1. Removed private coordinate records/IDs and personal file metadata from public copies.
- Verified input round trips, complete city predictions, planning summaries and both monitoring sequences. Full historical MCMC searches and geometry-dependent diagnostics were not rerun.

## 2026-10-14

- Shortened the repository introduction and linked directly to the modelling functions.
- Clarified public data, running instructions and the supplementary-file version.
- Documented differences between public code and the retained study analysis.
- Simplified script notes and comments. Model calculations, numerical data and figure/table files are unchanged.

## 2026-10-11

- Updated the manuscript title, journal and ten-author citation metadata.
- Aligned per-stage occupancy and Stan sampling settings with Supplementary Data 17.
- Corrected the recording-effort transformation to log(1 + sampled minutes / 60).
- Updated CEE supplementary files and retained public-data redactions.
- Aligned whole-station scoring and probability-scale pooling of three host refits.
- Restored the final hourly design and paired daily/hourly posterior calculation of city exposure.
- Added small-data tests for these calculations and documented the retained input requirements.

## 0.1.0 — 2026-08-14

- Added 14 documented public analysis drivers.
- Added base-R `smoke` and `verify` profiles with numerical and release-contract tests.
- Added curated non-sensitive reference summaries for survey effort, model effects, transfer validation, city prediction, prediction support, planning overlap and adaptive monitoring.
- Added conditional full-profile interfaces and public Stan source.
- Added citation, licence, data-boundary, provenance and contribution documentation.

