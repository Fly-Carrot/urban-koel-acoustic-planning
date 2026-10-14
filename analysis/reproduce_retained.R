# Recalculate released predictions and summaries without a new MCMC fit.
source("R/release_utils.R")
source("R/full_pipeline.R")
source("R/study_inputs.R")
source("R/reproduce_study.R")
require_package("matrixStats")
out <- full_output_dir("retained_reproduction")
parts <- read_retained_components()
args <- commandArgs(trailingOnly=TRUE)
if (length(args)==0L || "weekly" %in% args) reproduce_weekly_prediction(parts,out)
if (length(args)==0L || "planning" %in% args) reproduce_planning(parts,out)
if (length(args)==0L || "monitoring" %in% args) {
  settings <- read_table(file.path(study_input_dir(),"monitoring_settings.csv"))
  result <- rank_monitoring(parts$training,parts$city,
                           read_table(file.path(study_input_dir(),"monitoring_candidates.csv")),
                           read_table(file.path(study_input_dir(),"spacing_conflicts.csv")),
                           settings$value[settings$parameter=="minimum_spacing_m"])
  write_table(result$sequence,file.path(out,"monitoring_sequences.csv"))
  write_table(deployment_portfolios(result),file.path(out,"deployment_portfolios.csv"))
  for(route in c("environmental_learning","prediction_validation")){
    reference<-read_table(file.path(study_output_dir(),paste0(route,"_sequence.csv")))
    actual<-result$sequence[result$sequence$route==if(route=="environmental_learning")"Coverage Expansion" else "Prediction Validation",]
    stopifnot(identical(actual$cell_id,reference$cell_id),identical(actual$route_rank,reference$route_rank))
  }
}
cat("Retained-data calculations completed.\n")
