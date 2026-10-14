# Notes for each script

The numbered files in `analysis/` select a step. Calculations are in the linked R files. `make verify` checks stored summaries; `make full` runs the modelling functions with additional inputs. Read [code coverage](analysis_coverage.md) before attempting a study reproduction.

For retained study inputs, use [fit_released_input.R](../analysis/fit_released_input.R). It reads the already-standardised model designs, preserves missing surveys and fits the named model with its verified seed and settings. Use [reproduce_retained.R](../analysis/reproduce_retained.R) to recalculate all weekly predictions, joint-model dawn summaries and monitoring sequences without fitting again.

## `00_preflight`

[Code](../R/full_pipeline.R): check the required input entries in `data/full/manifest.csv`. The public-summary run instead checks the released files.

## `01_prepare_survey_histories`

[Code](../R/survey_histories.R): join recording effort to retained detections. Input: `survey_effort` and `acoustic_detections`. Output: daily histories and reconciliation totals. Zeros are assigned only to recorded surveys.

## `02_select_detection_backbone`

[Code](../R/occupancy_models.R): fit effort-only and acoustic-context detection models using daily histories and observation covariates. Output: PSIS-LOO comparisons and convergence summaries.

## `03_build_environmental_predictors`

[Code](../R/environmental_predictors.R): check the seven station and city predictors at the supplied scales. Output: completeness and predictor checks. Ecological neighbourhoods and reporting cells remain separate.

## `04_fit_potential_host_opportunity`

[Code](../R/occupancy_models.R): fit weekly models for corvids, sturnids and Masked Laughingthrush from host histories and covariates. Output: model objects and coefficient summaries.

## `05_fit_koel_weekly_opportunity`

[Code](../R/occupancy_models.R): fit no-host and three-host Koel models. Three complete host posterior surfaces enter three separate Koel fits. Output: fitted models and coefficient summaries.

## `06_validate_scale_and_transfer`

[Code](../R/transfer_validation.R): withhold whole stations in five folds; refit hosts and Koel models using training-only scaling at the retained 250 m scale. Output: held-station predictions, ELPD, Brier scores and calibration. Complete station histories share an unseen-station effect; host fits are pooled on the probability scale. Historical 100/500 m benchmarks stay separate.

## `07_fit_joint_calling_density`

[Code](../R/calling_density.R): fit three HEQZ daily joint models and a D1 hourly model in Stan. Input: daily/hourly counts and matching covariates. Output: fits and posterior summaries. D1 retains surveyed zero-count hours within positive days.

## `08_predict_citywide_activity`

[City code](../R/city_prediction.R) and [exposure code](../R/exposure_prediction.R): project model draws over 52 annual weeks. Input: city predictors and fitted draws. Output: cell-week opportunity, credible intervals, hourly and all-day exposure. Matched HEQZ and D1 components are combined before summarising; the reference day has 144 sampled minutes.

## `09_classify_prediction_support`

[Code](../R/prediction_support.R): derive PID from land cover and AOA from the monitored predictor space. Input: station and city predictors. Output: support classes per cell. Distances use root-mean-square standardised differences; PID PASS + AOA Boundary is Primary Results. Invalid predictors stay invalid.

## `10_summarise_planning_overlap`

[Code](../R/planning_overlap.R): join supported predictions to planning-sensitive points and urban-function areas. Points have equal weights; polygons use overlap area. Output: grouped weekly opportunity for new inputs. The retained-study entry uses [reproduce_study.R](../R/reproduce_study.R) for annual/seasonal opportunity and dawn expected-count/probability summaries from the joint HEQZ/D1 components.

## `11_design_adaptive_monitoring`

[Code](../R/monitoring_design.R): rank coverage candidates and uncertain spring predictions. Input: predictors, existing-site distances, support, uncertainty and spacing-conflict pairs. Each coverage selection updates predictor ranges and nearest dissimilarity using the frozen dmax. Output: two retained-rule sequences and nested deployment portfolios.

## `12_make_manuscript_outputs`

[Code](../R/full_pipeline.R): collect the preceding model, validation, prediction and monitoring tables. No models are refitted.

## `99_validate_release`

[Model-output checks](../R/full_pipeline.R) and [public-summary checks](../R/validate_release.R): check that expected outputs exist. The public route also checks reported totals, file hashes and excluded file types.
