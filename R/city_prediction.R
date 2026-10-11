prediction_design <- function(formula, data, coefficient_names) {
  x <- stats::model.matrix(formula, data = data)
  missing <- setdiff(coefficient_names, colnames(x))
  if (length(missing)) stop("Prediction matrix is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  x[, coefficient_names, drop = FALSE]
}

city_week_grid <- function(city, weeks = 1:52) {
  require_package("data.table")
  city <- data.table::as.data.table(city)
  grid <- city[rep(seq_len(nrow(city)), each = length(weeks))]
  grid[, annual_week := rep(weeks, times = nrow(city))]
  seasonal <- week_terms(grid$annual_week)
  grid[, `:=`(sin_week = seasonal$sin_week, cos_week = seasonal$cos_week)]
  grid[]
}

predict_host_surface <- function(fit, draw_index, formula, grid, centre, scale) {
  beta <- as.matrix(fit$beta.samples)[draw_index, , drop = FALSE]
  x <- prediction_design(formula, grid, colnames(beta))
  raw <- stats::plogis(drop(x %*% t(beta)))
  (raw - centre) / scale
}

run_city_prediction <- function(n_draws = 600L, n_exposure_draws = 300L) {
  require_package("data.table")
  city <- read_table(full_asset("city_predictors_250"), c("cell_id"))
  grid <- city_week_grid(city)
  host_models <- readRDS(file.path(full_output_dir("04_host_models"), "host_models.rds"))
  koel_models <- readRDS(file.path(full_output_dir("05_koel_models"), "koel_models.rds"))
  M <- length(koel_models$three_host)
  per_model <- ceiling(n_draws / M)
  predicted <- vector("list", M)

  for (m in seq_len(M)) {
    model_grid <- data.table::copy(grid)
    scaling <- koel_models$host_scaling[[m]]
    for (role in names(host_models)) {
      row <- scaling[scaling$host_group == role, , drop = FALSE]
      model_grid[[paste0(role, "_host_psi_z")]] <- predict_host_surface(
        host_models[[role]], row$draw_index, host_formulas()[[role]], model_grid,
        row$centre, row$scale
      )
    }
    beta <- as.matrix(koel_models$three_host[[m]]$beta.samples)
    keep <- unique(as.integer(round(seq(1, nrow(beta), length.out = min(per_model, nrow(beta))))))
    beta <- beta[keep, , drop = FALSE]
    x <- prediction_design(koel_three_host_formula(), model_grid, colnames(beta))
    predicted[[m]] <- stats::plogis(x %*% t(beta))
  }
  draws <- do.call(cbind, predicted)[, seq_len(min(n_draws, sum(vapply(predicted, ncol, integer(1))))), drop = FALSE]
  summary <- data.table::data.table(
    cell_id = grid$cell_id,
    annual_week = grid$annual_week,
    psi_mean = rowMeans(draws),
    psi_median = apply(draws, 1, stats::median),
    psi_q025 = apply(draws, 1, stats::quantile, 0.025),
    psi_q975 = apply(draws, 1, stats::quantile, 0.975)
  )
  summary[, psi_cri_width := psi_q975 - psi_q025]

  reference_path <- full_asset("reference_detection_density_draws", required = FALSE)
  if (!is.null(reference_path)) {
    reference <- read_table(reference_path, c("p", "mu_plus"))
    # Retain equal contributions from the three host imputations.
    draw_groups <- rep(seq_len(M), times = vapply(predicted, ncol, integer(1)))[seq_len(ncol(draws))]
    per_group <- max(1L, floor(n_exposure_draws / M))
    exposure_keep <- unlist(lapply(split(seq_len(ncol(draws)), draw_groups), function(g) {
      g[unique(as.integer(round(seq(1, length(g), length.out = min(per_group, length(g))))))]
    }), use.names = FALSE)
    index <- rep(seq_len(nrow(reference)), length.out = length(exposure_keep))
    exposure <- sweep(draws[, exposure_keep, drop = FALSE], 2, reference$p[index] * reference$mu_plus[index], "*")
    summary[, `:=`(
      exposure_mean = rowMeans(exposure),
      exposure_q025 = apply(exposure, 1, stats::quantile, 0.025),
      exposure_q975 = apply(exposure, 1, stats::quantile, 0.975)
    )]
  }

  out <- full_output_dir("08_city_prediction")
  write_table(summary, file.path(out, "city_week_predictions.csv"))
  saveRDS(draws, file.path(out, "city_week_psi_draws.rds"))
}
