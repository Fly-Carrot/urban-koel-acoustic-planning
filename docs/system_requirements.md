# System requirements

Verification: R 4.5+, Python 3.10+, GNU Make, `data.table`, `reformulas`, `jsonlite`, `matrixStats` and `digest`. Python checks use the standard library. `make setup` installs missing verification packages from CRAN.

Refitting additionally needs `spOccupancy`, `cmdstanr`, CmdStan, `posterior` and `loo`. Install CmdStan with `cmdstanr::install_cmdstan()` after installing cmdstanr from its official repository. Full fits can take hours.

Calculations were checked on macOS/Apple Silicon. [Package versions](../config/package_versions.csv) record tested local versions, not a complete transitive dependency lock. The old empty `renv.lock` was removed to avoid implying it pinned the environment.
