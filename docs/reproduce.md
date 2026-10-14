# Running the code

## Check the public summaries

```bash
make setup
make verify
make test
```

`make verify` reads aggregate files in `data/processed/reference/`, checks reported totals and writes summary copies and plots to `outputs/`. It does not estimate new model parameters. `make test` checks calculations using small examples; missing optional test packages are reported.

## Run the modelling functions

1. Read [current code coverage](analysis_coverage.md). Several details differ from the retained study analysis.
2. Prepare compatible inputs using the [data dictionary](data_dictionary.md).
3. Copy `config/full_data_manifest_example.csv` to `data/full/manifest.csv` and enter your local input paths.
4. Install the [required packages](system_requirements.md) and CmdStan.
5. Run `make full`.

Results go to `outputs/full/`. See [notes for each script](script_reference.md) for inputs and outputs and [sampling settings](mcmc_settings.md) for MCMC settings.

Three sets of host posterior surfaces enter three separate Koel fits. Each set contributes equally to predictions. These are three uncertainty-propagation sets, not three MCMC chains.

The model-ready study inputs are not included. Successful execution with new inputs would not, by itself, reproduce the paper's estimates.
