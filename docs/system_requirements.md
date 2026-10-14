# System requirements

## Public verification

- R 4.5 or later;
- GNU Make;
- `sha256sum`, `shasum` or `openssl`.

`make verify` and the summary checks in `make test` use base R. The final-calculation tests also need `data.table` and `reformulas`; otherwise they are explicitly skipped.

## Full analysis

The model-fitting route uses:

- `data.table`;
- `spOccupancy`;
- `loo`;
- `reformulas`;
- `cmdstanr` and CmdStan;
- `posterior`.

The modelling functions read environmental and planning tables as CSV files. These model-ready study inputs are not supplied in the current public release. Full MCMC fitting and three-scale cross-validation can take many hours.

`renv.lock` records the R version but currently has an empty package list; it does not pin the complete package environment. Study package versions are listed in Supplementary Data 17. Installing current package versions may produce different results.
