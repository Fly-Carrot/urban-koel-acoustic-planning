# Prepare daily survey histories; see R/survey_histories.R.

source(file.path("R", "release_utils.R"))
source(file.path("R", "full_pipeline.R"))
run_analysis_step("01_prepare_survey_histories")
