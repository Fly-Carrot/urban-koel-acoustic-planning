# Urban planning leaves an audible legacy in a megacity’s bird soundscape

Analysis code, processed study data and supplementary materials for the Asian Koel (*Eudynamys scolopaceus*) study in Shenzhen, China.

## Contents

| Folder | Contents |
|---|---|
| [analysis](analysis/) | Numbered R scripts, model refitting and recalculation of published results |
| [R](R/) · [stan](stan/) | Data preparation, model fitting, validation and prediction functions |
| [data/model-inputs](data/model-inputs/) | De-identified study inputs, model designs and fixed validation folds |
| [results/summaries](results/summaries/) | Model effects, validation, weekly predictions, planning and monitoring summaries |
| [results/posterior_draws](results/posterior_draws/) | Selected coefficient draws, training scales and reference results |
| [Supplementary Data 1–17](supplementary-materials/tables/) | Excel workbooks; `Table_S01.xlsx` corresponds to Supplementary Data 1 |
| [Supplementary Information](supplementary-materials/supplementary-information/Supplementary_Information.pdf) · [figures](supplementary-materials/figures/) | Supplementary methods and figures |
| [Main figures](supplementary-materials/main-figures/) · [Table 1](supplementary-materials/main-tables/) | Figure and table files |
| [Audio examples](supplementary-materials/audio/README.md) | Two original recordings of Koel vocalizations |

## Recalculate the published results

Run from the repository folder, using R:

```r
install.packages(c("data.table", "jsonlite", "matrixStats", "reformulas"))
```

```bash
Rscript analysis/reproduce_retained.R
# Or choose one part:
Rscript analysis/reproduce_retained.R weekly
Rscript analysis/reproduce_retained.R planning
Rscript analysis/reproduce_retained.R monitoring
```

Results are written to `outputs/full/retained_reproduction/`. This recalculates 13,714 cells × 52 weeks from 600 weekly-model draws, planning summaries from 300 matched joint-model draws, and both monitoring sequences. It does not refit the models.

## Refit a model

Fitting also requires `spOccupancy`, `loo` and `posterior`; Stan models require [cmdstanr and CmdStan](https://mc-stan.org/cmdstanr/articles/cmdstanr.html). The original MCMC schedules can take hours.

```bash
Rscript analysis/fit_released_input.R full_corvid_assemblage
Rscript analysis/fit_released_input.R full_H4_M01
Rscript analysis/fit_released_input.R fold01_H4_M01_train
Rscript analysis/fit_released_input.R full_HEQZ_M01
Rscript analysis/fit_released_input.R D1
```

Names match the files in `data/model-inputs/occupancy/`, `daily/` or `hourly/`, without `.json.gz`. Outputs go to `outputs/full/released_fits/`. Test inputs are for scoring, not fitting. Full-data season-only S1 inputs are included for comparison, but their original fitting seed has not been verified, so the script does not refit them.

## Analysis steps

Scripts `01–12` cover survey filtering, detection models, environmental predictors, potential hosts, Koel opportunity, held-station validation, calling density, city prediction, prediction support, planning overlaps and monitoring design. The calculations are in the corresponding R functions.

To adapt these steps to another dataset, copy `data/input_files_example.csv` to `data/input_files.csv`, supply your prepared tables, and run `Rscript analysis/run_all.R`. See [data notes](data/README.md) for the required fields. This route fits new models; it is separate from recalculating the retained study results above. Its planning step summarises weekly opportunity, whereas the retained-study calculation uses the joint model and dawn calling density.

## Data and interpretation

The released inputs contain real observations with private station and cell identities replaced. Precise coordinates, source rasters, granular POI records, AI weights and complete MCMC chains are not included. Coordinate-based diagnostics and historical 100/500 m comparisons are reported in the supplementary materials but cannot all be rerun from this export. The two listening examples are separate from the full recording archive.

Weekly acoustic opportunity and sampled-minute exposure describe recorded vocal activity, not abundance or residents’ perceived disturbance. Three host-information sets propagate host uncertainty; they are not three MCMC chains. Selected draws support recalculation, not a fresh convergence assessment.

Code is [BSD-3-Clause](LICENSE). Project-owned data and supplementary materials are [CC BY 4.0](data/LICENSE.md); OpenStreetMap-derived components retain ODbL terms. See [source notices](THIRD_PARTY_NOTICES.md). Please cite the associated manuscript and identify the repository version used.
