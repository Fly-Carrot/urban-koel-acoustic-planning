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
  exposure_by_imputation <- vector("list", M)
  joint <- readRDS(file.path(full_output_dir("07_calling_density"), "joint_daily_posteriors.rds"))
  hourly <- readRDS(file.path(full_output_dir("07_calling_density"), "hourly_posterior.rds"))
  density_scaling <- as.data.frame(read_table(full_asset("host_density_scaling"),
                                             c("imputation", "host_group", "centre", "scale")))
  if (M != 3L || length(joint) != M) stop("City exposure requires the three matching host imputations.", call. = FALSE)

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
    equal_host_z <- annual_equal_scale_host(host_models, scaling, as.data.frame(model_grid), density_scaling, m)
    exposure_by_imputation[[m]] <- predict_modular_exposure(
      as.data.frame(model_grid), equal_host_z, joint[[m]], hourly,
      n_draws = max(1L, floor(n_exposure_draws / M)), imputation = m
    )
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

  sizes <- vapply(exposure_by_imputation, ncol, integer(1))
  if (length(unique(sizes)) != 1L) stop("Host imputations must contribute equal exposure draws.", call. = FALSE)
  exposure <- do.call(cbind, exposure_by_imputation)
  summary[, `:=`(
    exposure_mean = rowMeans(exposure),
    exposure_q025 = apply(exposure, 1, stats::quantile, 0.025),
    exposure_q975 = apply(exposure, 1, stats::quantile, 0.975)
  )]

  out <- full_output_dir("08_city_prediction")
  write_table(summary, file.path(out, "city_week_predictions.csv"))
  saveRDS(draws, file.path(out, "city_week_psi_draws.rds"))
  saveRDS(exposure, file.path(out, "city_week_exposure_draws.rds"))
}
