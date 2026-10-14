# Example: Rscript analysis/fit_released_input.R full_HEQZ_M01
source("R/release_utils.R")
source("R/full_pipeline.R")
source("R/study_inputs.R")
args <- commandArgs(trailingOnly=TRUE)
if (length(args) != 1L) stop("Supply one released input name, e.g. full_H4_M01, full_HEQZ_M01 or D1.")
fit_released_input(args[1])
