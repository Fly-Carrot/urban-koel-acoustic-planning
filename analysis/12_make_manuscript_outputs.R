# Collect output tables; see R/full_pipeline.R.

source(file.path("R", "release_utils.R"))
source(file.path("R", "full_pipeline.R"))
run_analysis_step("12_make_manuscript_outputs")
