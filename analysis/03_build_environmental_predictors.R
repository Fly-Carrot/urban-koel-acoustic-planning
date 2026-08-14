# Purpose: Validate landscape, season, coordinate and reporting-support definitions.
# Inputs: predictor registry; conditional full inputs require licensed source assets.
# Outputs: outputs/tables/predictor_registry_public.csv.
# Profiles: smoke, verify, full.
# Boundary: circular ecological buffers are distinct from HEX reporting geometry.
source(file.path("R", "release_utils.R"))
run_public_step("03_build_environmental_predictors", parse_profile())

