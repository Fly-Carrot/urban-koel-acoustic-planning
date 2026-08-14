repo_root <- function() {
  here <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(here, "CITATION.cff")) && dir.exists(file.path(here, "analysis"))) return(here)
    parent <- dirname(here)
    if (identical(parent, here)) stop("Repository root not found.", call. = FALSE)
    here <- parent
  }
}

abort_release <- function(message) stop(message, call. = FALSE)

assert_release <- function(condition, message) {
  if (!isTRUE(condition)) abort_release(message)
  invisible(TRUE)
}

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

read_csv_release <- function(path, required = character()) {
  assert_release(file.exists(path), paste("Missing required file:", path))
  x <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  absent <- setdiff(required, names(x))
  assert_release(length(absent) == 0L, paste("Missing columns in", basename(path), ":", paste(absent, collapse = ", ")))
  x
}

write_csv_release <- function(x, path) {
  ensure_dir(dirname(path))
  utils::write.csv(x, path, row.names = FALSE, na = "")
  invisible(path)
}

copy_reference <- function(name, output_subdir = "tables") {
  root <- repo_root()
  src <- file.path(root, "data", "processed", "reference", name)
  dst <- file.path(root, "outputs", output_subdir, name)
  assert_release(file.exists(src), paste("Reference product unavailable:", name))
  ensure_dir(dirname(dst))
  ok <- file.copy(src, dst, overwrite = TRUE)
  assert_release(ok, paste("Could not copy", name))
  dst
}

parse_profile <- function(args = commandArgs(trailingOnly = TRUE)) {
  hit <- grep("^--profile=", args, value = TRUE)
  profile <- if (length(hit)) sub("^--profile=", "", hit[[1]]) else Sys.getenv("KOEL_PROFILE", "verify")
  assert_release(profile %in% c("smoke", "verify", "full"), "Profile must be smoke, verify, or full.")
  profile
}

sha256_file <- function(path) {
  assert_release(file.exists(path), paste("Cannot hash missing file:", path))
  if (nzchar(Sys.which("sha256sum"))) {
    out <- system2("sha256sum", path, stdout = TRUE)
    return(strsplit(out[[1]], "[[:space:]]+")[[1]][[1]])
  }
  if (nzchar(Sys.which("shasum"))) {
    out <- system2("shasum", c("-a", "256", path), stdout = TRUE)
    return(strsplit(out[[1]], "[[:space:]]+")[[1]][[1]])
  }
  if (nzchar(Sys.which("openssl"))) {
    out <- system2("openssl", c("dgst", "-sha256", path), stdout = TRUE)
    return(sub("^.*= ", "", out[[1]]))
  }
  abort_release("A SHA-256 command is required: sha256sum, shasum, or openssl.")
}

write_step_log <- function(step, profile, status, details = "") {
  root <- repo_root()
  path <- file.path(root, "outputs", "logs", paste0(step, ".csv"))
  write_csv_release(data.frame(
    step = step,
    profile = profile,
    status = status,
    details = details,
    stringsAsFactors = FALSE
  ), path)
  invisible(path)
}

require_full_inputs <- function() {
  abort_release(paste(
    "The pre-publication repository exposes the full model specification and Stan source,",
    "but does not distribute private-input adapters or restricted inputs.",
    "Use the public verify profile; see docs/data_access.md for the full-data contract."
  ))
}

