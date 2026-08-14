args <- commandArgs(trailingOnly = TRUE)
source(file.path("R", "release_utils.R"))
profile <- parse_profile(args)
drivers <- c(
  "00_preflight.R", "01_prepare_survey_histories.R", "02_select_detection_backbone.R",
  "03_build_environmental_predictors.R", "04_fit_potential_host_opportunity.R",
  "05_fit_koel_weekly_opportunity.R", "06_validate_scale_and_transfer.R",
  "07_fit_joint_calling_density.R", "08_predict_citywide_activity.R",
  "09_classify_prediction_support.R", "10_summarise_planning_overlap.R",
  "11_design_adaptive_monitoring.R", "12_make_manuscript_outputs.R", "99_validate_release.R"
)
for (driver in drivers) {
  status <- system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", file.path("analysis", driver), paste0("--profile=", profile)))
  if (!identical(status, 0L)) stop("Pipeline stopped at ", driver, call. = FALSE)
}
cat(sprintf("%s profile completed successfully.\n", profile))

