source(file.path("R", "release_utils.R"))

root <- repo_root()
source_root <- Sys.getenv("PROJECT55_RESULTS_ROOT", "")
assert_release(nzchar(source_root) && dir.exists(source_root),
               "Set PROJECT55_RESULTS_ROOT to the corrected-effort result directory.")
source_root <- normalizePath(source_root, winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "data", "processed", "reference")
manifest_dir <- file.path(root, "data", "manifests")
example_dir <- file.path(root, "data", "example")
ensure_dir(out_dir); ensure_dir(manifest_dir); ensure_dir(example_dir)

read_source <- function(...) {
  path <- file.path(source_root, ...)
  assert_release(file.exists(path), paste("Missing internal source:", file.path(...)))
  utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}

# Study-level effort reconciliation.
survey <- read_source("phase_a_response_detection", "effort_response_audit.csv")
names(survey)[names(survey) == "check"] <- "metric"
write_csv_release(survey, file.path(out_dir, "survey_reconciliation.csv"))

# Frozen formulas and predictor definitions.
models <- utils::read.csv(file.path(root, "config", "model_registry.csv"), check.names = FALSE)
write_csv_release(models, file.path(out_dir, "model_registry_public.csv"))
predictors <- utils::read.csv(file.path(root, "config", "predictor_registry.csv"), check.names = FALSE)
write_csv_release(predictors, file.path(out_dir, "predictor_registry_public.csv"))

# Exact membership of the three potential-host acoustic responses.
hosts <- data.frame(
  host_group = c(rep("corvid assemblage", 4), rep("sturnid assemblage", 3), "Masked Laughingthrush"),
  species_common_name = c("Red-billed Blue Magpie", "Azure-winged Magpie", "Oriental Magpie", "Large-billed Crow",
                          "Black-collared Starling", "Common Myna", "Crested Myna", "Masked Laughingthrush"),
  species_scientific_name = c("Urocissa erythroryncha", "Cyanopica cyanus", "Pica serica", "Corvus macrorhynchos",
                              "Gracupica nigricollis", "Acridotheres tristis", "Acridotheres cristatellus",
                              "Pterorhinus perspicillatus"),
  response_definition = "Effort-confirmed day positive when any group member had a retained acoustic record",
  stringsAsFactors = FALSE
)
write_csv_release(hosts, file.path(out_dir, "host_groups.csv"))

# Article-primary weekly opportunity and daily detectability summaries.
fixed <- read_source("phase_b_koel_H0_H5", "pooled_fixed_effects.csv")
fixed <- fixed[fixed$model_id == "H4" & fixed$parameter != "(Intercept)", ]
fixed$component <- ifelse(fixed$layer == "occurrence", "weekly_opportunity", "daily_detectability")
term_map <- c(
  trees = "tree_cover", built = "built_cover", dist_water_m_nearest = "distance_to_nearest_water",
  elevation = "elevation", sin_week = "annual_sine", cos_week = "annual_cosine",
  corvid_assemblage_host_psi_z = "corvid_opportunity", sturnid_assemblage_host_psi_z = "sturnid_opportunity",
  black_faced_laughingthrush_host_psi_z = "laughingthrush_opportunity", log_effort_z = "recording_effort",
  log1p_anthropogenic_rate_z = "anthropogenic_sounds", log1p_frog_rate_z = "frog_sounds"
)
fixed$term <- unname(term_map[fixed$parameter])
effects <- fixed[, c("component", "term", "mean", "sd", "median", "q025", "q975", "posterior_draws")]
effects$source_role <- "pooled H4 P0 posterior summary across three host imputations"
density <- data.frame(
  component = "positive_day_minute_probability",
  term = c("equal_scale_potential_host_opportunity", "annual_sine", "annual_cosine"),
  mean = c(0.44, 2.94, -1.16), sd = NA_real_, median = c(0.44, 2.94, -1.16),
  q025 = c(0.33, 2.40, -1.56), q975 = c(0.61, 3.60, -0.81), posterior_draws = NA_integer_,
  source_role = "reported pooled HEQZ daily density summary",
  stringsAsFactors = FALSE
)
effects <- rbind(effects, density)
write_csv_release(effects, file.path(out_dir, "model_effects.csv"))

