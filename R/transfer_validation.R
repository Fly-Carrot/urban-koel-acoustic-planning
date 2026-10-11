subset_tpg_data <- function(data, site_index) {
  n_week <- dim(data$y)[2]
  n_day <- dim(data$y)[3]
  subset_covariates <- function(covariates) {
    lapply(covariates, function(x) {
      d <- dim(x)
      if (length(d) == 3L && d[1] == dim(data$y)[1]) return(x[site_index, , , drop = FALSE])
      if (length(d) == 2L && d[1] == dim(data$y)[1]) return(x[site_index, , drop = FALSE])
      if (is.null(d) && length(x) == dim(data$y)[1]) return(x[site_index])
      x
    })
  }
  out <- list(
    y = data$y[site_index, , , drop = FALSE],
    occ.covs = subset_covariates(data$occ.covs),
    det.covs = subset_covariates(data$det.covs)
  )
  out$det.covs$site_re <- array(
    rep(seq_along(site_index), times = n_week * n_day),
    dim = dim(out$y)
  )
  out
}

scale_fold_covariates <- function(train, test, occurrence_terms, detection_terms) {
  rows <- list()
  occurrence_terms <- setdiff(occurrence_terms, c("sin_week", "cos_week"))
  for (name in occurrence_terms) {
    if (!name %in% names(train$occ.covs)) next
    x <- train$occ.covs[[name]]
    centre <- mean(x, na.rm = TRUE)
    scale <- stats::sd(x, na.rm = TRUE)
    if (!is.finite(scale) || scale <= 0) scale <- 1
    train$occ.covs[[name]] <- (x - centre) / scale
    test$occ.covs[[name]] <- (test$occ.covs[[name]] - centre) / scale
    rows[[length(rows) + 1L]] <- data.frame(layer = "occurrence", variable = name, centre, scale)
  }
  for (name in detection_terms) {
    if (!name %in% names(train$det.covs)) next
    x <- train$det.covs[[name]]
    centre <- mean(x, na.rm = TRUE)
    scale <- stats::sd(x, na.rm = TRUE)
    if (!is.finite(scale) || scale <= 0) scale <- 1
    train$det.covs[[name]] <- (x - centre) / scale
    test$det.covs[[name]] <- (test$det.covs[[name]] - centre) / scale
    rows[[length(rows) + 1L]] <- data.frame(layer = "detection", variable = name, centre, scale)
  }
  list(train = train, test = test, scaling = do.call(rbind, rows))
}

score_heldout_history <- function(fit, test, occurrence_formula, detection_formula,
                                  posterior_draws = 500L, random_effect_draws = 50L,
                                  seed = 1L) {
  x_occ <- tpg_design(test, occurrence_formula, "occ")
  x_det_all <- tpg_design(test, detection_formula, "det")
  y <- test$y
  observed <- which(!is.na(as.numeric(y)))
  array_index <- arrayInd(observed, dim(y))
  site_week <- array_index[, 1] + (array_index[, 2] - 1L) * dim(y)[1]
  y_observed <- as.numeric(y)[observed]
  x_det <- x_det_all[observed, , drop = FALSE]

  beta_all <- as.matrix(fit$beta.samples)
  alpha_all <- as.matrix(fit$alpha.samples)
  sigma_all <- sqrt(pmax(as.numeric(fit$sigma.sq.p.samples), 1e-10))
  n_available <- min(nrow(beta_all), nrow(alpha_all), length(sigma_all))
  keep <- unique(as.integer(round(seq(1, n_available, length.out = min(posterior_draws, n_available)))))
  beta <- beta_all[keep, colnames(x_occ), drop = FALSE]
  alpha <- alpha_all[keep, colnames(x_det), drop = FALSE]
  sigma <- sigma_all[keep]
  beta <- beta[rep(seq_len(nrow(beta)), each = random_effect_draws), , drop = FALSE]
  alpha <- alpha[rep(seq_len(nrow(alpha)), each = random_effect_draws), , drop = FALSE]
  sigma <- rep(sigma, each = random_effect_draws)

  set.seed(seed)
  site_effect <- matrix(
    stats::rnorm(nrow(beta) * dim(y)[1], 0, rep(sigma, times = dim(y)[1])),
    nrow = nrow(beta), ncol = dim(y)[1]
  )
  psi <- stats::plogis(x_occ %*% t(beta))
  eta_p <- x_det %*% t(alpha)
  for (site in seq_len(dim(y)[1])) {
    row <- array_index[, 1] == site
    eta_p[row, ] <- sweep(eta_p[row, , drop = FALSE], 2, site_effect[, site], "+")
  }
  p <- stats::plogis(eta_p)

  valid_week <- apply(!is.na(y), c(1, 2), any)
  output <- vector("list", sum(valid_week))
  counter <- 0L
  for (key in which(as.vector(valid_week))) {
    counter <- counter + 1L
    rows <- which(site_week == key)
    observed_y <- y_observed[rows]
    p_draw <- pmin(pmax(p[rows, , drop = FALSE], 1e-12), 1 - 1e-12)
    psi_draw <- pmin(pmax(psi[key, ], 1e-12), 1 - 1e-12)
    log_no_detection <- colSums(log1p(-p_draw))
    probability_any <- psi_draw * (1 - exp(log_no_detection))
    if (any(observed_y == 1L)) {
      log_likelihood <- log(psi_draw) + colSums(
        sweep(log(p_draw), 1, observed_y, "*") +
          sweep(log1p(-p_draw), 1, 1 - observed_y, "*")
      )
    } else {
      log_likelihood <- log((1 - psi_draw) + psi_draw * exp(log_no_detection))
    }
    site <- ((key - 1L) %% dim(y)[1]) + 1L
    week <- ((key - 1L) %/% dim(y)[1]) + 1L
    output[[counter]] <- data.frame(
      station_id = dimnames(y)[[1]][site],
      study_week = dimnames(y)[[2]][week],
      observed_any = as.integer(any(observed_y == 1L)),
      predicted_any = mean(probability_any),
      log_predictive_density = log_mean_exp(log_likelihood)
    )
  }
  do.call(rbind, output)
}

