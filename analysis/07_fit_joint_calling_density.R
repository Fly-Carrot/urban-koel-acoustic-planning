# Fit daily and hourly calling density; see R/calling_density.R and stan/.

source(file.path("R", "release_utils.R"))
source(file.path("R", "full_pipeline.R"))
run_analysis_step("07_fit_joint_calling_density")