# Transfer, coordinate and multiscale validation anchors.
contrasts <- read_source("phase_e_host_mechanism_transfer", "joint_host_transfer_r250", "scores", "paired_site_clustered_contrasts.csv")
r100 <- contrasts[contrasts$score_re_draws == 100, ]
pick <- function(type, a, b) r100[r100$contrast_type == type & r100$model_a == a & r100$model_b == b, ][1, ]
host <- pick("host_structure_minus_H0", "H4_P0", "H0_P0")
coord <- pick("coordinate_Pxy_minus_P0", "H4_Pxy", "H4_P0")
scales <- read_source("phase_c_transfer_multiscale", "phase_c_scale_contrasts_against_250.csv")
decision <- read_source("phase_e_host_mechanism_transfer", "joint_host_transfer_r250", "scores", "P0_Pxy_transfer_decision_primary_R100.csv")
transfer <- data.frame(
  comparison = c("three_host_minus_no_host_coordinate_free", "coordinate_trend_minus_coordinate_free_three_host",
                 "100m_minus_250m", "500m_minus_250m", "three_host_coordinate_free_held_site_performance"),
  metric = c("delta_held_site_ELPD", "delta_held_site_ELPD", "delta_held_site_ELPD", "delta_held_site_ELPD", "held_site_ELPD"),
  estimate = c(host$delta_elpd_a_minus_b, coord$delta_elpd_a_minus_b, scales$delta_elpd_a_minus_b[scales$scale_a == 100],
               scales$delta_elpd_a_minus_b[scales$scale_a == 500], decision$p0_held_site_joint_elpd),
  standard_error = c(host$site_clustered_se, coord$site_clustered_se, scales$site_clustered_se[scales$scale_a == 100],
                     scales$site_clustered_se[scales$scale_a == 500], NA_real_),
  interval_low = c(host$ci95_low, coord$ci95_low, scales$ci95_low[scales$scale_a == 100],
                   scales$ci95_low[scales$scale_a == 500], NA_real_),
  interval_high = c(host$ci95_high, coord$ci95_high, scales$ci95_high[scales$scale_a == 100],
                    scales$ci95_high[scales$scale_a == 500], NA_real_),
  n_sites = 31L,
  brier = c(NA, NA, NA, NA, decision$p0_brier_atleast_one),
  calibration_intercept = c(NA, NA, NA, NA, decision$p0_calibration_intercept),
  calibration_slope = c(NA, NA, NA, NA, decision$p0_calibration_slope),
  residual_moran_i = c(NA, NA, NA, NA, decision$p0_moran_i),
  residual_moran_p_bh = c(NA, NA, NA, NA, decision$p0_moran_p_bh),
  decision = c("host block improved coordinate-free transfer", "retain coordinate-free model by parsimony",
               "no clear scale replacement", "no clear scale replacement", "article ecological-planning primary"),
  stringsAsFactors = FALSE
)
write_csv_release(transfer, file.path(out_dir, "transfer_validation.csv"))

# Geometry-free annual city summaries.
psi <- read_source("phase_l_H4_P0_supported_weekly_visualization_20260727", "H4_P0_primary_plus_moderate_weekly_psi_summary.csv")
names(psi)[names(psi) == "calendar_week_52"] <- "calendar_week"
psi$mapping_population <- "centroid-in-city Primary Results + Moderate Extrapolation subset"
write_csv_release(psi, file.path(out_dir, "weekly_acoustic_opportunity.csv"))
exposure <- read_source("phase_m_H4_P0_all_day_exposure_20260727", "H4_P0_primary_plus_moderate_weekly_all_day_exposure_summary.csv")
names(exposure)[names(exposure) == "calendar_week_52"] <- "calendar_week"
exposure$mapping_population <- "centroid-in-city Primary Results + Moderate Extrapolation subset"
write_csv_release(exposure, file.path(out_dir, "weekly_acoustic_exposure.csv"))

# Support-class totals with article terminology.
support <- read_source("phase_l_H4_P0_supported_weekly_visualization_20260727", "H4_P0_interpretation_tier_summary.csv")
support_map <- c("Primary result" = "Primary Results", "Moderate interpretation" = "Moderate Extrapolation",
                 "Monitoring gap" = "Monitoring Gaps", "Outside reporting domain" = "Outside the Reporting Domain")
support$support_class <- unname(support_map[support$interpretation_tier])
support$percent_all_hex <- support$percent_all_hex
support <- support[, c("support_class", "n_hex", "percent_all_hex")]
write_csv_release(support, file.path(out_dir, "prediction_support_classes.csv"))

