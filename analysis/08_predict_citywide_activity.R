# Purpose: Rebuild weekly opportunity and sampled-minute exposure summaries for the city mapping subset.
# Inputs: frozen weekly prediction summaries or approved full city predictors.
# Outputs: outputs/tables/weekly_acoustic_opportunity.csv and weekly_acoustic_exposure.csv.
# Profiles: smoke, verify, full.
# Boundary: city prediction consumes the transfer model; support labels never modify predictions.
source(file.path("R", "release_utils.R"))
run_public_step("08_predict_citywide_activity", parse_profile())

