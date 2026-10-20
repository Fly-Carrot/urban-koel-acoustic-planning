# Data notes

`model-inputs/` contains actual numerical study inputs, with private identities replaced. These are not simulated data. Station codes ST01–ST31 and anonymous cell codes match across files. Dates and environmental values remain real; the data are de-identified, not guaranteed unidentifiable. Do not attempt to identify recorder locations.

## Study inputs

| Files | Contents |
|---|---|
| `survey_history.csv`, `daily_counts.csv` | Effort, four response groups and Koel positive-minute counts |
| `calendar.csv`, `fitting_weeks.csv`, `folds.csv` | Survey dates, 68 study weeks and fixed whole-station folds |
| `station_predictors.csv`, `full_scaling.csv` | Seven environmental predictors and training scales |
| `occupancy/*.json.gz` | Full and fivefold host/H0/H4 arrays and fitted covariates |
| `daily/` | HEQZ/S1 Stan inputs, design columns and row keys |
| `hourly_counts.csv`, `hourly/D1.json.gz` | Positive-day hourly observations and the D1 design |
| `city_predictors.csv`, `planning_weights.csv` | Predictors for 13,714 cells and geometry-free planning weights |
| `monitoring_candidates.csv`, `spacing_conflicts.csv`, `monitoring_settings.csv` | Monitoring priorities, pairwise spacing exclusions and settings |

Occupancy arrays use `{dim, values}` in R column-major order: `array(values, dim=dim)`. JSON `null` means missing, not zero. Stan JSON matrices use ordinary rows. The full occupancy array has 31 × 68 × 7 slots: 9,912 observed days, 4,844 missing slots and 2,682 Koel-positive days. Training and test files have disjoint stations and matching week/day axes.

## Saved results

[Summary CSVs](../results/summaries/) contain model effects, validation, annual-week predictions, support classes, planning overlaps and monitoring sequences. `model_formulas.csv`, `predictor_definitions.csv` and `host_groups.csv` describe the models and species groups.

[Posterior draws](../results/posterior_draws/) include 200 weekly H4 draws per host-information set (600 pooled), 100 joint HEQZ draws per set (300 pooled), matched D1 draws, host coefficients and training scales. H4 weekly-map coefficients and HEQZ joint-model coefficients come from different fits and must not be interchanged.

`psi` is weekly acoustic opportunity; `p` is conditional daily detectability; `mu_plus` is positive-day sampled-minute probability; `E = psi * p * mu_plus`. `q025` and `q975` bound a 95% credible interval. Percentages use 0–100; probabilities use 0–1. Missing values are blank or `NA`, never zero. In `model_effects.csv`, `positive_day_minute_probability` labels the density branch, whose coefficients enter the underlying `logit(mu)`, not a separate regression for derived `mu_plus`.

Fitting uses a dated 365.2425-day annual phase. The retained city projection uses a 52-week cycle. Density host indices use retained annual training scales, not city-wide scales.

## Using another dataset

The numbered scripts require your own prepared tables, listed in `input_files.csv`. The example gives file paths only; it is not another copy of the study data.

| Input name | Required fields |
|---|---|
| `survey_effort` | `station_id`, `date`, `scheduled_minutes`, `usable_minutes` |
| `acoustic_detections` | `station_id`, `date`, `sampled_minute`, `species_group`; optional `retained` or `positive` |
| `survey_calendar` | `date`, `study_week`, `survey_day`, `week_start` |
| `weekly_covariates`, `weekly_covariates_250` | Station/week keys and environmental predictors |
| `daily_detection_covariates` | Station/week/day keys, effort, anthropogenic and frog-event covariates |
| `validation_folds` | `station_id`, `fold_id` |
| `joint_daily_data` | Counts, `imputation` (1–3), host/environmental/observation covariates and `reference_log_effort_z`; repeat surveys for their matching host-information set |
| `hourly_calling_counts` | `station_id`, `date`, `clock_hour` (0–23), `positive_minutes`, `sampled_minutes`, `sin_week`, `cos_week`; include surveyed zero-count hours |
| `host_density_scaling` | `imputation`, `host_group`, `centre`, `scale`; include `equal_scale` |
| `training_predictors_250` | Station ID and the seven predictors |
| `city_predictors_250` | Cell ID, seven predictors, `dominant_land_cover`, `permanent_water` |
| `planning_sensitive_points` | `cell_id`, `context_class` |
| `urban_function_overlap` | `cell_id`, `context_class`, `overlap_area_m2` |
| Monitoring inputs | Candidate priorities, spacing-conflict pairs and minimum spacing; match the study file columns |

The predictors are `trees`, `built`, `grass`, `road_density`, `tree_edge_area_50m`, `dist_water_m_nearest` and `elevation`. Effort is `log1p(recorded sampled minutes / 60)` before training-based standardisation. The reference effort is 144 minutes; reference acoustic-context covariates and station effect are zero. Exact geometry is not supplied.

See [licences](LICENSE.md) and [source notices](../THIRD_PARTY_NOTICES.md). OSM-derived planning weights and road-density values retain ODbL terms.
