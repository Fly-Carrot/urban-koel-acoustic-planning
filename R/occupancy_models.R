primary_detection_formula <- function() {
  ~ log_effort_z + log1p_anthropogenic_rate_z + log1p_frog_rate_z + (1 | site_re)
}

koel_no_host_formula <- function() {
  ~ trees + built + dist_water_m_nearest + elevation + sin_week + cos_week
}

koel_three_host_formula <- function() {
  ~ trees + built + dist_water_m_nearest + elevation + sin_week + cos_week +
    corvid_host_psi_z + sturnid_host_psi_z + laughingthrush_host_psi_z
}

host_formulas <- function() {
  list(
    corvid = ~ trees + built + dist_water_m_nearest + elevation + sin_week + cos_week,
    sturnid = ~ grass + road_density + dist_water_m_nearest + elevation + sin_week + cos_week,
    laughingthrush = ~ tree_edge_area_50m + built + dist_water_m_nearest + elevation + sin_week + cos_week
  )
}

full_mcmc_settings <- function(profile = c("full_data", "detection", "validation")) {
  profile <- match.arg(profile)
  batches <- c(full_data = 600L, detection = 1000L, validation = 1200L)
  burn <- c(full_data = 10000L, detection = 20000L, validation = 20000L)
  list(
    n.batch = unname(batches[[profile]]),
    batch.length = 50L,
    n.burn = unname(burn[[profile]]),
    n.thin = 20L,
    n.chains = 4L
  )
}

flatten_tpg_covariates <- function(covariates, formula, y_dim, layer) {
  variables <- intersect(names(covariates), all.vars(formula))
  out <- lapply(covariates[variables], function(x) {
    d <- dim(x)
    if (layer == "occ") {
      if (length(d) == 2L) return(as.numeric(x))
      if (is.null(d) && length(x) == y_dim[[1]]) return(rep(as.numeric(x), times = y_dim[[2]]))
    } else {
      if (length(d) == 3L) return(as.numeric(x))
      if (length(d) == 2L) return(rep(as.numeric(x), times = y_dim[[3]]))
      if (is.null(d) && length(x) == y_dim[[1]]) {
        return(rep(as.numeric(x), times = y_dim[[2]] * y_dim[[3]]))
      }
    }
    as.numeric(x)
  })
  as.data.frame(out, check.names = FALSE)
}

tpg_design <- function(data, formula, layer) {
  require_package("reformulas")
  covariates <- if (layer == "occ") data$occ.covs else data$det.covs
  flat <- flatten_tpg_covariates(covariates, formula, dim(data$y), layer)
  fixed_formula <- reformulas::nobars(formula)
  stats::model.matrix(fixed_formula, data = flat)
}

fit_tpg_model <- function(data, occurrence_formula, detection_formula, seed,
                          verbose = TRUE, settings = full_mcmc_settings()) {
  require_package("spOccupancy")
  x_occ <- tpg_design(data, occurrence_formula, "occ")
  x_det <- tpg_design(data, detection_formula, "det")
  z_init <- apply(data$y, c(1, 2), function(x) as.integer(any(x == 1L, na.rm = TRUE)))
  set.seed(seed)
  spOccupancy::tPGOcc(
    occ.formula = occurrence_formula,
    det.formula = detection_formula,
    data = data,
    inits = list(
      beta = rep(0, ncol(x_occ)),
      alpha = rep(0, ncol(x_det)),
      z = z_init,
      sigma.sq.p = 1
    ),
    priors = list(
      beta.normal = list(0, 2.25),
      alpha.normal = list(0, 2.25),
      sigma.sq.p.ig = list(2, 1)
    ),
    tuning = list(),
    n.batch = settings$n.batch,
    batch.length = settings$batch.length,
    n.burn = settings$n.burn,
    n.thin = settings$n.thin,
    n.chains = settings$n.chains,
    n.report = 100L,
    n.omp.threads = 1L,
    verbose = verbose,
    ar1 = FALSE
  )
}