run_public_step <- function(step, profile) {
  root <- repo_root()
  if (identical(profile, "full")) require_full_inputs()

  if (step == "00_preflight") {
    source(file.path(root, "tools", "validate_contract.R"), local = new.env(parent = globalenv()))
  } else if (step == "01_prepare_survey_histories") {
    path <- copy_reference("survey_reconciliation.csv")
    x <- read_csv_release(path, c("metric", "value", "expected", "pass"))
    assert_release(all(x$pass), "Survey reconciliation failed.")
  } else if (step == "02_select_detection_backbone") {
    path <- copy_reference("model_registry_public.csv")
    x <- read_csv_release(path, c("component", "public_formula", "role"))
    assert_release(any(x$component == "daily_detectability"), "Detection formula is absent.")
  } else if (step == "03_build_environmental_predictors") {
    path <- copy_reference("predictor_registry_public.csv")
    x <- read_csv_release(path, c("public_name", "likelihood_layer", "spatial_support"))
    assert_release(all(!grepl("hex", x$spatial_support, ignore.case = TRUE) | x$likelihood_layer == "reporting"), "Ecological and map supports were conflated.")
  } else if (step == "04_fit_potential_host_opportunity") {
    path <- copy_reference("host_groups.csv")
    x <- read_csv_release(path, c("host_group", "species_common_name", "species_scientific_name"))
    assert_release(length(unique(x$host_group)) == 3L, "Expected three potential-host groups.")
  } else if (step == "05_fit_koel_weekly_opportunity") {
    path <- copy_reference("model_effects.csv")
    x <- read_csv_release(path, c("component", "term", "median", "q025", "q975"))
    assert_release(sum(x$component == "weekly_opportunity") == 9L, "Unexpected weekly-opportunity coefficient count.")
  } else if (step == "06_validate_scale_and_transfer") {
    path <- copy_reference("transfer_validation.csv")
    x <- read_csv_release(path, c("comparison", "estimate", "interval_low", "interval_high"))
    host <- x[x$comparison == "three_host_minus_no_host_coordinate_free", ]
    assert_release(nrow(host) == 1L && host$estimate > 0 && host$interval_low > 0, "Host-block transfer anchor failed.")
  } else if (step == "07_fit_joint_calling_density") {
    path <- copy_reference("model_effects.csv")
    x <- read_csv_release(path, c("component", "term", "median", "q025", "q975"))
    assert_release(sum(x$component == "positive_day_minute_probability") == 3L, "Calling-density coefficients are incomplete.")
    formula <- readLines(file.path(root, "config", "derived_metrics.txt"), warn = FALSE)
    assert_release(any(grepl("E = psi * p * mu_plus", formula, fixed = TRUE)), "Exposure contract is absent.")
  } else if (step == "08_predict_citywide_activity") {
    psi <- copy_reference("weekly_acoustic_opportunity.csv")
    exp <- copy_reference("weekly_acoustic_exposure.csv")
    assert_release(nrow(read_csv_release(psi)) == 52L && nrow(read_csv_release(exp)) == 52L, "Expected 52 annual weeks.")
  } else if (step == "09_classify_prediction_support") {
    path <- copy_reference("prediction_support_classes.csv")
    x <- read_csv_release(path, c("support_class", "n_hex", "percent_all_hex"))
    assert_release(sum(x$n_hex) == 13714L, "Prediction-support classes do not sum to 13,714.")
  } else if (step == "10_summarise_planning_overlap") {
    path <- copy_reference("planning_overlap.csv")
    x <- read_csv_release(path, c("group_type", "group_name", "planning_domain", "unit_total"))
    assert_release(all(x$planning_domain == "Primary Results + Moderate Extrapolation"), "Planning denominator drifted.")
  } else if (step == "11_design_adaptive_monitoring") {
    path <- copy_reference("adaptive_monitoring_sequences.csv")
    x <- read_csv_release(path, c("deployment_size", "route", "route_rank"))
    assert_release(identical(sort(unique(x$deployment_size)), c(5L, 10L, 15L)), "Deployment sizes must be 5, 10 and 15.")
  } else if (step == "12_make_manuscript_outputs") {
    module <- new.env(parent = environment())
    sys.source(file.path(root, "R", "make_verification_outputs.R"), envir = module)
    module$make_verification_outputs(root)
  } else if (step == "99_validate_release") {
    module <- new.env(parent = environment())
    sys.source(file.path(root, "R", "validate_release.R"), envir = module)
    module$validate_release(root)
  } else {
    abort_release(paste("Unknown public step:", step))
  }

  write_step_log(step, profile, "PASS")
  message(sprintf("[%s] %s PASS", profile, step))
  invisible(TRUE)
}
