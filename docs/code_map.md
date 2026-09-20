# Methods-to-code map

| Manuscript step | Driver | Main functions | Main input | Main output |
|---|---|---|---|---|
| Survey histories | `analysis/01_prepare_survey_histories.R` | `prepare_survey_histories()` | effort and acoustic detections | daily histories |
| Detection model | `analysis/02_select_detection_backbone.R` | `run_detection_models()` | daily histories and observation covariates | model comparison |
| Environmental predictors | `analysis/03_build_environmental_predictors.R` | `validate_environmental_predictors()` | station and city predictors | predictor check |
| Potential hosts | `analysis/04_fit_potential_host_opportunity.R` | `run_host_models()` | host histories | three host models |
| Koel opportunity | `analysis/05_fit_koel_weekly_opportunity.R` | `run_koel_models()` | Koel history and host posterior surfaces | no-host and three-host models |
| Spatial transfer | `analysis/06_validate_scale_and_transfer.R` | `run_transfer_validation()` | five station folds and three scales | held-station predictions and scores |
| Calling density | `analysis/07_fit_joint_calling_density.R` | `run_calling_density_models()` | daily and hourly positive-minute counts | Stan fits and summaries |
| City prediction | `analysis/08_predict_citywide_activity.R` | `run_city_prediction()` | model draws and city predictors | cell-week predictions |
| PID and AOA | `analysis/09_classify_prediction_support.R` | `classify_prediction_support()` | land cover and environmental space | support class per cell |
| Planning overlap | `analysis/10_summarise_planning_overlap.R` | `run_planning_overlap()` | supported predictions and planning layers | grouped summaries |
| Monitoring design | `analysis/11_design_adaptive_monitoring.R` | `run_monitoring_design()` | gaps, uncertainty and candidates | two ranked sequences |
| Manuscript outputs | `analysis/12_make_manuscript_outputs.R` | `collect_full_outputs()` | preceding outputs | selected tables |

Shared formulas and fitting functions are in `R/occupancy_models.R`. Stan programs are in `stan/`.
