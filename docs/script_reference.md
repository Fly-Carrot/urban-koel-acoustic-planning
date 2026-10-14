# Notes for each script

The numbered files in `analysis/` select a step. Calculations are in the linked R files. `make verify` checks stored summaries; `make full` runs the modelling functions with additional inputs. Read [code coverage](analysis_coverage.md) before attempting a study reproduction.

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

[Code](../R/transfer_validation.R): withhold whole stations in five folds; refit hosts and Koel models using training-only scaling. Input: folds and covariates at 100, 250 and 500 m. Output: held-station predictions, ELPD, Brier scores and calibration. Complete station histories share an unseen-station effect; host fits are pooled on the probability scale.

## `07_fit_joint_calling_density`

[Code](../R/calling_density.R): fit three HEQZ daily joint models and a D1 hourly model in Stan. Input: daily/hourly counts and matching covariates. Output: fits and posterior summaries. D1 retains surveyed zero-count hours within positive days.

## `08_predict_citywide_activity`

[City code](../R/city_prediction.R) and [exposure code](../R/exposure_prediction.R): project model draws over 52 annual weeks. Input: city predictors and fitted draws. Output: cell-week opportunity, credible intervals, hourly and all-day exposure. Matched HEQZ and D1 components are combined before summarising; the reference day has 144 sampled minutes.

## `09_classify_prediction_support`

[Code](../R/prediction_support.R): derive PID from land cover and AOA from the monitored predictor space. Input: station and city predictors. Output: support classes per cell. The current Boundary-to-tier mapping differs from the paper; see [code coverage](analysis_coverage.md).

## `10_summarise_planning_overlap`

[Code](../R/planning_overlap.R): join supported predictions to planning-sensitive points and urban-function areas. Points have equal weights; polygons use overlap area. Output: grouped weekly opportunity. The public function does not yet calculate the published dawn metrics.

## `11_design_adaptive_monitoring`

[Code](../R/monitoring_design.R): rank coverage candidates and uncertain spring predictions. Input: candidate predictors, coordinates, support and uncertainty. Output: two sequences. Eligibility, spacing and support updates differ from the study rules; see [code coverage](analysis_coverage.md).

## `12_make_manuscript_outputs`

[Code](../R/full_pipeline.R): collect the preceding model, validation, prediction and monitoring tables. No models are refitted.

## `99_validate_release`

[Model-output checks](../R/full_pipeline.R) and [public-summary checks](../R/validate_release.R): check that expected outputs exist. The public route also checks reported totals, file hashes and excluded file types.
