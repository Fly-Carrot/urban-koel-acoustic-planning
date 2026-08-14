# Purpose: Generate a compact verification figure and machine-readable manuscript tables.
# Inputs: verified public summaries only.
# Outputs: outputs/figures/verification_overview.pdf and copied tables.
# Profiles: smoke, verify, full.
# Boundary: this driver never fits a model and never changes reported numerical products.
source(file.path("R", "release_utils.R"))
run_public_step("12_make_manuscript_outputs", parse_profile())

