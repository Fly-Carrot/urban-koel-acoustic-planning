# Fit models and calculate predictions for your own prepared dataset.
# This includes long MCMC runs. For the published results, use reproduce_retained.R.
source("R/load.R")
read_input_files()
scripts <- sort(list.files("analysis", pattern = "^[0-9]{2}_.*[.]R$", full.names = TRUE))
for (script in scripts) {
  message(basename(script))
  source(script)
}
