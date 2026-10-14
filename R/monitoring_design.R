# Rank additional monitoring candidates using environmental coverage and uncertainty.

far_enough <- function(candidate, chosen, minimum_distance) {
  if (!length(chosen)) return(TRUE)
  all(sqrt((candidate$x - vapply(chosen, `[[`, numeric(1), "x"))^2 +
             (candidate$y - vapply(chosen, `[[`, numeric(1), "y"))^2) >= minimum_distance)
}

select_coverage_expansion <- function(candidates, gaps, predictors, threshold,
                                      n = 9L, minimum_distance = 1000) {
  chosen <- list()
  covered <- rep(FALSE, nrow(gaps))
  for (rank in seq_len(n)) {
    best <- NULL
    best_gain <- -1L
    for (i in seq_len(nrow(candidates))) {
      candidate <- candidates[i, , drop = FALSE]
      if (candidate$candidate_id %in% vapply(chosen, `[[`, character(1), "candidate_id")) next
      if (!far_enough(candidate, chosen, minimum_distance)) next
      distance <- sqrt(rowSums((as.matrix(gaps[, predictors, drop = FALSE]) -
                                 matrix(as.numeric(candidate[, predictors]), nrow(gaps),
                                        length(predictors), byrow = TRUE))^2))
      gain <- sum(!covered & distance <= threshold)
      if (gain > best_gain) {
        best <- as.list(candidate)
        best$covered <- distance <= threshold
        best_gain <- gain
      }
    }
    if (is.null(best)) break
    covered <- covered | best$covered
    best$route_rank <- rank
    best$additional_gaps_covered <- best_gain
    chosen[[length(chosen) + 1L]] <- best
  }
  chosen
}

select_prediction_validation <- function(candidates, n = 6L, minimum_distance = 1000) {
  candidates <- candidates[order(candidates$uncertainty_width, decreasing = TRUE), , drop = FALSE]
  chosen <- list()
  for (i in seq_len(nrow(candidates))) {
    candidate <- as.list(candidates[i, , drop = FALSE])
    if (far_enough(candidate, chosen, minimum_distance)) {
      candidate$route_rank <- length(chosen) + 1L
      chosen[[length(chosen) + 1L]] <- candidate
    }
    if (length(chosen) == n) break
  }
  chosen
}

public_sequence <- function(chosen, route, prefix) {
  if (!length(chosen)) return(data.frame())
  data.frame(
    candidate_code = sprintf("%s%02d", prefix, seq_along(chosen)),
    route = route,
    route_rank = seq_along(chosen),
    source_candidate_id = vapply(chosen, `[[`, character(1), "candidate_id"),
    stringsAsFactors = FALSE
  )
}

run_monitoring_design <- function() {
  require_package("data.table")
  candidates <- read_table(full_asset("monitoring_candidates"),
                           c("candidate_id", "x", "y", environmental_predictor_names()))
  support <- read_table(file.path(full_output_dir("09_prediction_support"), "prediction_support_by_cell.csv"))
  prediction <- read_table(file.path(full_output_dir("08_city_prediction"), "city_week_predictions.csv"))
  predictors <- environmental_predictor_names()
  training <- read_table(full_asset("training_predictors_250"))
  city <- read_table(full_asset("city_predictors_250"))
  classified <- classify_prediction_support(training, city)
  threshold <- attr(classified, "aoa_threshold")
  centre <- vapply(training[, ..predictors], mean, numeric(1), na.rm = TRUE)
  scale <- vapply(training[, ..predictors], stats::sd, numeric(1), na.rm = TRUE)
  scale[!is.finite(scale) | scale == 0] <- 1
  for (name in predictors) {
    candidates[[name]] <- (candidates[[name]] - centre[[name]]) / scale[[name]]
    support[[name]] <- (support[[name]] - centre[[name]]) / scale[[name]]
  }
  gaps <- support[support_class == "Monitoring Gaps"]
  coverage <- select_coverage_expansion(candidates, gaps, predictors, threshold)

  spring <- prediction[annual_week %in% 15:21,
                       .(uncertainty_width = mean(psi_cri_width)), by = cell_id]
  validation <- merge(candidates, spring, by.x = "candidate_id", by.y = "cell_id")
  validation <- select_prediction_validation(validation)
  sequence <- rbind(
    public_sequence(coverage, "Coverage Expansion", "L"),
    public_sequence(validation, "Prediction Validation", "V")
  )
  write_table(sequence, file.path(full_output_dir("11_monitoring_design"), "monitoring_sequences.csv"))
}
