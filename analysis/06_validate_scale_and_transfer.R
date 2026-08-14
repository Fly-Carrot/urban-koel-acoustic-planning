# Purpose: Test transfer to wholly withheld stations and compare 100, 250 and 500 m neighbourhoods.
# Inputs: frozen validation summaries or full fold-specific predictions.
# Outputs: outputs/tables/transfer_validation.csv.
# Profiles: smoke, verify, full.
# Boundary: formula selection preceded CV; this is conditional validation of a frozen pipeline.
source(file.path("R", "release_utils.R"))
run_public_step("06_validate_scale_and_transfer", parse_profile())

