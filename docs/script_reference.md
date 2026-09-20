# Script reference

The scripts run in manuscript order. `verify` checks the published summaries; `full` runs the corresponding analysis with approved model-ready inputs.

## `00_preflight`

- Checks the input manifest and repository files.
- Full input: `data/full/manifest.csv`.

## `01_prepare_survey_histories`

- Joins recording effort to retained detections.
- Writes daily histories and assigns zero only to effort-confirmed surveys.

## `02_select_detection_backbone`

- Fits effort-only and acoustic-context detection models.
- Compares them with PSIS-LOO and convergence summaries.

## `03_build_environmental_predictors`

- Checks the seven station and city predictors used by the models.
- Keeps station-centred ecological neighbourhoods separate from reporting cells.

## `04_fit_potential_host_opportunity`

- Fits weekly detection-corrected models for corvids, sturnids and Masked Laughingthrush.
- Saves model objects and coefficient summaries.

## `05_fit_koel_weekly_opportunity`

- Fits no-host and three-host Koel models.
- Propagates three complete posterior host surfaces through three Koel refits.

## `06_validate_scale_and_transfer`

- Withholds complete stations in five folds.
- Repeats host and Koel fitting at 100, 250 and 500 m, then reports ELPD, Brier score and calibration.

## `07_fit_joint_calling_density`

- Fits the daily hurdle-density model and the hourly extension in Stan.
- Combines aligned weekly opportunity, detectability and positive-day minute density.

## `08_predict_citywide_activity`

- Projects the coordinate-free three-host model across 52 weeks.
- Writes posterior means, medians, credible intervals and interval width for every cell-week.

## `09_classify_prediction_support`

- Derives PID from land-cover context.
- Derives AOA from training ranges and nearest-station environmental distance.

## `10_summarise_planning_overlap`

- Joins supported predictions to planning-sensitive points and urban-function areas.
- Uses one weight per point and overlap area for polygons.

## `11_design_adaptive_monitoring`

- Greedily expands environmental coverage in Monitoring Gaps.
- Separately ranks uncertain spring predictions for field validation.

## `12_make_manuscript_outputs`

- Collects model, validation, prediction and monitoring summaries.
- Does not refit models.

## `99_validate_release`

- Confirms that all expected outputs were created.
- The public route also checks reported totals, checksums and excluded file types.
