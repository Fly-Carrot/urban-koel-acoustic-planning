source(file.path("R", "release_utils.R"))
root <- repo_root()

expected_drivers <- c(
  "00_preflight.R", "01_prepare_survey_histories.R", "02_select_detection_backbone.R",
  "03_build_environmental_predictors.R", "04_fit_potential_host_opportunity.R",
  "05_fit_koel_weekly_opportunity.R", "06_validate_scale_and_transfer.R",
  "07_fit_joint_calling_density.R", "08_predict_citywide_activity.R",
  "09_classify_prediction_support.R", "10_summarise_planning_overlap.R",
  "11_design_adaptive_monitoring.R", "12_make_manuscript_outputs.R", "99_validate_release.R"
)
actual_drivers <- sort(list.files(file.path(root, "analysis"), pattern = "^[0-9]{2}_.+\\.R$"))
assert_release(identical(sort(expected_drivers), actual_drivers),
               paste("Expected exactly 14 public drivers; found", length(actual_drivers)))

git_available <- nzchar(Sys.which("git")) && dir.exists(file.path(root, ".git"))
if (git_available) {
  relative_files <- system2("git", c("-C", root, "ls-files"), stdout = TRUE)
  relative_files <- relative_files[nzchar(relative_files)]
} else {
  absolute_files <- list.files(root, recursive = TRUE, all.files = TRUE, full.names = TRUE,
                               include.dirs = FALSE, no.. = TRUE)
  relative_files <- substring(normalizePath(absolute_files, winslash = "/", mustWork = FALSE), nchar(root) + 2L)
  relative_files <- relative_files[!grepl("^(\\.git/|outputs/)", relative_files)]
}
relative_files <- sort(unique(relative_files))
absolute_files <- file.path(root, relative_files)
assert_release(length(relative_files) > 0L, "No release files were found.")
assert_release(!any(file.info(absolute_files)$isdir), "Directory entries entered the file contract.")
assert_release(!any(file.info(absolute_files)$size >= 50 * 1024^2), "A release file is 50 MB or larger.")

binary_extensions <- paste0(
  "\\.(wav|flac|mp3|m4a|aac|aif|aiff|opus|tif|tiff|gpkg|kml|kmz|pbf|shp|dbf|shx|",
  "geojson|rds|rda|rdata|qs|fst|docx|pptx|xlsx|xls|pdf|png|stan\\.csv)$"
)
allowed_supplementary_binaries <- c(
  "supplementary-materials/supplementary-information/Supplementary_Information.pdf",
  sprintf("supplementary-materials/tables/Table_S%02d.xlsx", 1:17),
  sprintf("supplementary-materials/figures/Figure_S%02d.pdf", 1:10),
  sprintf("supplementary-materials/figures/previews/Figure_S%02d.png", 1:10)
)
tracked_binaries <- relative_files[grepl(binary_extensions, relative_files, ignore.case = TRUE)]
assert_release(setequal(tracked_binaries, allowed_supplementary_binaries),
               "Tracked binary assets differ from the explicit supplementary-material allowlist.")
assert_release(!any(grepl("^(data/(raw|full|private)/|archive/|materials/|tmp/|\\.agent-os/|\\.agents/)", relative_files)),
               "A private or workspace-management path is tracked.")

text_extensions <- "\\.(R|py|md|csv|tsv|yml|yaml|json|cff|txt|stan|svg|lock|gitignore)$"
text_files <- relative_files[grepl(text_extensions, relative_files, ignore.case = TRUE) |
                               basename(relative_files) %in% c("Makefile", "LICENSE", ".gitignore")]
