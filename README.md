# Supplementary materials and analysis code

This repository accompanies the manuscript *Urban planning leaves an audible legacy in a megacity’s bird soundscape*, prepared for *Communications Earth & Environment*.

It contains the Supplementary Information, individual data files and figures, statistical models, and a readable R implementation of the main analysis steps.

[![checks](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/contract.yml/badge.svg)](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/contract.yml)
[![verify](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/verify.yml/badge.svg)](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/verify.yml)
[![license](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

## Contents

```text
analysis/   ordered scripts matching the paper
R/          functions for data preparation, models and prediction
stan/       Stan models for calling density
config/     model, predictor and decision records
data/       public summaries and a synthetic example
supplementary-materials/  PDF, tables, figures and file manifests
docs/       data notes and a method-to-code index
tests/      numerical and repository checks
```

The analysis follows twelve main steps:

1. prepare effort-confirmed survey histories;
2. select the daily detection model;
3. check environmental predictors at 100, 250 and 500 m;
4. fit three potential-host opportunity models;
5. fit weekly Asian Koel acoustic opportunity;
6. test transfer to withheld stations;
7. fit daily and hourly calling-density models;
8. predict citywide acoustic activity;
9. map the Prediction Interpretation Domain (PID) and Area of Applicability (AOA);
10. summarise planning-sensitive intersections;
11. rank Coverage Expansion and Prediction Validation sites; and
12. assemble manuscript outputs.

See [`docs/code_map.md`](docs/code_map.md) for the link between the Methods, scripts, inputs and outputs. [`docs/script_reference.md`](docs/script_reference.md) gives a short description of every script.

## Quick check

The public summaries can be checked with base R:

```bash
git clone https://github.com/Fly-Carrot/urban-koel-acoustic-planning.git
cd urban-koel-acoustic-planning
make setup
make verify
make test
```

Generated files are written to `outputs/`.

## Running the models

The model-fitting code is public. Raw audio, exact recorder and candidate-site coordinates, detailed POIs, model weights and licensed geospatial layers are not redistributed.

Researchers with approved model-ready inputs can copy [`config/full_data_manifest_example.csv`](config/full_data_manifest_example.csv) to `data/full/manifest.csv`, add the corresponding local paths and run:

```bash
make full
```

The full route requires R packages listed in [`docs/system_requirements.md`](docs/system_requirements.md). Data fields and access limits are described in [`docs/data_access.md`](docs/data_access.md). Stage-specific sampling settings are listed in [`docs/mcmc_settings.md`](docs/mcmc_settings.md).

## Supplementary files

| Material | Link |
|---|---|
| Complete Supplementary Information | [PDF](supplementary-materials/supplementary-information/Supplementary_Information.pdf) |
| Supplementary Data 1–17 | [data files](supplementary-materials/tables/) |
| Supplementary Figs. 1–10 | [figures](supplementary-materials/figures/) |
| Checksums and inventories | [manifests](supplementary-materials/manifests/) |

## Scope

The public `verify` route rebuilds reported summaries from non-sensitive processed products. The `full` route needs approved model-ready inputs and does not yet reproduce every archived scoring and prediction step exactly. See [`docs/analysis_coverage.md`](docs/analysis_coverage.md) for the remaining differences.

Potential-host acoustic opportunity is predictive context and does not establish local parasitism. Mapped acoustic activity does not measure abundance, human presence or annoyance. PID and AOA describe prediction support; they do not alter prediction values.

Code is released under BSD-3-Clause. Project-owned supplementary materials and summary data are released under CC BY 4.0. Third-party sources retain their original licences.

## Citation

Please cite the manuscript and the versioned repository release. Citation metadata are provided in [`CITATION.cff`](CITATION.cff).
