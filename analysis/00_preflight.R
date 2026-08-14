# Purpose: Validate the public release contract before scientific work begins.
# Inputs: repository structure, registries, frozen reference manifests.
# Outputs: outputs/logs/00_preflight.csv.
# Profiles: smoke, verify, full.
# Boundary: checks availability and safety; it never changes scientific data.
source(file.path("R", "release_utils.R"))
run_public_step("00_preflight", parse_profile())

