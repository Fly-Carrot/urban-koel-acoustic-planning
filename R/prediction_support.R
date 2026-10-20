# Classify land-cover context and similarity to monitored environments.

nearest_distance <- function(query, reference, block_size = 1000L) {
  answer <- numeric(nrow(query))
  for (start in seq(1L, nrow(query), by = block_size)) {
    rows <- start:min(start + block_size - 1L, nrow(query))
    block <- vapply(seq_len(nrow(reference)), function(j) {
      rowSums((query[rows, , drop = FALSE] - matrix(reference[j, ], nrow = length(rows),
                                                     ncol = ncol(query), byrow = TRUE))^2)
    }, numeric(length(rows)))
    block <- matrix(block, nrow=length(rows), ncol=nrow(reference))
    answer[rows] <- sqrt(apply(block, 1, min) / ncol(query))
  }
  answer
}

aoa_threshold <- function(training) {
  distance <- as.matrix(stats::dist(training)) / sqrt(ncol(training))
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
  if (any(!is.finite(scale) | scale <= 0) || any(!is.finite(as.matrix(training[, ..predictors])))) {
    stop("All seven training predictors must be finite and variable.", call. = FALSE)
  }
  train_z <- sweep(sweep(as.matrix(training[, ..predictors]), 2, centre, "-"), 2, scale, "/")
  city_z <- sweep(sweep(as.matrix(city[, ..predictors]), 2, centre, "-"), 2, scale, "/")
  threshold <- aoa_threshold(train_z)
  finite <- apply(city_z, 1, function(x) all(is.finite(x)))
  di <- rep(NA_real_, nrow(city))
  if (any(finite)) di[finite] <- nearest_distance(city_z[finite, , drop = FALSE], train_z)
  city[, aoa_distance := di]
  ranges <- vapply(predictors, function(name) {
    city[[name]] >= min(training[[name]], na.rm = TRUE) &
      city[[name]] <= max(training[[name]], na.rm = TRUE)
  }, logical(nrow(city)))
  ranges <- matrix(ranges,nrow=nrow(city),ncol=length(predictors))
  city[, range_exceedances := length(predictors) - rowSums(ranges)]
  city[, aoa_class := data.table::fcase(
    !finite, "Invalid Data",
    range_exceedances >= 2 | aoa_distance > threshold[["maximum"]], "Severely Unsupported",
    range_exceedances == 1, "Extrapolated",
    aoa_distance > threshold[["q95"]], "Boundary",
    default = "Supported"
  )]
  city[, aoa_pass := aoa_class %in% c("Supported", "Boundary")]

  terrestrial <- c("trees", "grass", "shrub_and_scrub", "flooded_vegetation", "crops")
  cover_valid <- !is.na(city$permanent_water) & city$dominant_land_cover %in%
    c(terrestrial, "built", "bare", "water", "snow_and_ice")
  city[, pid := data.table::fcase(
    !cover_valid, "INVALID DATA",
    as.logical(permanent_water), "EXCLUDED",
    dominant_land_cover %in% terrestrial, "PASS",
    default = "UNCERTAIN"
  )]
  city[, support_class := data.table::fcase(
    pid == "INVALID DATA" | aoa_class == "Invalid Data", "Invalid Data",
    pid == "EXCLUDED", "Outside the Reporting Domain",
    aoa_class == "Severely Unsupported", "Monitoring Gaps",
    pid == "PASS" & aoa_class %in% c("Supported", "Boundary"), "Primary Results",
    default = "Moderate Extrapolation"
  )]
  attr(city, "aoa_threshold") <- threshold[["q95"]]
  attr(city, "aoa_maximum") <- threshold[["maximum"]]
  city[]
}

run_prediction_support <- function() {
  training <- read_table(input_file("training_predictors_250"), c("station_id"))
  city <- read_table(input_file("city_predictors_250"),
                     c("cell_id", "dominant_land_cover", "permanent_water"))
  support <- classify_prediction_support(training, city)
  out <- full_output_dir("09_prediction_support")
  write_table(support, file.path(out, "prediction_support_by_cell.csv"))
  write_table(
    as.data.frame(table(support$support_class), stringsAsFactors = FALSE),
    file.path(out, "prediction_support_counts.csv")
  )
}