summarise_heldout_scores <- function(scores) {
  scores <- data.frame(scores)
  data.frame(
    n_site_weeks = nrow(scores),
    heldout_elpd = sum(scores$log_predictive_density),
    brier = mean((scores$observed_any - scores$predicted_any)^2),
    calibration_intercept = unname(stats::coef(stats::glm(
      observed_any ~ 1,
      offset = stats::qlogis(pmin(pmax(predicted_any, 1e-6), 1 - 1e-6)),
      family = stats::binomial(),
      data = scores
    ))[[1]])
  )
}

run_transfer_validation <- function(M = 3L) {
  folds <- read_table(full_asset("fold_registry"), c("station_id", "fold_id"))
  scales <- c(100L, 250L, 500L)
  result_rows <- list()
  point_rows <- list()
  scaling_rows <- list()

  for (scale_m in scales) {
    weekly_asset <- paste0("weekly_covariates_", scale_m)
    weekly_path <- full_asset(weekly_asset)
    for (fold_id in sort(unique(folds$fold_id))) {
      daily <- read_table(file.path(full_output_dir("01_survey_histories"), "daily_survey_histories.csv"))
      weekly <- read_table(weekly_path, c("station_id", "study_week"))
      detection <- read_table(full_asset("daily_detection_covariates"))
      all_data <- make_tpg_data(daily, weekly, detection, "koel")
      sites <- dimnames(all_data$y)[[1]]
      test_sites <- folds$station_id[folds$fold_id == fold_id]
      test_index <- match(test_sites, sites)
      test_index <- test_index[!is.na(test_index)]
      train_index <- setdiff(seq_along(sites), test_index)
      train <- subset_tpg_data(all_data, train_index)
      test <- subset_tpg_data(all_data, test_index)

      scaled <- scale_fold_covariates(
        train, test,
        formula_terms(koel_no_host_formula()),
        formula_terms(primary_detection_formula())
      )
      train <- scaled$train
      test <- scaled$test
      scaled$scaling$scale_m <- scale_m
      scaled$scaling$fold_id <- fold_id
      scaling_rows[[length(scaling_rows) + 1L]] <- scaled$scaling

      h0 <- fit_tpg_model(
        train, koel_no_host_formula(), primary_detection_formula(),
        2026082000L + scale_m * 10L + fold_id,
        verbose = FALSE, settings = full_mcmc_settings("validation")
      )
      h0_scores <- score_heldout_history(
        h0, test, koel_no_host_formula(), primary_detection_formula(),
        seed = 2026082100L + scale_m * 10L + fold_id
      )
      h0_scores$model_id <- "no_host"
      h0_scores$scale_m <- scale_m
      h0_scores$fold_id <- fold_id
      h0_scores$imputation <- 0L
      point_rows[[length(point_rows) + 1L]] <- h0_scores
      h0_summary <- summarise_heldout_scores(h0_scores)
      h0_summary$model_id <- "no_host"
      h0_summary$scale_m <- scale_m
      h0_summary$fold_id <- fold_id
      result_rows[[length(result_rows) + 1L]] <- h0_summary

      # Host models are refitted inside every training fold. Their posterior
      # surfaces are then propagated through M Koel refits.
      host_fits <- list()
      host_test_data <- list()
      host_train_data <- list()
      for (role in names(host_formulas())) {
        host_all <- make_tpg_data(daily, weekly, detection, role)
        host_train <- subset_tpg_data(host_all, train_index)
        host_test <- subset_tpg_data(host_all, test_index)
        host_scaled <- scale_fold_covariates(
          host_train, host_test,
          formula_terms(host_formulas()[[role]]),
          formula_terms(primary_detection_formula())
        )
        host_train <- host_scaled$train
        host_test <- host_scaled$test
        host_train_data[[role]] <- host_train
        host_test_data[[role]] <- host_test
        host_fits[[role]] <- fit_tpg_model(
          host_train, host_formulas()[[role]], primary_detection_formula(),
          2026082200L + scale_m * 100L + fold_id * 10L + match(role, names(host_formulas())),
          verbose = FALSE, settings = full_mcmc_settings("validation")
        )
      }
      draw_schedule <- chain_stratified_host_draws(
        host_fits, M,
        seed = 2026082250L + scale_m * 100L + fold_id * 10L
      )
      valid_train <- apply(!is.na(train$y), c(1, 2), any)
      for (m in seq_len(M)) {
        train_m <- train
        test_m <- test
        for (role in names(host_fits)) {
          draw_index <- draw_schedule[[paste0(role, "_draw")]][[m]]
          beta <- as.matrix(host_fits[[role]]$beta.samples)[draw_index, ]
          x_train <- tpg_design(host_train_data[[role]], host_formulas()[[role]], "occ")
          x_test <- tpg_design(host_test_data[[role]], host_formulas()[[role]], "occ")
          raw_train <- matrix(
            stats::plogis(x_train[, names(beta), drop = FALSE] %*% beta),
            nrow = length(train_index), ncol = dim(train$y)[2]
          )
          raw_test <- matrix(
            stats::plogis(x_test[, names(beta), drop = FALSE] %*% beta),
            nrow = length(test_index), ncol = dim(test$y)[2]
          )
          centre <- mean(raw_train[valid_train])
          scale <- stats::sd(raw_train[valid_train])
          if (!is.finite(scale) || scale <= 0) stop("A host prediction surface is constant.", call. = FALSE)
          train_m$occ.covs[[paste0(role, "_host_psi_z")]] <- (raw_train - centre) / scale
          test_m$occ.covs[[paste0(role, "_host_psi_z")]] <- (raw_test - centre) / scale
        }
        h4 <- fit_tpg_model(
          train_m, koel_three_host_formula(), primary_detection_formula(),
          2026082300L + scale_m * 100L + fold_id * 10L + m,
          verbose = FALSE, settings = full_mcmc_settings("validation")
        )
        scores <- score_heldout_history(
          h4, test_m, koel_three_host_formula(), primary_detection_formula(),
          seed = 2026082400L + scale_m * 100L + fold_id * 10L + m
        )
        scores$model_id <- "three_host"
        scores$imputation <- m
        scores$scale_m <- scale_m
        scores$fold_id <- fold_id
        point_rows[[length(point_rows) + 1L]] <- scores
      }
    }
  }

  points <- do.call(rbind, point_rows)
  pooled <- aggregate(
    cbind(predicted_any, log_predictive_density) ~ station_id + study_week + model_id + scale_m + fold_id,
    data = points,
    FUN = mean
  )
  observed <- unique(points[, c("station_id", "study_week", "observed_any", "model_id", "scale_m", "fold_id")])
  pooled <- merge(pooled, observed, by = c("station_id", "study_week", "model_id", "scale_m", "fold_id"))
  metrics <- do.call(rbind, lapply(split(pooled, list(pooled$scale_m, pooled$fold_id, pooled$model_id)), function(x) {
    out <- summarise_heldout_scores(x)
    out$scale_m <- x$scale_m[[1]]
    out$fold_id <- x$fold_id[[1]]
    out$model_id <- x$model_id[[1]]
    out
  }))
  out <- full_output_dir("06_transfer_validation")
  write_table(pooled, file.path(out, "heldout_predictions.csv"))
  write_table(metrics, file.path(out, "heldout_metrics.csv"))
  write_table(do.call(rbind, scaling_rows), file.path(out, "fold_scaling.csv"))
}
