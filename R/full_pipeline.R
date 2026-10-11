source(file.path("R", "analysis_io.R"))
source(file.path("R", "survey_histories.R"))
source(file.path("R", "environmental_predictors.R"))
source(file.path("R", "occupancy_models.R"))
source(file.path("R", "transfer_validation.R"))
source(file.path("R", "calling_density.R"))
source(file.path("R", "city_prediction.R"))
source(file.path("R", "exposure_prediction.R"))
source(file.path("R", "prediction_support.R"))
source(file.path("R", "planning_overlap.R"))
source(file.path("R", "monitoring_design.R"))

check_full_inputs <- function() {
  manifest <- read_full_manifest()
  required <- c(
    "survey_effort", "acoustic_detections", "weekly_covariates",
    "weekly_covariates_100", "weekly_covariates_250", "weekly_covariates_500",
    "daily_detection_covariates", "fold_registry", "joint_daily_data",
    "hourly_calling_counts", "host_density_scaling", "training_predictors_250", "city_predictors_250",
    "planning_sensitive_points", "urban_function_overlap", "monitoring_candidates"
  )
  missing <- setdiff(required, manifest$asset_id)
  if (length(missing)) stop("Full-data manifest is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  invisible(manifest)
}

collect_full_outputs <- function() {
  files <- c(
    "01_survey_histories/survey_reconciliation.csv",
    "02_detection/detection_model_comparison.csv",
    "04_host_models/host_model_effects.csv",
    "05_koel_models/koel_model_effects.csv",
    "06_transfer_validation/heldout_metrics.csv",
    "07_calling_density/joint_daily_summary.csv",
    "08_city_prediction/city_week_predictions.csv",
    "09_prediction_support/prediction_support_counts.csv",
    "10_planning_overlap/planning_overlap_summary.csv",
    "11_monitoring_design/monitoring_sequences.csv"
  )
  destination <- full_output_dir("12_manuscript_outputs")
  for (file in files) {
    source_path <- file.path(full_output_dir(), file)
    if (!file.exists(source_path)) stop("Missing analysis output: ", file, call. = FALSE)
    file.copy(source_path, file.path(destination, basename(file)), overwrite = TRUE)
  }
}

validate_full_outputs <- function() {
  expected <- c(
    "01_survey_histories/daily_survey_histories.csv",
    "02_detection/detection_model_comparison.csv",
    "04_host_models/host_models.rds",
    "05_koel_models/koel_models.rds",
    "06_transfer_validation/heldout_predictions.csv",
    "07_calling_density/joint_daily_summary.csv",
    "08_city_prediction/city_week_predictions.csv",
    "09_prediction_support/prediction_support_by_cell.csv",
    "10_planning_overlap/planning_overlap_summary.csv",
    "11_monitoring_design/monitoring_sequences.csv"
  )
  present <- file.exists(file.path(full_output_dir(), expected))
  write_table(data.frame(file = expected, present = present),
              file.path(full_output_dir("99_validation"), "full_output_check.csv"))
  if (!all(present)) stop("The full analysis is incomplete.", call. = FALSE)
}

run_full_step <- function(step) {
  switch(step,
    "00_preflight" = check_full_inputs(),
    "01_prepare_survey_histories" = run_prepare_survey_histories(),
    "02_select_detection_backbone" = run_detection_models(),
    "03_build_environmental_predictors" = validate_environmental_predictors(),
    "04_fit_potential_host_opportunity" = run_host_models(),
    "05_fit_koel_weekly_opportunity" = run_koel_models(),
    "06_validate_scale_and_transfer" = run_transfer_validation(),
    "07_fit_joint_calling_density" = run_calling_density_models(),
    "08_predict_citywide_activity" = run_city_prediction(),
    "09_classify_prediction_support" = run_prediction_support(),
    "10_summarise_planning_overlap" = run_planning_overlap(),
    "11_design_adaptive_monitoring" = run_monitoring_design(),
    "12_make_manuscript_outputs" = collect_full_outputs(),
    "99_validate_release" = validate_full_outputs(),
    stop("Unknown analysis step: ", step, call. = FALSE)
  )
}

run_analysis_step <- function(step) {
  profile <- parse_profile()
  if (profile == "full") run_full_step(step) else run_public_step(step, profile)
}
