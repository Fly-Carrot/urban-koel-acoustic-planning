# Fit daily HEQZ and hourly D1 models from positive-minute counts.

strip_random_effects <- function(formula) {
  require_package("reformulas")
  reformulas::nobars(formula)
}

build_joint_stan_data <- function(daily) {
  require_package("data.table")
  daily <- data.table::as.data.table(daily)
  needed <- c(
    "station_id", "date", "study_week", "positive_minutes", "usable_minutes",
    "trees", "built", "dist_water_m_nearest", "elevation",
    "sin_week", "cos_week", "corvid_host_psi_z", "sturnid_host_psi_z",
    "laughingthrush_host_psi_z", "log_effort_z",
    "log1p_anthropogenic_rate_z", "log1p_frog_rate_z",
    "equal_scale_host_index_z", "reference_log_effort_z"
  )
  missing <- setdiff(needed, names(daily))
  if (length(missing)) stop("The joint-model table is missing: ", paste(missing, collapse = ", "), call. = FALSE)

  daily <- daily[is.finite(usable_minutes) & usable_minutes > 0]
  daily[, detected := as.integer(positive_minutes > 0)]
  data.table::setorder(daily, station_id, study_week, date)
  daily[, group_id := .GRP, by = .(station_id, study_week)]
  daily[, site_id := match(station_id, unique(station_id))]

  group <- daily[, .(
    start_day = .I[1],
    end_day = .I[.N],
    any_positive = as.integer(any(detected == 1L)),
    trees = trees[1],
    built = built[1],
    dist_water_m_nearest = dist_water_m_nearest[1],
    elevation = elevation[1],
    sin_week = sin_week[1],
    cos_week = cos_week[1],
    corvid_host_psi_z = corvid_host_psi_z[1],
    sturnid_host_psi_z = sturnid_host_psi_z[1],
    laughingthrush_host_psi_z = laughingthrush_host_psi_z[1]
  ), by = group_id]

  x_occ <- stats::model.matrix(koel_three_host_formula(), data = group)
  x_det <- stats::model.matrix(strip_random_effects(primary_detection_formula()), data = daily)
  x_int <- stats::model.matrix(
    ~ equal_scale_host_index_z + sin_week + cos_week,
    data = daily
  )
  reference <- rep(0, ncol(x_det))
  names(reference) <- colnames(x_det)
  reference["(Intercept)"] <- 1
  effort_reference <- unique(daily$reference_log_effort_z)
  if (length(effort_reference) != 1L || !is.finite(effort_reference)) {
    stop("Provide the retained standardized 144-minute reference effort.", call. = FALSE)
  }
  reference["log_effort_z"] <- effort_reference

  list(
    G = nrow(group),
    D = nrow(daily),
    S = length(unique(daily$station_id)),
    P_occ = ncol(x_occ),
    P_det = ncol(x_det),
    P_int = ncol(x_int),
    X_occ = x_occ,
    X_det = x_det,
    X_int = x_int,
    site_id = daily$site_id,
    detected = daily$detected,
    k = as.integer(daily$positive_minutes),
    n = as.integer(daily$usable_minutes),
    start_day = group$start_day,
    end_day = group$end_day,
    any_positive = group$any_positive,
    x_det_reference = unname(reference),
    n_reference = 144L
  )
}

stan_sampling_settings <- function(profile = c("daily", "hourly")) {
  profile <- match.arg(profile)
  iterations <- if (profile == "daily") 750L else 1000L
  list(iter_warmup = iterations, iter_sampling = iterations)
}

fit_cmdstan_model <- function(stan_file, data, output_dir, seed, profile = "daily") {
  require_package("cmdstanr")
  settings <- stan_sampling_settings(profile)
  model <- cmdstanr::cmdstan_model(stan_file)
  model$sample(
    data = data,
    seed = seed,
    chains = 4,
    parallel_chains = 4,
    iter_warmup = settings$iter_warmup,
    iter_sampling = settings$iter_sampling,
    adapt_delta = 0.95,
    max_treedepth = 12,
    output_dir = output_dir,
    refresh = 200
  )
}

