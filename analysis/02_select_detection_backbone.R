# Compare daily detection models; see R/occupancy_models.R.

source(file.path("R", "release_utils.R"))
source(file.path("R", "full_pipeline.R"))
run_analysis_step("02_select_detection_backbone")
