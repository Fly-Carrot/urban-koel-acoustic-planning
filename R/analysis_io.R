# Read model inputs, build design matrices and summarise posterior draws.

repo_root <- function() {
  here <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(here, "CITATION.cff")) && dir.exists(file.path(here, "analysis"))) return(here)
    parent <- dirname(here)
    if (identical(parent, here)) stop("Run the script from the repository folder.", call. = FALSE)
    here <- parent
  }
}

ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

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

read_input_files <- function() {
  path <- file.path(repo_root(), "data", "input_files.csv")
  if (!file.exists(path)) {
    stop("For a new dataset, copy data/input_files_example.csv to data/input_files.csv and fill in your file paths. To recalculate the published results, run analysis/reproduce_retained.R instead.", call. = FALSE)
  }
  files <- read_table(path, c("input", "path"))
  if (anyNA(files$input) || anyNA(files$path) || anyDuplicated(files$input)) {
    stop("Each input must have one name and one path in data/input_files.csv.", call. = FALSE)
  }
  as.data.frame(files)
}

input_file <- function(name, required = TRUE) {
  files <- read_input_files()
  row <- files[files$input == name, , drop = FALSE]
  if (!nrow(row)) {
    if (!required) return(NULL)
    stop("Add the input '", name, "' to data/input_files.csv.", call. = FALSE)
  }
  path <- row$path[[1]]
  if (!grepl("^(/|[A-Za-z]:[/\\\\])", path)) {
    path <- file.path(repo_root(), path)
  }
  if (!file.exists(path)) stop("Input file not found for '", name, "': ", path, call. = FALSE)
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

week_terms <- function(week) {
  data.frame(
    sin_week = sin(2 * pi * (week - 1) / 52),
    cos_week = cos(2 * pi * (week - 1) / 52)
  )
}

# Fitting uses the actual week-start date, not the display-week number.
dated_terms <- function(date) {
  phase <- 2 * pi * (as.integer(format(as.Date(date), "%j")) - 1) / 365.2425
  data.frame(sin_week = sin(phase), cos_week = cos(phase))
}

reporting_week <- function(date) {
  pmin(52L, (as.integer(format(as.Date(date), "%j")) - 1L) %/% 7L + 1L)
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
