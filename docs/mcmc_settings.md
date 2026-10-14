# Sampling settings

Settings follow Supplementary Data 17, Table S17B. Occupancy iterations are counted per chain before burn-in and thinning.

| Fit | Chains | Iterations per chain | Burn-in | Thin | Pooled retained draws |
|---|---:|---:|---:|---:|---:|
| Full-data Koel, corvid and laughingthrush | 4 | 30,000 | 10,000 | 20 | 4,000 per fit |
| Retained sturnid refit | 4 | 60,000 | 20,000 | 20 | 8,000 |
| Whole-station host and Koel validation | 4 | 60,000 | 20,000 | 20 | 8,000 per fit |
| Formal detection-backbone comparison | 4 | 50,000 | 20,000 | 20 | 6,000 per fit |

`full_mcmc_settings()` uses 30,000 iterations by default. Detection comparison, sturnid fitting and whole-station validation use the settings above. Each of the three host posterior sets has a separate Koel fit; these sets are not MCMC chains.

The daily host-informed Stan model uses four chains with 750 warm-up and 750 sampling iterations per chain. Hourly models use four chains with 1,000 warm-up and 1,000 sampling iterations. Both use `adapt_delta = 0.95` and `max_treedepth = 12`.

The public scripts set seeds for a fresh run. Published estimates are retained in `data/processed/reference/`; see [code coverage](analysis_coverage.md) for differences between the public functions and the study analysis.
