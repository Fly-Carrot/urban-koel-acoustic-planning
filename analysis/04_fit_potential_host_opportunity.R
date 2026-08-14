# Purpose: Define three detection-corrected potential-host acoustic-opportunity layers.
# Inputs: host-group registry; full runs require daily host detection histories.
# Outputs: outputs/tables/host_groups.csv.
# Profiles: smoke, verify, full.
# Boundary: acoustic co-occurrence is predictive context, not confirmed host use.
source(file.path("R", "release_utils.R"))
run_public_step("04_fit_potential_host_opportunity", parse_profile())

