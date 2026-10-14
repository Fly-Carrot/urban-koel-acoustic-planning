root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(root, "CITATION.cff"))) stop("Run make setup from the repository root.", call. = FALSE)
dirs <- file.path(root, "outputs", c("diagnostics", "figures", "logs", "manifests", "tables"))
invisible(vapply(dirs, dir.create, logical(1), recursive = TRUE, showWarnings = FALSE))
packages <- c("data.table", "reformulas", "jsonlite", "matrixStats", "digest")
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly=TRUE)]
if (length(missing)) install.packages(missing, repos="https://cloud.r-project.org")
stopifnot(all(vapply(packages, requireNamespace, logical(1), quietly=TRUE)))
cat("Setup complete. Verification packages are available.\n")
cat("R:", R.version.string, "\n")

