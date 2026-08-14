# System requirements

## Public verification

- R 4.5 or later;
- GNU Make;
- a SHA-256 implementation (`sha256sum`, `shasum` or `openssl`);
- approximately 100 MB free disk space.

No contributed R package is required for `make smoke`, `make verify` or `make test`.

## Conditional full profile

The full Bayesian and spatial analysis additionally used CmdStan/Stan, `cmdstanr`, `posterior`, `loo`, `spOccupancy`, `sf`, `terra`, `exactextractr`, `data.table`, `dplyr`, `ggplot2`, `Matrix`, Python/Google Earth Engine tooling and licensed source assets. Exact versions, seeds and command-line settings must be recorded in the full-input manifest before a full result is accepted.

Full MCMC and city extraction are computationally expensive and are intentionally excluded from routine continuous integration.

