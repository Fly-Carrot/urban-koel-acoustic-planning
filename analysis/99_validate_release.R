# Purpose: Enforce final scientific, terminology, privacy and release invariants.
# Inputs: every public output and repository contract.
# Outputs: outputs/diagnostics/release_validation.csv and final step log.
# Profiles: smoke, verify, full.
# Boundary: any failed invariant exits non-zero and blocks release.
source(file.path("R", "release_utils.R"))
run_public_step("99_validate_release", parse_profile())

