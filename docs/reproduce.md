# Reproducing the analysis

## Check the public summaries

```bash
make setup
make verify
make test
```

This route uses the aggregate files in `data/processed/reference/` and writes its results to `outputs/`.

## Refit with approved inputs

1. Copy `config/full_data_manifest_example.csv` to `data/full/manifest.csv`.
2. Replace the example paths with local model-ready files.
3. Install the packages in `docs/system_requirements.md` and CmdStan.
4. Run `make full`.

The full route fits host and Koel models, scores complete held-station histories, fits daily and hourly density models, predicts city cell-weeks, classifies PID/AOA, summarises planning overlaps and ranks new monitoring sites. It retains the final calculation logic, without replaying every candidate fit. Model-ready tables must use the retained covariate scaling and matching host draw IDs. See [analysis_coverage.md](analysis_coverage.md) for the scope and [mcmc_settings.md](mcmc_settings.md) for sampling profiles.

Three complete sets of host posterior surfaces carry host uncertainty through three Koel refits. Predictive probabilities are pooled with equal weights. Three sets are a limited uncertainty-propagation analysis, not a stabilised large-M analysis.