build_hourly_stan_data <- function(hourly) {
  require_package("data.table")
  hourly <- data.table::as.data.table(hourly)
  needed <- c("station_id", "date", "clock_hour", "positive_minutes", "sampled_minutes", "sin_week", "cos_week")
  missing <- setdiff(needed, names(hourly))
  if (length(missing)) stop("The hourly table is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  hourly <- hourly[sampled_minutes > 0]
  hourly <- hourly[, if (sum(positive_minutes) > 0) .SD, by = .(station_id, date)]
  if (!nrow(hourly)) stop("Hourly density needs at least one positive day.", call. = FALSE)
  if (any(hourly$positive_minutes > hourly$sampled_minutes)) stop("Positive counts exceed effort.", call. = FALSE)
  # Hour midpoints and two harmonics match the retained D1 design.
  theta <- 2 * pi * (hourly$clock_hour + 0.5) / 24
  hourly[, `:=`(
    sin_hour_1 = sin(theta), cos_hour_1 = cos(theta),
    sin_hour_2 = sin(2 * theta), cos_hour_2 = cos(2 * theta),
    day_id = .GRP
  ), by = .(station_id, date)]
  data.table::setorder(hourly, day_id, clock_hour)
  day <- hourly[, .(start_hour = .I[1], end_hour = .I[.N]), by = day_id]
  x <- stats::model.matrix(~ sin_week + cos_week + sin_hour_1 + cos_hour_1 + sin_hour_2 + cos_hour_2, data = hourly)
  list(
    J = nrow(day),
    R = nrow(hourly),
    P = ncol(x),
    X = x,
    day_id = hourly$day_id,
    k = as.integer(hourly$positive_minutes),
    n = as.integer(hourly$sampled_minutes),
    start_hour = day$start_hour,
    end_hour = day$end_hour
  )
}

run_calling_density_models <- function() {
  require_package("posterior")
  daily <- read_table(input_file("joint_daily_data"))
  if (!"imputation" %in% names(daily) || !setequal(unique(daily$imputation), 1:3)) {
    stop("joint_daily_data must contain the three retained host imputations (imputation = 1, 2, 3).", call. = FALSE)
  }
  out <- full_output_dir("07_calling_density")
  bundles <- summaries <- vector("list", 3L)
  for (m in 1:3) {
    daily_data <- build_joint_stan_data(daily[imputation == m])
    chain_dir <- file.path(out, paste0("daily_chains_M", m))
    ensure_dir(chain_dir)
    daily_fit <- fit_cmdstan_model(
      file.path(repo_root(), "stan", "463_joint_intensity_host_season_compare.stan"),
      daily_data, chain_dir, 464026L + m * 100L + 2L
    )
    bundles[[m]] <- list(
      draws = as.matrix(daily_fit$draws(c("beta_occ", "alpha_det", "gamma_int"), format = "matrix")),
      occurrence_names = colnames(daily_data$X_occ),
      detection_names = colnames(daily_data$X_det),
      x_det_reference = daily_data$x_det_reference
    )
    summaries[[m]] <- data.frame(imputation = m, posterior::summarise_draws(
      daily_fit$draws(c("beta_occ", "alpha_det", "gamma_int", "phi", "sigma_det"))))
  }
  saveRDS(bundles, file.path(out, "joint_daily_posteriors.rds"))
  write_table(do.call(rbind, summaries), file.path(out, "joint_daily_summary.csv"))

  hourly <- read_table(input_file("hourly_calling_counts"))
  hourly_data <- build_hourly_stan_data(hourly)
  ensure_dir(file.path(out, "hourly_chains"))
  hourly_fit <- fit_cmdstan_model(
    file.path(repo_root(), "stan", "470_conditional_hourly_density.stan"),
    hourly_data,
    file.path(out, "hourly_chains"),
    470127L,
    profile = "hourly"
  )
  hourly_fit$save_object(file.path(out, "hourly_density_fit.rds"))
  saveRDS(list(draws = as.matrix(hourly_fit$draws(c("beta", "sigma_day", "log_phi"), format = "matrix")),
               design_names = colnames(hourly_data$X)), file.path(out, "hourly_posterior.rds"))
  write_table(
    posterior::summarise_draws(hourly_fit$draws(c("beta", "phi", "sigma_day"))),
    file.path(out, "hourly_density_summary.csv")
  )
}
