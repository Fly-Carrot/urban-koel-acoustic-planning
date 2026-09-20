# Data dictionary

## Public reference products

| File | Unit | Core fields | Meaning |
|---|---|---|---|
| `survey_reconciliation.csv` | release check | `metric`, `value`, `expected`, `pass` | effort and response totals used by the fitted pipeline |
| `model_registry_public.csv` | model component | formula and role | public names and frozen formulas |
| `predictor_registry_public.csv` | predictor | likelihood layer and support | ecological, observation and reporting definitions |
| `host_groups.csv` | species | group and scientific name | exact membership of three potential-host responses |
| `model_effects.csv` | coefficient | median and 95% CrI | reported `psi`, `p` and `mu_plus` effects |
| `transfer_validation.csv` | comparison | estimate, interval and diagnostics | held-station and multiscale evidence |
| `weekly_acoustic_opportunity.csv` | annual week | spatial quantiles and mean | `psi` across the centroid-in-city mapping subset |
| `weekly_acoustic_exposure.csv` | annual week | spatial quantiles and mean | all-day `E` across the same subset |
| `prediction_support_classes.csv` | support class | HEX count and percentage | PID × AOA cross-classification |
| `planning_overlap.csv` | mapped context class | counts/area and posterior summaries | functional-zone and POI summaries |
| `adaptive_monitoring_sequences.csv` | anonymised route rank | gains, uncertainty and inclusion | nested 5/10/15 deployment scenarios without coordinates |

## Symbols

| Public field | Definition |
|---|---|
| `psi` | detection-corrected weekly acoustic opportunity |
| `p` | conditional daily detectability |
| `mu_plus` | positive-day sampled-minute probability |
| `E` | sampled-minute acoustic exposure, `psi * p * mu_plus` |
| `q025`, `q975` | lower and upper limits of a 95% Bayesian credible interval |
| `ELPD` | expected log predictive density for complete held-station histories |
| `PID` | Prediction Interpretation Domain, an ecological reporting label |
| `AOA` | Area of Applicability, a monitored predictor-space support label |

Percent columns are stored on a 0–100 scale; probability columns are stored on a 0–1 scale. Missing values are empty CSV fields, never coded as zero.

## Model-ready inputs for `make full`

| Asset | Required fields |
|---|---|
| `survey_effort` | `station_id`, `date`, `scheduled_minutes`, `usable_minutes` |
| `acoustic_detections` | `station_id`, `date`, `sampled_minute`, `species_group`; optional `retained` or `positive` |
| `weekly_covariates_*` | `station_id`, `study_week` and the registered environmental predictors |
| `daily_detection_covariates` | station/week/day keys, anthropogenic-event rate and frog-event rate |
| `fold_registry` | `station_id`, `fold_id` |
| `joint_daily_data` | daily counts plus the Koel, host, environmental and observation covariates used by the joint Stan model |
| `hourly_calling_counts` | `station_id`, `date`, `clock_hour`, `positive_minutes`, `sampled_minutes` |
| `training_predictors_250` | station ID and seven environmental predictors |
| `city_predictors_250` | cell ID, seven predictors, dominant land cover and permanent-water flag |
| `planning_sensitive_points` | `cell_id`, `context_class` |
| `urban_function_overlap` | `cell_id`, `context_class`, `overlap_area_m2` |
| `monitoring_candidates` | private candidate ID, projected coordinates and seven predictors |

The seven environmental predictors are `trees`, `built`, `grass`, `road_density`, `tree_edge_area_50m`, `dist_water_m_nearest` and `elevation`. Exact geometry stays outside the public repository.
