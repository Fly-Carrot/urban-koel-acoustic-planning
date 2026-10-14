# Supplementary materials and analysis code

Accompanying materials for *Urban planning leaves an audible legacy in a megacity’s bird soundscape*.

## Supplementary materials

| Material | Open |
|---|---|
| Supplementary Methods S1–S9 and captions | [Complete PDF](supplementary-materials/supplementary-information/Supplementary_Information.pdf) |
| Supplementary Data 1–17 | [Excel files and titles](supplementary-materials/tables/README.md) |
| Supplementary Figures 1–10 | [PDFs and previews](supplementary-materials/figures/README.md) |
| Reported numerical summaries | [CSV files](data/processed/reference/) · [field descriptions](docs/data_dictionary.md) |

The supplementary files are the public export updated on **11 October 2026**. They retain the numbering and lowercase figure panels of that version. Later manuscript revisions are not included in these files.

## Analysis code

The numbered files in [analysis/](analysis/) run each step. The calculations are in [R/](R/); the calling-density models are in [stan/](stan/).

| Step | Main code |
|---|---|
| Join recording effort and detections | [Survey histories](R/survey_histories.R) |
| Check environmental predictors | [Environmental predictors](R/environmental_predictors.R) |
| Fit detection, host and Koel opportunity models | [Occupancy models](R/occupancy_models.R) |
| Test predictions at withheld stations | [Transfer validation](R/transfer_validation.R) |
| Fit daily and hourly calling density | [Calling density](R/calling_density.R) · [Stan models](stan/README.md) |
| Predict citywide activity and sampled-minute exposure | [City prediction](R/city_prediction.R) · [Exposure](R/exposure_prediction.R) |
| Classify prediction support | [PID and AOA](R/prediction_support.R) |
| Summarise planning-sensitive overlaps | [Planning overlap](R/planning_overlap.R) |
| Rank additional monitoring sites | [Monitoring design](R/monitoring_design.R) |

[Methods-to-code map](docs/code_map.md) · [Notes for each script](docs/script_reference.md) · [Model roles](docs/model_registry.md)

## Run the public checks

```bash
git clone https://github.com/Fly-Carrot/urban-koel-acoustic-planning.git
cd urban-koel-acoustic-planning
make setup
make verify
make test
```

These commands check the released summaries and example calculations. Results go to `outputs/`; they do not refit the study models.

Model fitting requires additional inputs listed in the [data notes](docs/data_access.md). See [running instructions](docs/reproduce.md) and [current code coverage](docs/analysis_coverage.md) before using `make full`. The public implementation has several differences from the retained study analysis and has not been verified as a complete numerical reproduction.

## Data and interpretation

Included data are aggregate summaries and a small synthetic example. Raw recordings, model-ready station-level inputs, exact coordinates and model weights are not included. [Data access](docs/data_access.md) lists the required files; [source notices](THIRD_PARTY_NOTICES.md) list third-party datasets.

Weekly acoustic opportunity, detectability and sampled-minute exposure describe different parts of the recording process. Mapped activity does not measure abundance or perceived disturbance. [Definitions and interpretation](docs/scientific_boundaries.md)

## Citation and licence

Please cite the associated manuscript and identify the repository tag or commit you used. See [citation metadata](CITATION.cff) and [tagged releases](https://github.com/Fly-Carrot/urban-koel-acoustic-planning/releases).

Code: [BSD-3-Clause](LICENSE). Project-owned summary data and supplementary materials: [CC BY 4.0](data/LICENSE.md). Third-party sources retain their own terms.
