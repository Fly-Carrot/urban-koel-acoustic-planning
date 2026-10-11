source("R/analysis_io.R")
source("R/occupancy_models.R")
source("R/transfer_validation.R")
source("R/calling_density.R")
source("R/city_prediction.R")
source("R/exposure_prediction.R")

# Compare joint station likelihood against direct integration over the same draws.
toy <- list(y = array(c(1, 0), c(1, 2, 1), dimnames = list("A", c("1", "2"), "1")),
            occ.covs = list(x = matrix(c(0, 1), 1)),
            det.covs = list(x = array(c(0, 1), c(1, 2, 1))))
fit <- list(beta.samples = matrix(c(-2, 2, 0, 0), 2, dimnames = list(NULL, c("(Intercept)", "x"))),
            alpha.samples = matrix(c(-1, 1, 0, 0), 2, dimnames = list(NULL, c("(Intercept)", "x"))),
            sigma.sq.p.samples = c(0.04, 0.09))
s <- score_heldout_history(fit, toy, ~ x, ~ x, posterior_draws = 2, random_effect_draws = 3, seed = 77)
set.seed(77)
psi <- rep(stats::plogis(c(-2, 2)), each = 3)
p <- stats::plogis(rep(c(-1, 1), each = 3) + stats::rnorm(6, 0, rep(c(0.2, 0.3), each = 3)))
direct <- log(mean((psi * p) * (1 - psi * p)))
stopifnot(abs(s$site_log_predictive_density[1] - direct) < 1e-12)
stopifnot(abs(sum(s$log_predictive_density) - direct) > 1e-4)

s$model_id <- "H4"; s$scale_m <- 250; s$fold_id <- 1
s2 <- s; s2$site_log_predictive_density <- s$site_log_predictive_density - 2
pooled <- pool_host_scores(rbind(s, s2))
expected <- log_mean_exp(c(direct, direct - 2))
stopifnot(abs(summarise_heldout_scores(pooled)$heldout_elpd - expected) < 1e-12)
station_scores <- data.frame(station_id = rep(c("A", "B", "C"), 2), scale_m = 250,
                            fold_id = rep(1:3, 2), model_id = rep(c("three_host", "no_host"), each = 3),
                            site_log_predictive_density = c(-2, -4, -5, -3, -5, -8))
contrast <- paired_station_contrast(station_scores)
stopifnot(contrast$delta_elpd_host_minus_no_host == 5,
          abs(contrast$station_clustered_se - sqrt(3 * stats::var(c(1, 1, 3)))) < 1e-12)

# D1 contains annual terms and two hour harmonics; all-zero days are excluded.
hourly <- data.frame(station_id = "A", date = rep(c("2026-01-01", "2026-01-02"), each = 2),
                     clock_hour = rep(c(6, 7), 2), positive_minutes = c(1, 0, 0, 0),
                     sampled_minutes = 6, sin_week = 0, cos_week = 1)
h <- build_hourly_stan_data(hourly)
stopifnot(h$J == 1, h$R == 2, h$P == 7,
          identical(colnames(h$X), c("(Intercept)", "sin_week", "cos_week", "sin_hour_1", "cos_hour_1", "sin_hour_2", "cos_hour_2")))

# Annual host opportunity uses the retained host scaling and equal-scale index.
host_grid <- data.frame(cell_id = c("X", "Y", "X"), trees = c(0, 1, 0), built = 0,
                        grass = c(0, 1, 0), road_density = 0, tree_edge_area_50m = c(0, 1, 0),
                        dist_water_m_nearest = 0, elevation = 0, sin_week = 0, cos_week = 1)
host_models <- lapply(host_formulas(), function(formula) {
  columns <- colnames(stats::model.matrix(formula, host_grid))
  beta <- matrix(0, 1, length(columns), dimnames = list(NULL, columns))
  beta[1, "(Intercept)"] <- -1; beta[1, 2] <- 0.8
  beta[1, "sin_week"] <- 0.3; beta[1, "cos_week"] <- -0.2
  list(beta.samples = beta)
})
schedule <- data.frame(host_group = names(host_models), draw_index = 1)
scaling <- data.frame(imputation = 1, host_group = c(names(host_models), "equal_scale"),
                      centre = c(0.4, 0.4, 0.4, 0.1), scale = c(0.2, 0.2, 0.2, 0.7))
annual <- annual_equal_scale_host(host_models, schedule, host_grid, scaling, 1)
phase <- 2 * pi * ((1:365) - 1) / 365.2425
raw <- vapply(c(-1, -0.2, -1), function(a) mean(stats::plogis(a + 0.3 * sin(phase) - 0.2 * cos(phase))), numeric(1))
stopifnot(max(abs(annual - (((raw - 0.4) / 0.2 - 0.1) / 0.7))) < 1e-12)

# Check positive-day conditioning and matched posterior products.
eta <- matrix(stats::qlogis(0.1), 1, 24)
phi <- 50
p0 <- exp(lbeta(0.1 * phi, 6 + 0.9 * phi) - lbeta(0.1 * phi, 0.9 * phi))
stopifnot(abs(conditional_hour_fraction(eta, phi) - 0.1 / (1 - p0^24)) < 1e-12)
grid <- data.frame(trees = 0, built = 0, dist_water_m_nearest = 0, elevation = 0,
                   corvid_host_psi_z = 0, sturnid_host_psi_z = 0, laughingthrush_host_psi_z = 0,
                   sin_week = 0, cos_week = 1)
names_occ <- colnames(stats::model.matrix(koel_three_host_formula(), grid))
j <- matrix(0, 2, length(names_occ) + 1 + 4)
colnames(j) <- c(paste0("beta_occ[", seq_along(names_occ), "]"), "alpha_det[1]", paste0("gamma_int[", 1:4, "]"))
j[, "beta_occ[1]"] <- c(-2, 2); j[, "alpha_det[1]"] <- c(2, -2)
j[, "gamma_int[1]"] <- stats::qlogis(0.1)
hd <- matrix(0, 2, 9); colnames(hd) <- c(paste0("beta[", 1:7, "]"), "sigma_day", "log_phi")
hd[, "log_phi"] <- log(phi)
joint <- list(draws = j, occurrence_names = names_occ, detection_names = "(Intercept)", x_det_reference = 1)
hour <- list(draws = hd, design_names = colnames(h$X))
e <- predict_modular_exposure(grid, 0, joint, hour, n_draws = 2)
target <- stats::plogis(c(-2, 2)) * stats::plogis(c(2, -2)) * conditional_hour_fraction(eta, phi)
stopifnot(max(abs(as.numeric(e) - target)) < 1e-12)
cat("Final scoring, hourly design and matched exposure tests passed.\n")
