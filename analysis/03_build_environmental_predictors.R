# Check environmental predictors; see R/environmental_predictors.R.

source(file.path("R", "release_utils.R"))
source(file.path("R", "full_pipeline.R"))
run_analysis_step("03_build_environmental_predictors")
