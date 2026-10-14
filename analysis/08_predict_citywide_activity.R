# Predict citywide activity; see R/city_prediction.R and R/exposure_prediction.R.

source(file.path("R", "release_utils.R"))
source(file.path("R", "full_pipeline.R"))
run_analysis_step("08_predict_citywide_activity")
