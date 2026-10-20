# Load the functions used by the analysis scripts.
for (file in c(
  "analysis_io.R", "survey_histories.R", "environmental_predictors.R",
  "occupancy_models.R", "transfer_validation.R", "calling_density.R",
  "city_prediction.R", "exposure_prediction.R", "prediction_support.R",
  "planning_overlap.R", "monitoring_design.R", "study_inputs.R"
)) source(file.path("R", file))
