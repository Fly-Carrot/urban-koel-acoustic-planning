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
    "equal_scale_host_index_z"
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
    n_reference = as.integer(stats::median(daily$usable_minutes))
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
  needed <- c("station_id", "date", "clock_hour", "positive_minutes", "sampled_minutes")
  missing <- setdiff(needed, names(hourly))
  if (length(missing)) stop("The hourly table is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  hourly <- hourly[sampled_minutes > 0]
  hourly[, `:=`(
    sin_hour = sin(2 * pi * clock_hour / 24),
    cos_hour = cos(2 * pi * clock_hour / 24),
    day_id = .GRP
  ), by = .(station_id, date)]
  data.table::setorder(hourly, day_id, clock_hour)
  day <- hourly[, .(start_hour = .I[1], end_hour = .I[.N]), by = day_id]
  x <- stats::model.matrix(~ sin_hour + cos_hour, data = hourly)
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
  daily <- read_table(full_asset("joint_daily_data"))
  out <- full_output_dir("07_calling_density")
  daily_data <- build_joint_stan_data(daily)
  daily_fit <- fit_cmdstan_model(
    file.path(repo_root(), "stan", "462_joint_occupancy_hurdle_intensity.stan"),
    daily_data,
    file.path(out, "daily_chains"),
    2026082501L
  )
  daily_fit$save_object(file.path(out, "joint_daily_fit.rds"))
  write_table(
    posterior::summarise_draws(
      daily_fit$draws(c("beta_occ", "alpha_det", "gamma_int", "phi", "sigma_det"))
    ),
    file.path(out, "joint_daily_summary.csv")
  )

  hourly <- read_table(full_asset("hourly_calling_counts"))
  hourly_data <- build_hourly_stan_data(hourly)
  hourly_fit <- fit_cmdstan_model(
    file.path(repo_root(), "stan", "470_conditional_hourly_density.stan"),
    hourly_data,
    file.path(out, "hourly_chains"),
    2026082502L,
    profile = "hourly"
  )
  hourly_fit$save_object(file.path(out, "hourly_density_fit.rds"))
  write_table(
    posterior::summarise_draws(hourly_fit$draws(c("beta", "phi", "sigma_day"))),
    file.path(out, "hourly_density_summary.csv")
  )
}