occupancy_diagnostics <- function(fit) {
  rhat <- as.numeric(unlist(fit$rhat, use.names = FALSE))
  ess <- as.numeric(unlist(if (!is.null(fit$ESS)) fit$ESS else fit$ess, use.names = FALSE))
  rhat <- rhat[is.finite(rhat)]
  ess <- ess[is.finite(ess)]
  data.frame(
    max_rhat = if (length(rhat)) max(rhat) else NA_real_,
    min_ess = if (length(ess)) min(ess) else NA_real_
  )
}

psis_summary <- function(fit, data, model_id) {
  require_package("loo")
  valid_week <- apply(!is.na(data$y), c(1, 2), any)
  index <- which(as.vector(valid_week))
  likelihood <- matrix(fit$like.samples, nrow = dim(fit$like.samples)[1])[, index, drop = FALSE]
  log_lik <- log(pmax(likelihood, .Machine$double.xmin))
  chain <- rep(seq_len(fit$n.chains), each = nrow(log_lik) / fit$n.chains)
  result <- loo::loo(log_lik, r_eff = loo::relative_eff(exp(log_lik), chain_id = chain))
  data.frame(
    model_id = model_id,
    elpd_loo = result$estimates["elpd_loo", "Estimate"],
    se = result$estimates["elpd_loo", "SE"],
    pareto_k_over_0_7 = sum(loo::pareto_k_values(result) > 0.7),
    pareto_k_over_1 = sum(loo::pareto_k_values(result) > 1)
  )
}

read_model_inputs <- function(response_group) {
  daily <- read_table(
    file.path(full_output_dir("01_survey_histories"), "daily_survey_histories.csv"),
    c("station_id", "study_week", "survey_day", "species_group", "detected")
  )
  weekly <- read_table(full_asset("weekly_covariates"), c("station_id", "study_week"))
  detection <- read_table(
    full_asset("daily_detection_covariates"),
    c("station_id", "study_week", "survey_day", "log1p_anthropogenic_rate_z", "log1p_frog_rate_z")
  )
  make_tpg_data(daily, weekly, detection, response_group)
}

run_detection_models <- function() {
  data <- read_model_inputs("koel")
  occ_formula <- koel_no_host_formula()
  candidates <- list(
    effort_only = ~ log_effort_z + (1 | site_re),
    acoustic_context = primary_detection_formula()
  )
  out <- full_output_dir("02_detection")
  scores <- list()
  for (i in seq_along(candidates)) {
    model_id <- names(candidates)[[i]]
    fit <- fit_tpg_model(data, occ_formula, candidates[[i]], 2026081400L + i,
                         settings = full_mcmc_settings("detection"))
    saveRDS(fit, file.path(out, paste0(model_id, ".rds")))
    scores[[i]] <- cbind(
      psis_summary(fit, data, model_id),
      occupancy_diagnostics(fit)
    )
  }
  write_table(do.call(rbind, scores), file.path(out, "detection_model_comparison.csv"))
}

run_host_models <- function() {
  formulas <- host_formulas()
  response_names <- c(
    corvid = "corvid",
    sturnid = "sturnid",
    laughingthrush = "laughingthrush"
  )
  out <- full_output_dir("04_host_models")
  fits <- list()
  summaries <- list()
  for (i in seq_along(formulas)) {
    role <- names(formulas)[[i]]
    data <- read_model_inputs(response_names[[role]])
    # The retained sturnid refit used the longer profile.
    profile <- if (role == "sturnid") "validation" else "full_data"
    fit <- fit_tpg_model(data, formulas[[role]], primary_detection_formula(), 2026081500L + i,
                         settings = full_mcmc_settings(profile))
    fits[[role]] <- fit
    saveRDS(fit, file.path(out, paste0(role, ".rds")))
    summaries[[role]] <- cbind(
      fit_summary(fit$beta.samples, "weekly_host_opportunity", role),
      occupancy_diagnostics(fit)
    )
  }
  saveRDS(fits, file.path(out, "host_models.rds"))
  write_table(do.call(rbind, summaries), file.path(out, "host_model_effects.csv"))
}

