# HEQZ supplies host and annual effects; D1 supplies hour effects and dispersion.
posterior_rows <- function(n, requested) {
  unique(as.integer(round(seq(1, n, length.out = min(n, requested)))))
}

stan_coefficients <- function(draws, stem, n) {
  columns <- paste0(stem, "[", seq_len(n), "]")
  if (!all(columns %in% colnames(draws))) stop("Missing posterior coefficients: ", stem, call. = FALSE)
  draws[, columns, drop = FALSE]
}

annual_equal_scale_host <- function(host_models, host_draw_scaling, grid, density_scaling, imputation) {
  city <- grid[!duplicated(grid$cell_id), , drop = FALSE]
  day <- 1:365
  annual_z <- lapply(names(host_models), function(role) {
    schedule <- host_draw_scaling[host_draw_scaling$host_group == role, , drop = FALSE]
    beta <- as.matrix(host_models[[role]]$beta.samples)[schedule$draw_index, ]
    x <- prediction_design(host_formulas()[[role]], city, names(beta))
    seasonal <- c("sin_week", "cos_week")
    static <- setdiff(names(beta), seasonal)
    eta <- drop(x[, static, drop = FALSE] %*% beta[static])
    offset <- beta["sin_week"] * sin(2 * pi * (day - 1) / 365.2425) +
      beta["cos_week"] * cos(2 * pi * (day - 1) / 365.2425)
    annual_mean <- rowMeans(stats::plogis(outer(eta, offset, "+")))
    scale_row <- density_scaling[density_scaling$imputation == imputation & density_scaling$host_group == role, ]
    if (nrow(scale_row) != 1L || !is.finite(scale_row$scale) || scale_row$scale <= 0) {
      stop("Missing retained annual host scaling for ", role, call. = FALSE)
    }
    (annual_mean - scale_row$centre) / scale_row$scale
  })
  equal <- density_scaling[density_scaling$imputation == imputation & density_scaling$host_group == "equal_scale", ]
  if (nrow(equal) != 1L || !is.finite(equal$scale) || equal$scale <= 0) {
    stop("Missing retained equal-scale index scaling.", call. = FALSE)
  }
  index <- (Reduce("+", annual_z) / length(annual_z) - equal$centre) / equal$scale
  index[match(grid$cell_id, city$cell_id)]
}

conditional_hour_fraction <- function(eta, phi, samples_per_hour = 6L) {
  mu <- stats::plogis(pmax(-30, pmin(30, eta)))
  dim(mu) <- dim(eta)
  log_p0 <- lbeta(mu * phi, samples_per_hour + (1 - mu) * phi) -
    lbeta(mu * phi, (1 - mu) * phi)
  dim(log_p0) <- dim(eta)
  positive_day <- -expm1(rowSums(log_p0))
  pmin(1, rowMeans(mu / pmax(positive_day, 1e-12)))
}

predict_modular_exposure <- function(grid, equal_host_z, joint, hourly, n_draws = 100L,
                                     imputation = 1L, chunk_size = 200L) {
  joint_draws <- joint$draws[posterior_rows(nrow(joint$draws), n_draws), , drop = FALSE]
  hourly_draws <- hourly$draws[posterior_rows(nrow(hourly$draws), nrow(joint_draws)), , drop = FALSE]
  if (nrow(hourly_draws) != nrow(joint_draws)) stop("Insufficient matched hourly draws.", call. = FALSE)
  beta <- stan_coefficients(joint_draws, "beta_occ", length(joint$occurrence_names))
  alpha <- stan_coefficients(joint_draws, "alpha_det", length(joint$detection_names))
  gamma <- stan_coefficients(joint_draws, "gamma_int", 4L)
  hourly_beta <- stan_coefficients(hourly_draws, "beta", length(hourly$design_names))
  hour_terms <- c("sin_hour_1", "cos_hour_1", "sin_hour_2", "cos_hour_2")
  if (!all(hour_terms %in% hourly$design_names)) stop("Hourly posterior must use the retained D1 basis.", call. = FALSE)
  hour_beta <- hourly_beta[, match(hour_terms, hourly$design_names), drop = FALSE]
  theta <- 2 * pi * ((0:23) + 0.5) / 24
  hour_basis <- cbind(sin(theta), cos(theta), sin(2 * theta), cos(2 * theta))
  x <- prediction_design(koel_three_host_formula(), grid, joint$occurrence_names)
  p_ref <- stats::plogis(drop(alpha %*% joint$x_det_reference))
  n <- nrow(joint_draws)
  set.seed(475027L + 100L + imputation)
  day_quantiles <- sample(stats::qnorm((seq_len(n) - 0.5) / n), replace = FALSE)
  exposure <- matrix(NA_real_, nrow(grid), n)
  # Keep opportunity, detection and daily density from the same posterior row.
  for (start in seq(1L, nrow(grid), by = chunk_size)) {
    rows <- start:min(nrow(grid), start + chunk_size - 1L)
    psi <- stats::plogis(x[rows, , drop = FALSE] %*% t(beta))
    for (d in seq_len(n)) {
      eta_base <- gamma[d, 1] + gamma[d, 2] * equal_host_z[rows] +
        gamma[d, 3] * grid$sin_week[rows] + gamma[d, 4] * grid$cos_week[rows] +
        hourly_draws[d, "sigma_day"] * day_quantiles[d]
      eta <- outer(eta_base, drop(hour_basis %*% hour_beta[d, ]), "+")
      cplus <- conditional_hour_fraction(eta, exp(hourly_draws[d, "log_phi"]))
      exposure[rows, d] <- psi[, d] * p_ref[d] * cplus
    }
  }
  check_probability(exposure, "Sampled-minute exposure")
  exposure
}
