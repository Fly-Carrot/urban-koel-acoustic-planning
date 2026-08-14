# Purpose: Fit or verify weekly Koel acoustic opportunity using habitat, season and host context.
# Inputs: model effects, formula registry and host-posterior surfaces.
# Outputs: outputs/tables/model_effects.csv.
# Profiles: smoke and verify use frozen posterior summaries; full refits Bayesian models.
# Boundary: the three-host block is evaluated jointly and does not identify independent host effects.
source(file.path("R", "release_utils.R"))
run_public_step("05_fit_koel_weekly_opportunity", parse_profile())