chain_stratified_host_draws <- function(host_fits, M = 3L, seed = 2026081600L) {
  schedule <- data.frame(imputation = seq_len(M))
  for (i in seq_along(host_fits)) {
    role <- names(host_fits)[[i]]
    fit <- host_fits[[role]]
    n_draw <- dim(fit$psi.samples)[1]
    n_chain <- as.integer(fit$n.chains)
    if (!is.finite(n_chain) || n_chain < M || n_draw %% n_chain != 0L || n_draw / n_chain < M) {
      stop("Host posterior cannot support three chain-stratified draws: ", role, call. = FALSE)
    }
    per_chain <- n_draw %/% n_chain
    set.seed(seed + 100L * i)
    chain <- sample.int(n_chain, M, replace = FALSE)
    within_chain <- sample.int(per_chain, M, replace = FALSE)
    schedule[[paste0(role, "_draw")]] <- (chain - 1L) * per_chain + within_chain
    schedule[[paste0(role, "_chain")]] <- chain
  }
  schedule
}

host_draw_surface <- function(fit, draw_index, train_sites = NULL,
                              reference_mask = NULL, return_scaling = FALSE) {
  psi_dim <- dim(fit$psi.samples)
  surface <- matrix(
    fit$psi.samples[draw_index, , ],
    nrow = psi_dim[[2]], ncol = psi_dim[[3]]
  )
  use <- surface
  if (!is.null(train_sites)) use <- surface[train_sites, , drop = FALSE]
  reference <- if (is.null(reference_mask)) as.numeric(use) else use[reference_mask]
  centre <- mean(reference, na.rm = TRUE)
  scale <- stats::sd(reference, na.rm = TRUE)
  if (!is.finite(scale) || scale <= 0) stop("A host posterior surface is constant.", call. = FALSE)
  standardised <- (surface - centre) / scale
  if (return_scaling) {
    return(list(values = standardised, centre = centre, scale = scale, draw_index = draw_index))
  }
  standardised
}

run_koel_models <- function(M = 3L) {
  data <- read_model_inputs("koel")
  host_fits <- readRDS(file.path(full_output_dir("04_host_models"), "host_models.rds"))
  draw_schedule <- chain_stratified_host_draws(host_fits, M)
  valid_siteweek <- apply(!is.na(data$y), c(1, 2), any)

  out <- full_output_dir("05_koel_models")
  h0 <- fit_tpg_model(data, koel_no_host_formula(), primary_detection_formula(), 2026081600L)
  saveRDS(h0, file.path(out, "no_host_transfer_model.rds"))
  h4_fits <- vector("list", M)
  host_scaling <- vector("list", M)
  summaries <- list(fit_summary(h0$beta.samples, "weekly_koel_opportunity", "no_host"))

  for (m in seq_len(M)) {
    model_data <- data
    scaling_rows <- list()
    for (role in names(host_fits)) {
      draw_index <- draw_schedule[[paste0(role, "_draw")]][[m]]
      info <- host_draw_surface(
        host_fits[[role]], draw_index,
        reference_mask = valid_siteweek,
        return_scaling = TRUE
      )
      model_data$occ.covs[[paste0(role, "_host_psi_z")]] <- info$values
      scaling_rows[[role]] <- data.frame(
        host_group = role, draw_index = info$draw_index,
        centre = info$centre, scale = info$scale,
        stringsAsFactors = FALSE
      )
    }
    host_scaling[[m]] <- do.call(rbind, scaling_rows)
    h4_fits[[m]] <- fit_tpg_model(
      model_data,
      koel_three_host_formula(),
      primary_detection_formula(),
      2026081600L + m
    )
    saveRDS(h4_fits[[m]], file.path(out, sprintf("three_host_imputation_%02d.rds", m)))
    summaries[[m + 1L]] <- fit_summary(
      h4_fits[[m]]$beta.samples,
      "weekly_koel_opportunity",
      sprintf("three_host_M%02d", m)
    )
  }
  saveRDS(list(no_host = h0, three_host = h4_fits, host_draw_schedule = draw_schedule,
               host_scaling = host_scaling),
          file.path(out, "koel_models.rds"))
  write_table(do.call(rbind, summaries), file.path(out, "koel_model_effects.csv"))
}
