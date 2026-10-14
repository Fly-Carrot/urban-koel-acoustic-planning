# Running the code

## Check files and calculations

```bash
make setup
make verify
make test
```

Neither command fits a model. Tests cover released inputs, dated annual terms, support classes and positive-day conditioning.

## Recalculate retained results

```bash
make reproduce
# Or run one part:
Rscript analysis/reproduce_retained.R weekly
Rscript analysis/reproduce_retained.R planning
Rscript analysis/reproduce_retained.R monitoring
```

Outputs go to `outputs/full/retained_reproduction/`:

- weekly opportunity: 13,714 cells × 52 weeks, 600 draws;
- planning: joint HEQZ opportunity, standardised detection and D1 density, 300 matched draws;
- monitoring: updated predictor ranges/dissimilarity, retained spacing and route-specific pools.

Cell codes are de-identified. `spacing_conflicts.csv` permits spacing checks without coordinates. Maps are supplied as PDFs.

## Refit a retained model

```bash
Rscript analysis/fit_released_input.R full_corvid_assemblage
Rscript analysis/fit_released_input.R full_H4_M01
Rscript analysis/fit_released_input.R fold01_H4_M01_train
Rscript analysis/fit_released_input.R full_HEQZ_M01
Rscript analysis/fit_released_input.R D1
```

Names match files in `data/model-inputs/occupancy/`, `daily/` and `hourly/`, without `.json.gz`. Test files are for scoring, never fitting. Install [modelling requirements](system_requirements.md) first. Original schedules take hours; this update validates inputs/calculations but does not claim to have rerun every full MCMC chain.

Three host posterior surfaces enter three Koel fits with equal prediction weight. They are uncertainty-propagation sets, not three chains.

Full-data season-only S1 inputs are supplied for comparison; refitting stops because their original seed is unverified. Coordinate-trend/Moran analyses need withheld geometry. Historical searches and 100/500 m fits are documented in supplementary tables, not completely rerun here.

## Another dataset

Numbered `analysis/01–12` functions and `make full` accept your own tables through `config/full_data_manifest_example.csv`. This is a reusable modelling route, not the exact retained-study entry. Its planning step reports weekly-only overlaps; the retained-study entry above supplies the matched joint-model dawn summaries. New datasets need their own joint/hourly posterior composition. See [coverage](analysis_coverage.md).
