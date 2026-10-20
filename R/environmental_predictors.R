# Check station and city environmental predictors at each supplied scale.

environmental_predictor_names <- function() {
  c("trees", "built", "grass", "road_density", "tree_edge_area_50m",
    "dist_water_m_nearest", "elevation")
}

validate_environmental_predictors <- function() {
  require_package("data.table")
  weekly <- read_table(input_file("weekly_covariates_250"), c("station_id", "study_week"))
  city <- read_table(input_file("city_predictors_250"), c("cell_id"))
  needed <- environmental_predictor_names()
  missing_weekly <- setdiff(needed, names(weekly))
  missing_city <- setdiff(needed, names(city))
  if (length(missing_weekly) || length(missing_city)) {
    stop("Environmental inputs do not contain the seven study predictors.", call. = FALSE)
  }
  if (any(!is.finite(as.matrix(weekly[, ..needed])))) stop("Station predictors contain non-finite values.", call. = FALSE)
  if (any(!is.finite(as.matrix(city[, ..needed])))) stop("City predictors contain non-finite values.", call. = FALSE)
  out <- full_output_dir("03_environment")
  write_table(data.frame(
    dataset = c("station_week", "city_cell"),
    rows = c(nrow(weekly), nrow(city)),
    predictors = length(needed)
  ), file.path(out, "environmental_input_check.csv"))
}
