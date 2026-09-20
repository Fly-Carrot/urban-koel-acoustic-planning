prepare_survey_histories <- function(effort, detections) {
  require_package("data.table")
  effort <- data.table::as.data.table(effort)
  detections <- data.table::as.data.table(detections)

  needed_effort <- c("station_id", "date", "scheduled_minutes", "usable_minutes")
  needed_detection <- c("station_id", "date", "sampled_minute", "species_group")
  if (length(setdiff(needed_effort, names(effort)))) stop("The effort table is incomplete.", call. = FALSE)
  if (length(setdiff(needed_detection, names(detections)))) stop("The detection table is incomplete.", call. = FALSE)

  effort[, date := as.Date(date)]
  detections[, date := as.Date(date)]
  if (anyDuplicated(effort[, .(station_id, date)])) {
    stop("The effort table must contain one row per station and date.", call. = FALSE)
  }

  # A zero is a non-detection only when recording effort was confirmed.
  effort[, valid_survey := is.finite(usable_minutes) & usable_minutes > 0]
  detections <- detections[!is.na(station_id) & !is.na(date) & !is.na(species_group)]
  if ("retained" %in% names(detections)) detections <- detections[retained == TRUE]
  if ("positive" %in% names(detections)) detections <- detections[positive == TRUE]

  positive <- unique(detections[, .(station_id, date, species_group, sampled_minute)])[
    , .(positive_minutes = .N), by = .(station_id, date, species_group)
  ]
  groups <- sort(unique(detections$species_group))
  if (!length(groups)) stop("No retained acoustic detections were found.", call. = FALSE)

  daily <- effort[
    rep(seq_len(.N), each = length(groups)),
    .(station_id, date, scheduled_minutes, usable_minutes, valid_survey)
  ]
  daily[, species_group := rep(groups, times = nrow(effort))]
  daily <- merge(daily, positive, by = c("station_id", "date", "species_group"), all.x = TRUE)
  daily[valid_survey & is.na(positive_minutes), positive_minutes := 0L]
  daily[valid_survey == FALSE, positive_minutes := NA_integer_]
  daily[, detected := as.integer(positive_minutes > 0)]

  first_date <- min(daily$date, na.rm = TRUE)
  daily[, study_week := as.integer(as.integer(date - first_date) %/% 7) + 1L]
  daily[, annual_week := as.integer(strftime(date, format = "%V"))]
  daily[, survey_day := as.integer(format(date, "%u"))]
  seasonal <- week_terms(daily$annual_week)
  daily[, `:=`(sin_week = seasonal$sin_week, cos_week = seasonal$cos_week)]
  data.table::setorder(daily, species_group, station_id, study_week, date)
  daily[]
}

make_tpg_data <- function(daily, weekly_covariates, detection_covariates, response_group) {
  require_package("data.table")
  daily <- data.table::as.data.table(daily)[species_group == response_group]
  weekly_covariates <- data.table::as.data.table(weekly_covariates)
  detection_covariates <- data.table::as.data.table(detection_covariates)
  if (!nrow(daily)) stop("No daily records for response_group: ", response_group, call. = FALSE)

  sites <- sort(unique(daily$station_id))
  weeks <- sort(unique(daily$study_week))
  keys <- data.table::CJ(station_id = sites, study_week = weeks, unique = TRUE)
  visits <- sort(unique(daily$survey_day))
  y <- array(
    NA_integer_,
    dim = c(length(sites), length(weeks), length(visits)),
    dimnames = list(station_id = sites, study_week = weeks, survey_day = visits)
  )
  site_index <- match(daily$station_id, sites)
  week_index <- match(daily$study_week, weeks)
  visit_index <- match(daily$survey_day, visits)
  y[cbind(site_index, week_index, visit_index)] <- daily$detected

  occ <- merge(keys, weekly_covariates, by = c("station_id", "study_week"), all.x = TRUE)
  data.table::setorder(occ, station_id, study_week)
  occ_covs <- lapply(setdiff(names(occ), c("station_id", "study_week")), function(name) {
    matrix(occ[[name]], nrow = length(sites), ncol = length(weeks), byrow = TRUE,
           dimnames = list(sites, weeks))
  })
  names(occ_covs) <- setdiff(names(occ), c("station_id", "study_week"))

  det <- merge(
    daily[, .(station_id, study_week, survey_day, usable_minutes)],
    detection_covariates,
    by = c("station_id", "study_week", "survey_day"),
    all.x = TRUE
  )
  data.table::setorder(det, station_id, study_week, survey_day)
  if (!"log_effort_z" %in% names(det)) {
    scaled_effort <- z_scale(log(pmax(det$usable_minutes, 1)))
    det[, log_effort_z := scaled_effort$value]
  }
  det[, site_re := match(station_id, sites)]
  det_names <- setdiff(names(det), c("station_id", "study_week", "survey_day"))
  det_covs <- lapply(det_names, function(name) {
    out <- array(NA_real_, dim = dim(y), dimnames = dimnames(y))
    out[cbind(match(det$station_id, sites), match(det$study_week, weeks), match(det$survey_day, visits))] <- det[[name]]
    out
  })
  names(det_covs) <- det_names

  list(y = y, occ.covs = occ_covs, det.covs = det_covs)
}

run_prepare_survey_histories <- function() {
  effort <- read_table(
    full_asset("survey_effort"),
    c("station_id", "date", "scheduled_minutes", "usable_minutes")
  )
  detections <- read_table(
    full_asset("acoustic_detections"),
    c("station_id", "date", "sampled_minute", "species_group")
  )
  daily <- prepare_survey_histories(effort, detections)
  out <- full_output_dir("01_survey_histories")
  write_table(daily, file.path(out, "daily_survey_histories.csv"))
  write_table(
    daily[, .(
      valid_days = sum(valid_survey),
      positive_days = sum(detected, na.rm = TRUE),
      sampled_minutes = sum(usable_minutes[valid_survey], na.rm = TRUE)
    ), by = species_group],
    file.path(out, "survey_reconciliation.csv")
  )
}
