# Script reference

The scripts run in manuscript order. `verify` checks the published summaries; `full` implements the selected workflow with approved model-ready inputs. See [analysis_coverage.md](analysis_coverage.md) for differences from the archived analysis, and [mcmc_settings.md](mcmc_settings.md) for the retained sampling settings.

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
- Scores complete station histories with one shared unseen-station effect; pools host imputations as an equal-weight probability mixture.

## `07_fit_joint_calling_density`

- Fits three HEQZ daily joint models and a D1 hourly model in Stan.
- D1 uses annual terms and two hour harmonics, conditioning on a positive day.

## `08_predict_citywide_activity`

- Projects the coordinate-free three-host model across 52 weeks.
- Writes posterior means, medians, credible intervals and interval width for every cell-week.
- Combines matched HEQZ occurrence, detection and host-season density draws with D1 hour effects. Uses 144 scheduled minutes per reference day; multiplies components before summarising exposure.

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
