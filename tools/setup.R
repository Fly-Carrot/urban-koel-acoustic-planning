root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(root, "CITATION.cff"))) stop("Run make setup from the repository root.", call. = FALSE)
dirs <- file.path(root, "outputs", c("diagnostics", "figures", "logs", "manifests", "tables"))
invisible(vapply(dirs, dir.create, logical(1), recursive = TRUE, showWarnings = FALSE))
cat("Setup complete. The public verification profile uses base R only.\n")
cat("R:", R.version.string, "\n")

