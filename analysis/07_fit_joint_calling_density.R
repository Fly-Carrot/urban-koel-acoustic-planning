# Purpose: Verify positive-day minute density and combine aligned posterior components into exposure.
# Inputs: calling-density coefficients, psi and p posterior products.
# Outputs: outputs/tables/model_effects.csv and the derived-metric contract.
# Profiles: smoke and verify check reported summaries; full invokes public Stan models.
# Boundary: window probabilities come from beta-binomial posterior prediction, not independent minutes.
source(file.path("R", "release_utils.R"))
run_public_step("07_fit_joint_calling_density", parse_profile())

