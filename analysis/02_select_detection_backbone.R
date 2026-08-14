# Purpose: Register the daily observation model used throughout the frozen pipeline.
# Inputs: model registry and, for full runs, effort-confirmed daily covariates.
# Outputs: outputs/tables/model_registry_public.csv.
# Profiles: smoke, verify, full.
# Boundary: observation covariates affect detectability p, not ecological opportunity psi.
source(file.path("R", "release_utils.R"))
run_public_step("02_select_detection_backbone", parse_profile())

