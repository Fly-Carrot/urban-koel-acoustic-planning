# Purpose: Cross-classify ecological interpretation (PID) and statistical applicability (AOA).
# Inputs: prediction-support registry and conditional full predictor-space distances.
# Outputs: outputs/tables/prediction_support_classes.csv.
# Profiles: smoke, verify, full.
# Boundary: Monitoring Gaps are unsupported environments, never zero acoustic activity.
source(file.path("R", "release_utils.R"))
run_public_step("09_classify_prediction_support", parse_profile())

