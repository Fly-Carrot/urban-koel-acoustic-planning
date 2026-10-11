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

The full route fits host and Koel occupancy models, runs held-station validation examples, fits Stan density models, predicts city cell-weeks, classifies PID/AOA, summarises planning overlaps and ranks new monitoring sites. It is a selected-workflow implementation, not an exact replay of all archived fits. See [analysis_coverage.md](analysis_coverage.md) for the remaining differences and [mcmc_settings.md](mcmc_settings.md) for sampling profiles.

The three host posterior surfaces are independent complete draws. They test whether the transfer result depends on one host estimate; they do not represent a large multiple-imputation analysis.
