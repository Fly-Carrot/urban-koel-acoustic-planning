source(file.path("R", "release_utils.R"))
source(file.path("R", "validate_release.R"))
root <- repo_root()
validate_release(root)

code_files <- c(
  list.files(file.path(root, "R"), pattern = "[.]R$", full.names = TRUE),
  list.files(file.path(root, "analysis"), pattern = "[.]R$", full.names = TRUE)
)
invisible(lapply(code_files, parse))

source(file.path(root, "R", "occupancy_models.R"))
source(file.path(root, "R", "calling_density.R"))
full <- full_mcmc_settings()
validation <- full_mcmc_settings("validation")
detection <- full_mcmc_settings("detection")
assert_release(full$n.batch * full$batch.length == 30000L && full$n.burn == 10000L,
               "Full-data sampling profile changed.")
assert_release(validation$n.batch * validation$batch.length == 60000L && validation$n.burn == 20000L,
               "Whole-station sampling profile changed.")
assert_release(detection$n.batch * detection$batch.length == 50000L && detection$n.burn == 20000L,
               "Detection sampling profile changed.")
assert_release(identical(stan_sampling_settings("daily")$iter_sampling, 750L) &&
                 identical(stan_sampling_settings("hourly")$iter_sampling, 1000L),
               "Stan sampling profiles changed.")

if (requireNamespace("data.table", quietly = TRUE)) {
  source(file.path(root, "R", "analysis_io.R"))
  source(file.path(root, "R", "survey_histories.R"))
  source(file.path(root, "R", "environmental_predictors.R"))
  source(file.path(root, "R", "occupancy_models.R"))
  source(file.path(root, "R", "prediction_support.R"))
  source(file.path(root, "R", "city_prediction.R"))
  source(file.path(root, "R", "planning_overlap.R"))
  effort <- data.frame(
    station_id = c("A", "A", "B"),
    date = c("2026-01-01", "2026-01-02", "2026-01-01"),
    scheduled_minutes = 10,
    usable_minutes = c(10, 0, 10)
  )
  detections <- data.frame(
    station_id = c("A", "B"),
    date = c("2026-01-01", "2026-01-01"),
    sampled_minute = c(1, 2),
    species_group = c("koel", "corvid")
  )
  history <- prepare_survey_histories(effort, detections)
  assert_release(nrow(history) == 6L, "Survey-history expansion failed.")
  assert_release(sum(history$detected, na.rm = TRUE) == 2L, "Positive days were not retained.")
  assert_release(sum(is.na(history$positive_minutes)) == 2L, "Missing effort was converted to absence.")

  fake_fit <- list(
    psi.samples = array(stats::runif(12 * 3 * 5), dim = c(12, 3, 5)),
    n.chains = 4L
  )
  schedule <- chain_stratified_host_draws(
    list(corvid = fake_fit, sturnid = fake_fit, laughingthrush = fake_fit),
    M = 3L
  )
  assert_release(nrow(schedule) == 3L, "Host-draw schedule failed.")

  grid <- city_week_grid(data.frame(cell_id = c("X", "Y"), trees = c(0, 1)))
  assert_release(nrow(grid) == 104L, "City-week expansion failed.")
  posterior_summary <- posterior_group_summary(
    matrix(c(0.1, 0.2, 0.3, 0.4, 0.2, 0.3, 0.4, 0.5), nrow = 2),
    row_index = c(1, 2),
    weight = c(1, 2)
  )
  assert_release(posterior_summary$q975 >= posterior_summary$q025,
                 "Planning posterior summary failed.")
}

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
if (requireNamespace("data.table", quietly = TRUE) && requireNamespace("reformulas", quietly = TRUE)) {
  source("tests/test_final_calculations.R")
} else {
  stop("Install verification packages with make setup, then rerun make test.",call.=FALSE)
}
source("tests/test_study_alignment.R")
