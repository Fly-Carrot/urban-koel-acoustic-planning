# Supplementary data and analysis code for: *Where wildlife is heard: AI-powered mapping of bird acoustic activity for adaptive monitoring and urban planning*

This repository provides the public supplementary code, aggregate processed data, model source and reproducibility workflow associated with the manuscript *Where wildlife is heard: AI-powered mapping of bird acoustic activity for adaptive monitoring and urban planning*, prepared for submission to *Landscape and Urban Planning*.

The study uses AI-assisted passive acoustic monitoring at 31 stations in Shenzhen, China, to examine how landscape context, potential-host opportunity and season shape Asian Koel (*Eudynamys scolopaceus*) acoustic activity. It then evaluates transfer to unmonitored neighbourhoods, maps where predictions are supported, summarises intersections with planning-sensitive urban spaces and identifies priorities for expanding the monitoring network.

These materials document the analyses reported in the manuscript and provide a public route for checking its derived results and reusing the workflow.

[![contract](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/contract.yml/badge.svg)](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/contract.yml)
[![verify](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/verify.yml/badge.svg)](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/actions/workflows/verify.yml)
[![license: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)
[![release](https://img.shields.io/github/v/release/Fly-Carrot/urban-koel-acoustic-planning?include_prereleases)](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/releases)

## Repository scope

The repository contains curated, manuscript-aligned materials rather than the complete private analysis workspace. Public contents include:

- 14 ordered analysis drivers with documented input and output contracts;
- aggregate, non-sensitive reference products used to verify manuscript results;
- exact Stan source for the public joint-model components;
- model, predictor, threshold, seed and provenance registries;
- a synthetic example dataset; and
- tests and continuous-integration workflows for checking the public release.

Raw audio, exact recorder and candidate-site coordinates, granular points of interest, restricted model weights and third-party geospatial source data are not redistributed because of data volume, privacy, security or licensing constraints.

> [!IMPORTANT]
> **Reproducibility scope.** `make verify` reconstructs the reported derived tables, curves and numerical checks from frozen, non-sensitive processed and posterior summaries. It does not recreate AI detections from raw audio or repeat exact site-level environmental extraction. The `full` profile therefore requires access to the documented model-ready private inputs.

<p align="center">
  <img src="docs/assets/workflow-overview.svg" alt="Overview of the supplementary analysis workflow" width="100%">
</p>

## Repository layout

```text
analysis/   14 ordered public analysis drivers
R/          shared and tested R functions
stan/       Stan model source used by the conditional full profile
config/     formula, predictor, seed, threshold and provenance registries
data/       synthetic examples and frozen non-sensitive reference summaries
docs/       script, data, reproduction and scientific-boundary documentation
tests/      release-contract and numerical tests
tools/      curation and release-validation utilities
```

Detailed descriptions of every public driver are provided in [`docs/script_reference.md`](docs/script_reference.md). Data fields are documented in [`docs/data_dictionary.md`](docs/data_dictionary.md), and the model roles and formulae are recorded in [`docs/model_registry.md`](docs/model_registry.md) and [`config/model_registry.csv`](config/model_registry.csv).

## Reproducing the supplementary results

Requirements: R 4.5 or later, GNU Make, and either `sha256sum`, `shasum` or `openssl`.

```bash
git clone https://github.com/Fly-Carrot/urban-koel-acoustic-planning.git
cd urban-koel-acoustic-planning
make setup
make verify
make test
```

The public verification profile uses base R and normally finishes in under one minute. Generated files are written to `outputs/`, which is intentionally ignored by Git.

| Profile | Command | Purpose | Public status |
|---|---|---|---|
| `smoke` | `make smoke` | Run all 14 drivers on synthetic/example inputs and check their interfaces | Available |
| `verify` | `make verify` | Rebuild reported summaries from frozen public products and validate manuscript anchors | Available and used in CI |
| `full` | `make full` | Check the private-input contract before a complete refit | Conditional on access to restricted model-ready inputs |

Additional instructions are available in [`docs/reproduce.md`](docs/reproduce.md) and [`docs/system_requirements.md`](docs/system_requirements.md).

## Analysis workflow represented in this repository

The public scripts follow the order of the manuscript and Supplementary Methods:

1. check software, data and release contracts;
2. construct effort-confirmed survey histories;
3. compare and retain the daily detection backbone;
4. prepare landscape and spatial predictors;
5. fit three potential-host acoustic-opportunity models;
6. estimate weekly Koel acoustic opportunity;
7. validate spatial transfer and compare 100-, 250- and 500-m neighbourhoods;
8. estimate calling density and sampled-minute acoustic exposure;
9. generate citywide activity predictions;
10. classify the Prediction Interpretation Domain (PID) and Area of Applicability (AOA);
11. summarise overlap with planning-sensitive places and urban functions;
12. rank Coverage Expansion and Prediction Validation sites;
13. produce manuscript-facing summaries; and
14. validate the complete public release.

The repository exposes a stable, documented interface for these steps. Historical development scripts and machine-specific orchestration files are not part of the public supplement.

## Data and model notes

The joint analysis separates three linked features of acoustic activity:

- weekly acoustic opportunity, \(\psi\): the probability that Koel vocal activity is present in a station-week;
- daily detectability, \(p\): the probability of retaining at least one Koel-positive sampled minute on a surveyed day, conditional on weekly opportunity; and
- positive-day sampled-minute probability, \(\mu^+\): the density of Koel-positive sampled minutes after the daily detection hurdle is crossed.

Aligned posterior draws give sampled-minute acoustic exposure:

\[
E = \psi \times p \times \mu^+.
\]

Potential-host acoustic opportunity provides life-history-informed predictive context; it does not demonstrate confirmed host use or local parasitism. Ecological predictors were measured within station-centred circular neighbourhoods. A 250-m radius was retained after matched 100-, 250- and 500-m transfer comparisons, while HEX cells were used only for citywide prediction and reporting.

PID describes ecological interpretation context and AOA describes similarity to the monitored predictor space. Their cross-classification produces four manuscript reporting classes:

- **Primary Results** — core planning interpretation;
- **Moderate Extrapolation** — preliminary screening with field confirmation;
- **Monitoring Gaps** — environments requiring additional monitoring before interpreting predicted values; and
- **Outside the Reporting Domain** — categorical permanent-water cells reported as unavailable.

These support classes accompany predictions without changing their values. Further interpretation boundaries are listed in [`docs/scientific_boundaries.md`](docs/scientific_boundaries.md).

## Verification checks

The public verification profile checks:

- reconciliation of the 31 stations, 9,912 effort-confirmed station-days, 2,682 Koel-positive days, 1,500 station-weeks and 1,398,905 sampled-minute opportunities;
- the registered Koel, detection and potential-host model structures;
- whole-station transfer, multiscale decisions and residual spatial diagnostics;
- coefficient, seasonal-activity and acoustic-exposure anchors reported in the manuscript;
- four prediction-support classes summing to 13,714 HEX cells;
- planning summaries based on 5,745 Primary Results and Moderate Extrapolation cells; and
- nested monitoring-deployment scenarios and the reported 15-station example.

The release contract additionally scans tracked files for exact-coordinate schemas, machine-specific paths, credentials and prohibited binary inputs.

## Data access, privacy and licensing

Only anonymised aggregate or simulated data admitted by the release contract are included. Data access and exclusion decisions are documented in [`data/README.md`](data/README.md), [`docs/data_access.md`](docs/data_access.md) and [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

Code is released under BSD-3-Clause. Curated project-owned summary data are released under CC BY 4.0. Third-party data remain governed by their original licences and are not relicensed by this repository.

## Citation

Please cite the associated manuscript and the versioned repository release when using these supplementary materials. Repository citation metadata are provided in [`CITATION.cff`](CITATION.cff). The article citation and archival DOI will be added after manuscript acceptance and repository archiving.

## Issues and contributions

Questions about the supplementary workflow or discrepancies in the public verification results can be reported through GitHub Issues. See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`SECURITY.md`](SECURITY.md) before submitting code, data or a vulnerability report.
