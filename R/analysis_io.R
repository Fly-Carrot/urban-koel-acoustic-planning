# Read model inputs, build design matrices and summarise posterior draws.

require_package <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("Install the R package '", package, "' to run the full analysis.", call. = FALSE)
  }
}

full_output_dir <- function(step = NULL) {
  path <- file.path(repo_root(), "outputs", "full")
  if (!is.null(step)) path <- file.path(path, step)
  ensure_dir(path)
}

read_full_manifest <- function() {
  path <- file.path(repo_root(), "data", "full", "manifest.csv")
  manifest <- read_csv_release(path, c("asset_id", "path"))
  if (anyDuplicated(manifest$asset_id)) {
    stop("Each asset_id in data/full/manifest.csv must be unique.", call. = FALSE)
  }
  manifest
}

full_asset <- function(asset_id, required = TRUE) {
  manifest <- read_full_manifest()
  row <- manifest[manifest$asset_id == asset_id, , drop = FALSE]
  if (!nrow(row)) {
    if (!required) return(NULL)
    stop("The full-data manifest is missing asset_id: ", asset_id, call. = FALSE)
  }
  path <- row$path[[1]]
  if (!grepl("^(/|[A-Za-z]:[/\\\\])", path)) {
    path <- file.path(repo_root(), path)
  }
  if (!file.exists(path)) stop("Full-data asset is missing: ", asset_id, call. = FALSE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

read_table <- function(path, required = character()) {
  require_package("data.table")
  x <- data.table::fread(path)
  missing <- setdiff(required, names(x))
  if (length(missing)) {
    stop("Missing columns in ", basename(path), ": ", paste(missing, collapse = ", "), call. = FALSE)
  }
  x
}

write_table <- function(x, path) {
  require_package("data.table")
  ensure_dir(dirname(path))
  data.table::fwrite(data.table::as.data.table(x), path, na = "NA")
  invisible(path)
}

read_rds_asset <- function(asset_id) readRDS(full_asset(asset_id))

week_terms <- function(week) {
  data.frame(
    sin_week = sin(2 * pi * (week - 1) / 52),
    cos_week = cos(2 * pi * (week - 1) / 52)
  )
}

z_scale <- function(x, centre = NULL, scale = NULL) {
  if (is.null(centre)) centre <- mean(x, na.rm = TRUE)
  if (is.null(scale)) scale <- stats::sd(x, na.rm = TRUE)
  if (!is.finite(scale) || scale <= 0) stop("Cannot standardise a constant variable.", call. = FALSE)
  list(value = (x - centre) / scale, centre = centre, scale = scale)
}

formula_terms <- function(formula) {
  setdiff(all.vars(stats::delete.response(stats::terms(formula))), c("site_id", "site_re"))
}

fixed_design <- function(covariates, formula) {
  model_formula <- stats::as.formula(paste("~", paste(deparse(formula[[length(formula)]]), collapse = " ")))
  stats::model.matrix(model_formula, data = covariates)
}

fit_summary <- function(draws, component, model_id) {
  draws <- as.matrix(draws)
  data.frame(
    component = component,
    model_id = model_id,
    term = colnames(draws),
    mean = colMeans(draws),
    sd = apply(draws, 2, stats::sd),
    median = apply(draws, 2, stats::median),
    q025 = apply(draws, 2, stats::quantile, 0.025),
    q975 = apply(draws, 2, stats::quantile, 0.975),
    row.names = NULL
  )
}

log_mean_exp <- function(x) {
  m <- max(x)
  m + log(mean(exp(x - m)))
}

check_probability <- function(x, name) {
  if (any(!is.finite(x) | x < 0 | x > 1)) {
    stop(name, " contains values outside [0, 1].", call. = FALSE)
  }
  invisible(x)
}
