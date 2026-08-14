source(file.path("R", "release_utils.R"))
source(file.path("R", "validate_release.R"))
root <- repo_root()
validate_release(root)

effects <- read_csv_release(file.path(root, "data", "processed", "reference", "model_effects.csv"))
tree <- effects[effects$component == "weekly_opportunity" & effects$term == "tree_cover", ]
sturnid <- effects[effects$component == "weekly_opportunity" & effects$term == "sturnid_opportunity", ]
host_mu <- effects[effects$component == "positive_day_minute_probability" & effects$term == "equal_scale_potential_host_opportunity", ]
assert_release(tree$q975 < 0, "Tree-cover interval should remain below zero.")
assert_release(sturnid$q025 > 0, "Sturnid-opportunity interval should remain above zero.")
assert_release(host_mu$q025 > 0, "Calling-density host-index interval should remain above zero.")

contract_log <- tempfile("contract-", fileext = ".log")
contract_status <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", "tools/validate_contract.R"),
  stdout = contract_log,
  stderr = contract_log
)
if (!identical(contract_status, 0L)) {
  cat(readLines(contract_log, warn = FALSE), sep = "\n")
  stop("Release contract failed inside the numerical test suite.", call. = FALSE)
}
cat("All numerical and release-contract tests passed.\n")
