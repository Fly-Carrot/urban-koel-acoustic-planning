# Read the released, de-identified inputs used by the retained models.
study_input_dir <- function() file.path(repo_root(), "data", "model-inputs")
study_output_dir <- function() file.path(repo_root(), "results", "posterior_draws")

read_json_gz <- function(path) {
  require_package("jsonlite")
  con <- gzfile(path, "rt")
  on.exit(close(con))
  jsonlite::fromJSON(paste(readLines(con, warn = FALSE), collapse = "\n"))
}

read_occupancy_input <- function(name) {
  x <- read_json_gz(file.path(study_input_dir(), "occupancy", paste0(name, ".json.gz")))
  decode <- function(a) array(a$values, dim = a$dim)
  y <- decode(x$y)
  dimnames(y) <- list(x$station_id, as.character(seq_len(dim(y)[2])), as.character(seq_len(dim(y)[3])))
  occ <- lapply(x$occurrence, decode); det <- lapply(x$detection, decode)
  for (v in names(occ)) dimnames(occ[[v]]) <- dimnames(y)[1:2]
  for (v in names(det)) dimnames(det[[v]]) <- dimnames(y)
  aliases <- c(corvid_assemblage_host_psi_z="corvid_host_psi_z",
               sturnid_assemblage_host_psi_z="sturnid_host_psi_z",
               black_faced_laughingthrush_host_psi_z="laughingthrush_host_psi_z")
  for (v in intersect(names(occ), names(aliases))) names(occ)[names(occ) == v] <- aliases[[v]]
  list(data=list(y=y, occ.covs=occ, det.covs=det), seed=x$seed, settings=x$settings)
}

released_occurrence_formula <- function(name) {
  if (grepl("H4", name)) return(koel_three_host_formula())
  if (grepl("H0", name)) return(koel_no_host_formula())
  role <- if (grepl("corvid", name)) "corvid" else if (grepl("sturnid", name)) "sturnid" else "laughingthrush"
  host_formulas()[[role]]
}

fit_released_input <- function(name) {
  out <- full_output_dir("released_fits")
  if (file.exists(file.path(study_input_dir(), "occupancy", paste0(name, ".json.gz")))) {
    if (grepl("_test$", name)) stop("Use training inputs for fitting and test inputs only for scoring.", call.=FALSE)
    x <- read_occupancy_input(name)
    if (!is.finite(x$seed)) stop("This input has no verified fitting seed.", call.=FALSE)
    fit <- fit_tpg_model(x$data, released_occurrence_formula(name), primary_detection_formula(),
                         x$seed, settings=full_mcmc_settings(x$settings))
    saveRDS(fit, file.path(out, paste0(name, ".rds")))
    return(invisible(fit))
  }
  profile <- if (name == "D1") "hourly" else "daily"
  branch <- if (profile == "hourly") "hourly" else "daily"
  dat <- read_json_gz(file.path(study_input_dir(), branch, paste0(name, ".json.gz")))
  # The release contains the already-standardised, retained design matrices.
  if (name == "D1") {
    seed <- 470127L; stan <- "470_conditional_hourly_density.stan"
  } else {
    model <- if (grepl("HEQZ", name)) "HEQZ" else "S1"
    m <- as.integer(sub(".*_M([0-9]{2}).*", "\\1", name))
    fold <- if (grepl("^fold", name)) as.integer(sub("^fold([0-9]{2}).*", "\\1", name)) else 0L
    if (grepl("_test$", name)) stop("Do not fit a withheld-station input.", call.=FALSE)
    if (model == "S1" && fold == 0L) stop("Full-data S1 is a comparison input; its original seed is not verified here.", call.=FALSE)
    seed <- 464026L + fold * 10000L + m * 100L + match(model,c("S1","HEQZ"))
    stan <- "463_joint_intensity_host_season_compare.stan"
  }
  chain_dir <- file.path(out, paste0(name, "_chains")); ensure_dir(chain_dir)
  fit <- fit_cmdstan_model(file.path(repo_root(), "stan", stan), dat, chain_dir, seed, profile)
  fit$save_object(file.path(out, paste0(name, ".rds")))
  invisible(fit)
}
