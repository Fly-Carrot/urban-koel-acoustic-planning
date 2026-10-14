# Classify land-cover context and similarity to monitored environments.

nearest_distance <- function(query, reference, block_size = 1000L) {
  answer <- numeric(nrow(query))
  for (start in seq(1L, nrow(query), by = block_size)) {
    rows <- start:min(start + block_size - 1L, nrow(query))
    block <- vapply(seq_len(nrow(reference)), function(j) {
      rowSums((query[rows, , drop = FALSE] - matrix(reference[j, ], nrow = length(rows),
                                                     ncol = ncol(query), byrow = TRUE))^2)
    }, numeric(length(rows)))
    answer[rows] <- sqrt(apply(block, 1, min))
  }
  answer
}

aoa_threshold <- function(training) {
  distance <- as.matrix(stats::dist(training))
  diag(distance) <- Inf
  nearest <- apply(distance, 1, min)
  c(q95 = stats::quantile(nearest, 0.95, names = FALSE), maximum = max(nearest))
}

classify_prediction_support <- function(training, city, predictors = environmental_predictor_names()) {
  require_package("data.table")
  training <- data.table::as.data.table(training)
  city <- data.table::as.data.table(city)
  if (anyDuplicated(training$station_id)) {
    stop("training_predictors_250 must contain one row per station.", call. = FALSE)
  }
  centre <- vapply(training[, ..predictors], mean, numeric(1), na.rm = TRUE)
  scale <- vapply(training[, ..predictors], stats::sd, numeric(1), na.rm = TRUE)
  scale[!is.finite(scale) | scale == 0] <- 1
  train_z <- sweep(sweep(as.matrix(training[, ..predictors]), 2, centre, "-"), 2, scale, "/")
  city_z <- sweep(sweep(as.matrix(city[, ..predictors]), 2, centre, "-"), 2, scale, "/")
  threshold <- aoa_threshold(train_z)
  city[, aoa_distance := nearest_distance(city_z, train_z)]
  ranges <- vapply(predictors, function(name) {
    city[[name]] >= min(training[[name]], na.rm = TRUE) &
      city[[name]] <= max(training[[name]], na.rm = TRUE)
  }, logical(nrow(city)))
  city[, range_exceedances := length(predictors) - rowSums(ranges)]
  city[, aoa_class := data.table::fcase(
    range_exceedances >= 2 | aoa_distance > threshold[["maximum"]], "Severely Unsupported",
    range_exceedances == 1, "Extrapolated",
    aoa_distance > threshold[["q95"]], "Boundary",
    default = "Supported"
  )]
  city[, aoa_pass := aoa_class == "Supported"]

  terrestrial <- c("trees", "grass", "shrub_and_scrub", "flooded_vegetation", "crops")
  city[, pid := data.table::fcase(
    as.logical(permanent_water), "EXCLUDED",
    dominant_land_cover %in% terrestrial, "PASS",
    default = "UNCERTAIN"
  )]
  city[, support_class := data.table::fcase(
    pid == "EXCLUDED", "Outside the Reporting Domain",
    aoa_class == "Severely Unsupported", "Monitoring Gaps",
    pid == "PASS" & aoa_class == "Supported", "Primary Results",
    default = "Moderate Extrapolation"
  )]
  attr(city, "aoa_threshold") <- threshold[["q95"]]
  attr(city, "aoa_maximum") <- threshold[["maximum"]]
  city[]
}

run_prediction_support <- function() {
  training <- read_table(full_asset("training_predictors_250"), c("station_id"))
  city <- read_table(full_asset("city_predictors_250"),
                     c("cell_id", "dominant_land_cover", "permanent_water"))
  support <- classify_prediction_support(training, city)
  out <- full_output_dir("09_prediction_support")
  write_table(support, file.path(out, "prediction_support_by_cell.csv"))
  write_table(
    as.data.frame(table(support$support_class), stringsAsFactors = FALSE),
    file.path(out, "prediction_support_counts.csv")
  )
}