# This scanner necessarily contains the patterns it searches for; exclude only its own source.
scan_files <- setdiff(text_files, c("tools/validate_contract.R", "tools/validate_supplementary_assets.py"))
read_text <- function(path) paste(readLines(file.path(root, path), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
texts <- setNames(lapply(scan_files, read_text), scan_files)
has_match <- function(pattern, perl = TRUE, ignore.case = FALSE) {
  hits <- vapply(texts, function(x) grepl(pattern, x, perl = perl, ignore.case = ignore.case), logical(1))
  names(hits)[hits]
}

absolute_hits <- has_match("/Users/[^/[:space:]]+/|/Volumes/[^/[:space:]]+/|[A-Za-z]:\\\\Users\\\\")
assert_release(length(absolute_hits) == 0L, paste("Absolute workstation path in:", paste(absolute_hits, collapse = ", ")))

secret_pattern <- paste(
  "AKIA[0-9A-Z]{16}",
  "ASIA[0-9A-Z]{16}",
  "gh[pousr]_[A-Za-z0-9_]{30,}",
  "github_pat_[A-Za-z0-9_]{50,}",
  "sk-[A-Za-z0-9]{32,}",
  "AIza[0-9A-Za-z_-]{35}",
  "xox[baprs]-[0-9A-Za-z-]{20,}",
  "-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----",
  "\\\"private_key\\\"[[:space:]]*:[[:space:]]*\\\"-----BEGIN",
  sep = "|"
)
secret_hits <- has_match(secret_pattern)
assert_release(length(secret_hits) == 0L, paste("Credential-like value in:", paste(secret_hits, collapse = ", ")))

csv_files <- relative_files[grepl("\\.csv$", relative_files, ignore.case = TRUE)]
coordinate_columns <- c("latitude", "longitude", "lat", "lon", "lng", "x_4547", "y_4547",
                        "coordinate", "coordinates", "geometry", "wkt", "site_x", "site_y")
coordinate_hits <- character()
for (path in csv_files) {
  header <- strsplit(readLines(file.path(root, path), n = 1L, warn = FALSE), ",", fixed = TRUE)[[1]]
  header <- tolower(gsub('^"|"$', "", trimws(header)))
  if (any(header %in% coordinate_columns)) coordinate_hits <- c(coordinate_hits, path)
}
assert_release(length(coordinate_hits) == 0L,
               paste("Exact-coordinate schema in:", paste(coordinate_hits, collapse = ", ")))

docs <- readLines(file.path(root, "docs", "script_reference.md"), warn = FALSE)
for (driver in sub("\\.R$", "", expected_drivers)) {
  assert_release(any(grepl(paste0("^## `", driver, "`$"), docs)), paste("Missing script card for", driver))
}

required_registries <- c("model_registry.csv", "predictor_registry.csv", "seed_registry.csv",
                         "decision_thresholds.csv", "provenance_registry.csv", "derived_metrics.txt")
assert_release(all(file.exists(file.path(root, "config", required_registries))), "A required configuration registry is absent.")

reference_dir <- file.path(root, "data", "processed", "reference")
required_reference <- c("survey_reconciliation.csv", "model_registry_public.csv", "predictor_registry_public.csv",
                        "host_groups.csv", "model_effects.csv", "transfer_validation.csv",
                        "weekly_acoustic_opportunity.csv", "weekly_acoustic_exposure.csv",
                        "prediction_support_classes.csv", "planning_overlap.csv", "adaptive_monitoring_sequences.csv")
assert_release(all(file.exists(file.path(reference_dir, required_reference))), "Reference products are incomplete.")

manifest_path <- file.path(root, "data", "manifests", "reference_products.csv")
manifest <- read_csv_release(manifest_path, c("path", "role", "sha256", "size_bytes", "owner", "source", "version",
                                             "spdx", "redistribution", "attribution", "privacy_class",
                                             "coordinate_precision", "approval_reference"))
expected_manifest_paths <- file.path("data", "processed", "reference", required_reference)
assert_release(setequal(manifest$path, expected_manifest_paths), "Reference manifest does not match the required public products.")
for (i in seq_len(nrow(manifest))) {
  path <- file.path(root, manifest$path[[i]])
  assert_release(file.exists(path), paste("Manifest path is missing:", manifest$path[[i]]))
  assert_release(identical(tolower(sha256_file(path)), tolower(manifest$sha256[[i]])),
                 paste("Manifest checksum changed:", manifest$path[[i]]))
  assert_release(as.numeric(file.info(path)$size) == as.numeric(manifest$size_bytes[[i]]),
                 paste("Manifest size changed:", manifest$path[[i]]))
  assert_release(manifest$coordinate_precision[[i]] == "not_applicable_no_coordinates",
                 paste("Coordinate declaration changed:", manifest$path[[i]]))
}

if (git_available) {
  emails <- system2("git", c("-C", root, "log", "--format=%ae"), stdout = TRUE, stderr = FALSE)
  if (length(emails)) {
    assert_release(!any(grepl("(@[^ ]*\\.local$|@localhost$)", emails, ignore.case = TRUE)),
                   "Git history contains a local-machine author email.")
  }
}

supplementary_log <- tempfile("supplementary-contract-", fileext = ".log")
supplementary_status <- system2(
  "python3",
  c("tools/validate_supplementary_assets.py"),
  stdout = supplementary_log,
  stderr = supplementary_log
)
if (!identical(supplementary_status, 0L)) {
  cat(readLines(supplementary_log, warn = FALSE), sep = "\n")
  stop("Supplementary-material contract failed.", call. = FALSE)
}
cat(readLines(supplementary_log, warn = FALSE), sep = "\n")

cat(sprintf(
  "Release contract PASS: %d tracked files, 14 drivers, 11 checksummed reference products and 38 supplementary assets; no exact-coordinate schema, prohibited payload, local path or credential signature.\n",
  length(relative_files)
))
