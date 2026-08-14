# Purpose: Summarise supported predictions across planning-sensitive places and urban functions.
# Inputs: aggregate posterior planning summaries; full runs require licensed spatial layers.
# Outputs: outputs/tables/planning_overlap.csv.
# Profiles: smoke, verify, full.
# Boundary: summaries use Primary Results + Moderate Extrapolation and do not measure realised disturbance.
source(file.path("R", "release_utils.R"))
run_public_step("10_summarise_planning_overlap", parse_profile())

