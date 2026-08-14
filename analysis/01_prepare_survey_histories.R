# Purpose: Reconcile effort-confirmed days, missing days and Koel detections.
# Inputs: frozen survey reconciliation or approved full-profile acoustic histories.
# Outputs: outputs/tables/survey_reconciliation.csv.
# Profiles: smoke and verify copy validated summaries; full requires model-ready histories.
# Boundary: effort-confirmed zero detections remain distinct from missing effort.
source(file.path("R", "release_utils.R"))
run_public_step("01_prepare_survey_histories", parse_profile())