# Aggregate planning intersections; no POI records or geometry.
functional <- read_source("phase_n_H4_P0_POI_functional_overlap_20260727", "H4_P0_functional_zone_planning_table.csv")
poi <- read_source("phase_n_H4_P0_POI_functional_overlap_20260727", "H4_P0_POI_planning_table.csv")
planning <- rbind(functional, poi)
planning$planning_domain <- "Primary Results + Moderate Extrapolation"
keep <- c("group_type", "group_name", "n_spatial_units", "unit_total", "unit_label", "peak_week_from_posterior_mean",
          "peak_week_posterior_mode", "peak_week_mode_probability", "median_annual_mean_psi", "median_w10_w30_mean_psi",
          "median_dawn_w15_w21_expected_positive_sampled_minutes", "median_dawn_w15_w21_probability_at_least_one",
          "q025_annual_mean_psi", "q975_annual_mean_psi", "q025_w10_w30_mean_psi", "q975_w10_w30_mean_psi",
          "q025_dawn_w15_w21_expected_positive_sampled_minutes", "q975_dawn_w15_w21_expected_positive_sampled_minutes",
          "q025_dawn_w15_w21_probability_at_least_one", "q975_dawn_w15_w21_probability_at_least_one",
          "posterior_draws", "planning_domain")
write_csv_release(planning[, keep], file.path(out_dir, "planning_overlap.csv"))

# Route-specific ranks without candidate identity or location.
deployment <- read_source("phase_o_H4_uncertainty_guided_PAM_design_20260727", "H4_P0_budget_portfolios.csv")
deployment$route <- ifelse(deployment$route == "Environmental learning", "Coverage Expansion", "Prediction Validation")
deployment$route_sequence_id <- paste0(ifelse(deployment$route == "Coverage Expansion", "CE", "PV"), sprintf("%02d", deployment$route_rank))
deployment$deployment_size <- deployment$total_budget
deployment$planning_context <- deployment$public_relevance_class
deployment$primary_objective <- gsub(
  "prospective marginal reduction of H4 severely unsupported Monitoring-gap HEXes",
  "prospective marginal reduction of severely unsupported Monitoring Gap HEXes under the primary three-host model",
  deployment$primary_objective,
  fixed = TRUE
)
deployment$primary_objective <- gsub(
  "largest remaining W15-W21 H4_P0 psi 95% credible-interval width",
  "largest remaining W15-W21 primary three-host weekly-opportunity 95% credible-interval width",
  deployment$primary_objective,
  fixed = TRUE
)
deployment$prospective_gap_coverage_share <- ifelse(
  deployment$route == "Coverage Expansion", deployment$cumulative_interpretable_gain_hex / 7066, NA_real_
)
keep <- c("deployment_size", "route_budget", "route", "route_sequence_id", "route_rank",
          "marginal_interpretable_gain_hex", "cumulative_interpretable_gain_hex", "prospective_gap_coverage_share",
          "W15_W21_psi_CrI_width", "planning_context",
          "primary_objective", "optimality_claim", "allocation_rule")
write_csv_release(deployment[, keep], file.path(out_dir, "adaptive_monitoring_sequences.csv"))

# Small deterministic example with pseudonymous IDs and no geography.
set.seed(20260814)
example <- expand.grid(site_id = sprintf("SITE_%02d", 1:3), annual_week = 15:16, survey_day = 1:3,
                       KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
example$scheduled_minutes <- sample(c(72L, 144L), nrow(example), replace = TRUE)
example$koel_positive_minutes <- pmin(example$scheduled_minutes, stats::rbinom(nrow(example), 4, 0.18))
example$detected <- as.integer(example$koel_positive_minutes > 0)
example$synthetic <- TRUE
write_csv_release(example, file.path(example_dir, "synthetic_survey_histories.csv"))

# Manifest for the released data products. It deliberately excludes itself.
reference_files <- sort(list.files(out_dir, pattern = "\\.csv$", full.names = TRUE))
manifest <- data.frame(
  path = file.path("data", "processed", "reference", basename(reference_files)),
  role = sub("\\.csv$", "", basename(reference_files)),
  sha256 = vapply(reference_files, sha256_file, character(1)),
  size_bytes = as.numeric(file.info(reference_files)$size),
  owner = "urban-koel-acoustic-planning contributors",
  source = "curated aggregate from corrected-effort analysis lineage",
  version = "0.1.0",
  spdx = "CC-BY-4.0",
  redistribution = "yes; aggregate project-owned summary",
  attribution = "Cite this repository version and associated article when available",
  privacy_class = "aggregate_non_sensitive",
  coordinate_precision = "not_applicable_no_coordinates",
  approval_reference = "SPEC-20260814-001 curated public release",
  stringsAsFactors = FALSE
)
write_csv_release(manifest, file.path(manifest_dir, "reference_products.csv"))
cat("Curated", nrow(manifest), "reference products and one synthetic example.\n")
