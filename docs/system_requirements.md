# System requirements

## Public verification

- R 4.5 or later;
- GNU Make;
- `sha256sum`, `shasum` or `openssl`.

`make verify` and `make test` use base R.

## Full analysis

The model-fitting route uses:

- `data.table`;
- `spOccupancy`;
- `loo`;
- `reformulas`;
- `cmdstanr` and CmdStan;
- `posterior`.

The environmental and planning tables are supplied as model-ready CSV files because exact coordinates and several source layers cannot be redistributed. Full MCMC fitting and three-scale cross-validation can take many hours.
