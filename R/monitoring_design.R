# Two monitoring routes. Candidate conflicts replace precise coordinates.
prospective_gain <- function(candidate_x, target_x, lower, upper, current_di, dmax) {
  p <- ncol(candidate_x)
  d2 <- (outer(rowSums(candidate_x^2), rowSums(target_x^2), "+") - 2 * tcrossprod(candidate_x, target_x)) / p
  new_d2 <- pmin(pmax(d2, 0), matrix(current_di^2, nrow(candidate_x), nrow(target_x), byrow = TRUE))
  outside <- matrix(0L, nrow(candidate_x), nrow(target_x))
  for (j in seq_len(p)) {
    outside <- outside + outer(pmin(lower[j], candidate_x[, j]), target_x[, j], function(a,b) b < a) +
      outer(pmax(upper[j], candidate_x[, j]), target_x[, j], function(a,b) b > a)
  }
  outside <= 1L & new_d2 <= dmax^2
}

remove_nearby <- function(remaining, winner, conflicts) {
  blocked <- c(winner, conflicts$cell_b[conflicts$cell_a == winner], conflicts$cell_a[conflicts$cell_b == winner])
  setdiff(remaining, blocked)
}

rank_monitoring <- function(training, city, candidates, conflicts, minimum_spacing, n = 15L) {
  require_package("data.table")
  predictors <- environmental_predictor_names()
  training <- as.data.frame(training); city <- as.data.frame(city); candidates <- as.data.frame(candidates)
  stopifnot(!anyDuplicated(candidates$cell_id), !anyDuplicated(city$cell_id))
  support <- as.data.frame(classify_prediction_support(training, city))
  centre <- vapply(training[predictors], mean, numeric(1)); scale <- vapply(training[predictors], stats::sd, numeric(1))
  train_z <- sweep(sweep(as.matrix(training[predictors]), 2, centre, "-"), 2, scale, "/")
  z <- sweep(sweep(as.matrix(city[predictors]), 2, centre, "-"), 2, scale, "/")
  dmax <- aoa_threshold(train_z)[["maximum"]]
  candidates <- merge(candidates, support[c("cell_id", "pid", "support_class")], by = "cell_id", all.x = TRUE)
  finite <- apply(z, 1, function(x) all(is.finite(x)))
  candidates$finite <- finite[match(candidates$cell_id, city$cell_id)]
  allowed <- candidates$pid %in% c("PASS", "UNCERTAIN") & candidates$finite & !candidates$existing_site &
    candidates$nearest_existing_site_m >= minimum_spacing
  candidates <- candidates[which(allowed), , drop = FALSE]
  coverage_pool <- candidates[candidates$support_class == "Monitoring Gaps", , drop = FALSE]
  validation_pool <- candidates[candidates$support_class %in% c("Primary Results", "Moderate Extrapolation") &
                                  is.finite(candidates$uncertainty_width), , drop = FALSE]
  original_gaps <- which(support$support_class == "Monitoring Gaps" & finite)
  uncovered <- original_gaps; remaining <- coverage_pool$cell_id
  lower <- apply(train_z, 2, min); upper <- apply(train_z, 2, max); di <- nearest_distance(z, train_z)
  coverage <- list()
  for (rank in seq_len(n)) {
    if (!length(remaining) || !length(uncovered)) break
    score <- numeric(length(remaining)); index <- match(remaining, city$cell_id)
    for (start in seq(1L, length(index), by = 96L)) {
      rows <- start:min(start + 95L, length(index))
      score[rows] <- rowSums(prospective_gain(z[index[rows], , drop = FALSE], z[uncovered, , drop = FALSE],
                                             lower, upper, di[uncovered], dmax))
    }
    meta <- coverage_pool[match(remaining, coverage_pool$cell_id), , drop = FALSE]
    order <- order(-score, -meta$planning_context, -meta$nearest_existing_site_m, meta$cell_id)
    win <- order[1]; winner <- remaining[win]; wi <- index[win]
    if (score[win] <= 0) break
    newly <- uncovered[as.vector(prospective_gain(z[wi, , drop = FALSE], z[uncovered, , drop = FALSE],
                                                 lower, upper, di[uncovered], dmax))]
    lower <- pmin(lower, z[wi, ]); upper <- pmax(upper, z[wi, ])
    di <- pmin(di, nearest_distance(z, z[wi, , drop = FALSE])); uncovered <- setdiff(uncovered, newly)
    coverage[[rank]] <- data.frame(cell_id=winner, route="Coverage Expansion", route_rank=rank,
                                   marginal_gain=length(newly), cumulative_gain=length(original_gaps)-length(uncovered),
                                   uncertainty_width=meta$uncertainty_width[win])
    remaining <- remove_nearby(remaining, winner, conflicts)
  }
  remaining <- validation_pool$cell_id; validation <- list()
  for (rank in seq_len(n)) {
    if (!length(remaining)) break
    meta <- validation_pool[match(remaining, validation_pool$cell_id), , drop = FALSE]
    order <- order(-meta$uncertainty_width, -meta$planning_context, -meta$nearest_existing_site_m, meta$cell_id)
    win <- order[1]; winner <- remaining[win]
    validation[[rank]] <- data.frame(cell_id=winner, route="Prediction Validation", route_rank=rank,
                                     marginal_gain=NA_integer_, cumulative_gain=NA_integer_, uncertainty_width=meta$uncertainty_width[win])
    remaining <- remove_nearby(remaining, winner, conflicts)
  }
  list(sequence=do.call(rbind, c(coverage, validation)),
       eligible_counts=c(coverage=nrow(coverage_pool), validation=nrow(validation_pool)),
       total_gaps=length(original_gaps), minimum_spacing=minimum_spacing)
}

deployment_portfolios <- function(result, sizes = c(5L, 10L, 15L)) {
  share <- result$eligible_counts[["coverage"]] / sum(result$eligible_counts)
  do.call(rbind, lapply(sizes, function(size) {
    nL <- max(1L, min(size-1L, as.integer(round(size*share))))
    s <- result$sequence
    rows <- (s$route == "Coverage Expansion" & s$route_rank <= nL) | (s$route == "Prediction Validation" & s$route_rank <= size-nL)
    data.frame(deployment_size=size, s[rows, , drop=FALSE])
  }))
}

run_monitoring_design <- function() {
  settings <- read_table(input_file("monitoring_settings"), c("parameter", "value"))
  result <- rank_monitoring(read_table(input_file("training_predictors_250")), read_table(input_file("city_predictors_250")),
                            read_table(input_file("monitoring_candidates")), read_table(input_file("spacing_conflicts")),
                            settings$value[settings$parameter == "minimum_spacing_m"])
  out <- full_output_dir("11_monitoring_design")
  write_table(result$sequence, file.path(out, "monitoring_sequences.csv"))
  write_table(deployment_portfolios(result), file.path(out, "deployment_portfolios.csv"))
}
