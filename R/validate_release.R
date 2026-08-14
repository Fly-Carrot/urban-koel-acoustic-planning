validate_release <- function(root = repo_root()) {
  reconciliation <- read_csv_release(file.path(root, "data", "processed", "reference", "survey_reconciliation.csv"))
  assert_release(all(reconciliation$pass), "Survey counts do not reconcile.")

  support <- read_csv_release(file.path(root, "data", "processed", "reference", "prediction_support_classes.csv"))
  assert_release(sum(support$n_hex) == 13714L, "Support-class total changed.")
  assert_release(sum(support$n_hex[support$support_class %in% c("Primary Results", "Moderate Extrapolation")]) == 5745L,
                 "Planning-domain total changed.")

  transfer <- read_csv_release(file.path(root, "data", "processed", "reference", "transfer_validation.csv"))
  host <- transfer[transfer$comparison == "three_host_minus_no_host_coordinate_free", ]
  assert_release(abs(host$estimate - 17.9578842) < 1e-6, "Held-station host-block ELPD anchor changed.")
  assert_release(host$interval_low > 0, "Held-station host-block interval no longer excludes zero.")

  weekly <- read_csv_release(file.path(root, "data", "processed", "reference", "weekly_acoustic_opportunity.csv"))
  assert_release(nrow(weekly) == 52L && identical(weekly$calendar_week, 1:52), "Annual week registry changed.")

  deployment <- read_csv_release(file.path(root, "data", "processed", "reference", "adaptive_monitoring_sequences.csv"))
  d15 <- deployment[deployment$deployment_size == 15L, ]
  assert_release(sum(d15$route == "Coverage Expansion") == 9L, "Expected nine Coverage Expansion sites at deployment size 15.")
  assert_release(sum(d15$route == "Prediction Validation") == 6L, "Expected six Prediction Validation sites at deployment size 15.")

  summary <- data.frame(
    check = c("survey_reconciliation", "support_total", "planning_domain", "host_transfer", "annual_weeks", "deployment_15"),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_csv_release(summary, file.path(root, "outputs", "diagnostics", "release_validation.csv"))
  invisible(summary)
}

