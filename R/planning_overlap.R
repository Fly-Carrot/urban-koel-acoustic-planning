# Summarise weekly opportunity at mapped points and urban-function areas.

posterior_group_summary <- function(draws, row_index, weight) {
  keep <- is.finite(row_index) & is.finite(weight) & weight > 0
  if (!any(keep)) {
    return(data.frame(n_units = 0L, weight_total = 0, mean = NA_real_,
                      median = NA_real_, q025 = NA_real_, q975 = NA_real_))
  }
  row_index <- row_index[keep]
  weight <- weight[keep]
  weighted_draw <- colSums(draws[row_index, , drop = FALSE] * weight) / sum(weight)
  data.frame(
    n_units = length(row_index),
    weight_total = sum(weight),
    mean = mean(weighted_draw),
    median = stats::median(weighted_draw),
    q025 = stats::quantile(weighted_draw, 0.025, names = FALSE),
    q975 = stats::quantile(weighted_draw, 0.975, names = FALSE)
  )
}

run_planning_overlap <- function() {
  # New-data weekly overlaps stay separate from the retained joint-model
  # dawn calculations in analysis/reproduce_retained.R.
  summarise_new_weekly_overlap()
}

summarise_new_weekly_overlap <- function() {
  require_package("data.table")
  prediction <- read_table(
    file.path(full_output_dir("08_city_prediction"), "city_week_predictions.csv"),
    c("cell_id", "annual_week", "psi_median")
  )
  draws <- readRDS(file.path(full_output_dir("08_city_prediction"), "city_week_psi_draws.rds"))
  if (nrow(draws) != nrow(prediction)) stop("Prediction draws and rows do not align.", call. = FALSE)
  prediction[, row_index := seq_len(.N)]
  support <- read_table(
    file.path(full_output_dir("09_prediction_support"), "prediction_support_by_cell.csv"),
    c("cell_id", "support_class")
  )
  supported <- support[support_class %in% c("Primary Results", "Moderate Extrapolation")]
  prediction <- merge(prediction, supported[, .(cell_id)], by = "cell_id")

  points <- read_table(full_asset("planning_sensitive_points"), c("cell_id", "context_class"))
  polygons <- read_table(full_asset("urban_function_overlap"),
                         c("cell_id", "context_class", "overlap_area_m2"))
  point_join <- merge(points, prediction, by = "cell_id")
  point_join[, weight := 1]
  polygon_join <- merge(polygons, prediction, by = "cell_id")
  polygon_join[, weight := overlap_area_m2]

  point_summary <- point_join[, posterior_group_summary(draws, row_index, weight),
                              by = .(layer = "planning_sensitive_point", context_class, annual_week)]
  polygon_summary <- polygon_join[, posterior_group_summary(draws, row_index, weight),
                                  by = .(layer = "urban_function", context_class, annual_week)]
  out <- full_output_dir("10_planning_overlap")
  write_table(rbind(point_summary, polygon_summary), file.path(out, "planning_overlap_summary.csv"))
}
