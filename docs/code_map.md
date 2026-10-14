# Methods-to-code map

The numbered script runs a step; the linked R file contains its calculations. Input fields are described in the [data dictionary](data_dictionary.md). This map describes the public code; see [code coverage](analysis_coverage.md) for differences from the study analysis.

| Method | Run script | Calculation code | Input | Output |
|---|---|---|---|---|
| Survey histories | [01](../analysis/01_prepare_survey_histories.R) | [survey_histories.R](../R/survey_histories.R) | effort and retained detections | daily histories |
| Detection models | [02](../analysis/02_select_detection_backbone.R) | [occupancy_models.R](../R/occupancy_models.R) | histories and observation covariates | model comparison |
| Environmental predictors | [03](../analysis/03_build_environmental_predictors.R) | [environmental_predictors.R](../R/environmental_predictors.R) | station and city predictors | predictor checks |
| Potential hosts | [04](../analysis/04_fit_potential_host_opportunity.R) | [occupancy_models.R](../R/occupancy_models.R) | host histories | three host fits |
| Koel opportunity | [05](../analysis/05_fit_koel_weekly_opportunity.R) | [occupancy_models.R](../R/occupancy_models.R) | Koel history and host draws | no-host and three-host fits |
| Spatial transfer | [06](../analysis/06_validate_scale_and_transfer.R) | [transfer_validation.R](../R/transfer_validation.R) | station folds at the retained 250 m scale | held-station predictions and scores |
| Calling density | [07](../analysis/07_fit_joint_calling_density.R) | [calling_density.R](../R/calling_density.R) · [Stan](../stan/README.md) | daily and hourly minute counts | fits and posterior summaries |
| City prediction | [08](../analysis/08_predict_citywide_activity.R) | [city_prediction.R](../R/city_prediction.R) · [exposure_prediction.R](../R/exposure_prediction.R) | model draws and city predictors | cell-week predictions and exposure |
| PID and AOA | [09](../analysis/09_classify_prediction_support.R) | [prediction_support.R](../R/prediction_support.R) | land cover and monitored predictor space | support classes |
| Planning overlap | [10](../analysis/10_summarise_planning_overlap.R) | [planning_overlap.R](../R/planning_overlap.R) | predictions, points and overlap areas | grouped weekly opportunity |
| Monitoring design | [11](../analysis/11_design_adaptive_monitoring.R) | [monitoring_design.R](../R/monitoring_design.R) | gaps, uncertainty and candidates | two candidate sequences |
| Collect outputs | [12](../analysis/12_make_manuscript_outputs.R) | [full_pipeline.R](../R/full_pipeline.R) | preceding outputs | selected tables |

[00](../analysis/00_preflight.R) checks inputs; [99](../analysis/99_validate_release.R) checks outputs. The same step names are used for summary checks and model fitting; their behaviour depends on the command (`make verify` or `make full`).

For the retained study, [fit_released_input.R](../analysis/fit_released_input.R) reads exported model matrices, and [reproduce_retained.R](../analysis/reproduce_retained.R) recalculates weekly predictions, joint-model dawn summaries and monitoring sequences. This route preserves scaling and draw schedules without raw recordings or precise geometry.
