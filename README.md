# Supplementary materials and analysis code

Accompanying materials for *Urban planning leaves an audible legacy in a megacity’s bird soundscape*.

## Materials

| Material | Open |
|---|---|
| Supplementary Methods S1–S9 and captions | [Complete PDF](supplementary-materials/supplementary-information/Supplementary_Information.pdf) |
| Supplementary Data 1–17 | [Excel files and titles](supplementary-materials/tables/README.md) |
| Supplementary Figures 1–10 | [PDFs and previews](supplementary-materials/figures/README.md) |
| Main figures and Table 1 | [Figures](supplementary-materials/main-figures/README.md) · [Table](supplementary-materials/main-tables/README.md) |
| Model-ready study inputs | [Data and field notes](data/model-inputs/README.md) |
| Selected posterior draws and reported summaries | [Draws](data/model-outputs/README.md) · [Summary CSVs](data/processed/reference/) |

Updated **15 October 2026** to match the current Science Advances submission files. Figure panels use uppercase letters. Public copies omit precise coordinates and private station/candidate identifiers; workbook sheet names and numerical results are retained.

## Analysis

The numbered files in [analysis/](analysis/) follow the paper. Functions in [R/](R/) perform the calculations; [stan/](stan/) contains the calling-density models.

| Step | Code |
|---|---|
| Prepare daily detections and recording effort | [Survey histories](R/survey_histories.R) |
| Fit detection, host and Koel models | [Occupancy models](R/occupancy_models.R) |
| Test transfer to withheld stations | [Transfer validation](R/transfer_validation.R) |
| Fit daily and hourly calling density | [Calling density](R/calling_density.R) |
| Recalculate city predictions and dawn summaries | [Retained-draw calculations](R/reproduce_study.R) |
| Identify prediction boundaries | [PID and AOA](R/prediction_support.R) |
| Select the next monitoring sites | [Monitoring design](R/monitoring_design.R) |

[Methods-to-code map](docs/code_map.md) · [Script notes](docs/script_reference.md) · [Model roles](docs/model_registry.md) · [Verification](docs/verification.md)

## Run

```bash
git clone https://github.com/Fly-Carrot/urban-koel-acoustic-planning.git
cd urban-koel-acoustic-planning
make setup
make verify
make test
make reproduce
```

`verify` checks reported summaries. `test` checks calculations and released inputs. `reproduce` recalculates citywide weekly predictions, dawn overlap summaries and monitoring sequences from retained draws; it does not run MCMC again.

To refit a retained model, use `Rscript analysis/fit_released_input.R full_H4_M01` after installing modelling packages. [Running instructions](docs/reproduce.md) describe requirements and the parts not rerun here.

## Sharing and interpretation

Study inputs use ST01–ST31 and randomly assigned cell codes. Dates and environmental measurements remain real: these are **de-identified data**, not a guarantee against re-identification. Exact positions, private identity maps, raw recordings, AI weights and source rasters are not distributed. [Data access](docs/data_access.md)

Acoustic opportunity, detectability and sampled-minute exposure describe different parts of the recording process. They do not measure abundance or residents’ perceived disturbance. [Definitions](docs/scientific_boundaries.md)

Please cite the manuscript and repository commit used. [Citation metadata](CITATION.cff)

Code: [BSD-3-Clause](LICENSE). Project-owned data/materials: [CC BY 4.0](data/LICENSE.md). OSM-derived planning data: ODbL 1.0. [Source notices](THIRD_PARTY_NOTICES.md)
