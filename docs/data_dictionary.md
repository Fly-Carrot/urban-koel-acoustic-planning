# Data dictionary

## Frozen public reference products

| File | Unit | Core fields | Meaning |
|---|---|---|---|
| `survey_reconciliation.csv` | release check | `metric`, `value`, `expected`, `pass` | effort and response totals used by the fitted pipeline |
| `model_registry_public.csv` | model component | formula and role | public names and frozen formulas |
| `predictor_registry_public.csv` | predictor | likelihood layer and support | ecological, observation and reporting definitions |
| `host_groups.csv` | species | group and scientific name | exact membership of three potential-host responses |
| `model_effects.csv` | coefficient | median and 95% CrI | reported `psi`, `p` and `mu_plus` effects |
| `transfer_validation.csv` | comparison | estimate, interval and diagnostics | held-station and multiscale evidence |
| `weekly_acoustic_opportunity.csv` | annual week | spatial quantiles and mean | `psi` across the centroid-in-city mapping subset |
| `weekly_acoustic_exposure.csv` | annual week | spatial quantiles and mean | all-day `E` across the same subset |
| `prediction_support_classes.csv` | support class | HEX count and percentage | PID × AOA cross-classification |
| `planning_overlap.csv` | mapped context class | counts/area and posterior summaries | functional-zone and POI summaries |
| `adaptive_monitoring_sequences.csv` | anonymised route rank | gains, uncertainty and inclusion | nested 5/10/15 deployment scenarios without coordinates |

## Symbols

| Public field | Definition |
|---|---|
| `psi` | detection-corrected weekly acoustic opportunity |
| `p` | conditional daily detectability |
| `mu_plus` | positive-day sampled-minute probability |
| `E` | sampled-minute acoustic exposure, `psi * p * mu_plus` |
| `q025`, `q975` | lower and upper limits of a 95% Bayesian credible interval |
| `ELPD` | expected log predictive density for complete held-station histories |
| `PID` | Prediction Interpretation Domain, an ecological reporting label |
| `AOA` | Area of Applicability, a monitored predictor-space support label |

Percent columns are stored on a 0–100 scale; probability columns are stored on a 0–1 scale. Missing values are empty CSV fields, never coded as zero.

