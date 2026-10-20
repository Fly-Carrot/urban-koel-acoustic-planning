# Collect the tables calculated by steps 01–11.
source("R/load.R")
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
  if (!file.copy(source_path, file.path(destination, basename(file)), overwrite = TRUE)) {
    stop("Could not save output: ", file, call. = FALSE)
  }
}
