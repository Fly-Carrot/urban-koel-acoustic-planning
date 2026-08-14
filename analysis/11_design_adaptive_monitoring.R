# Purpose: Produce nested Coverage Expansion and Prediction Validation deployment sequences.
# Inputs: anonymised sequence summaries; full runs require approved candidate geometries.
# Outputs: outputs/tables/adaptive_monitoring_sequences.csv.
# Profiles: smoke, verify, full.
# Boundary: sequences are transparent greedy designs, not globally optimal networks or deployment approval.
source(file.path("R", "release_utils.R"))
run_public_step("11_design_adaptive_monitoring", parse_profile())

