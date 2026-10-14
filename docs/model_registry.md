# Model roles

| Model | Role in the study |
|---|---|
| H4 P0: three-host Koel model without coordinate trends, 250 m | Primary model for weekly opportunity, supported city mapping and planning summaries. |
| H0 Pxy: no-host model with projected coordinate trends | Predictive benchmark for broad spatial variation. |
| HEQZ: equal-scale host index and annual terms | Host-informed daily calling-density model. Its completed draws are combined with D1 hourly effects for city exposure. |
| Season-only daily density | Comparison model because the HEQZ transfer gain varied among folds. |
| D1: annual terms and two cyclic-hour harmonics | Retained hourly density model, fitted to recorded hours on positive days. |

H4 P0 improved the matched coordinate-free no-host comparison; it was not the numerical winner in every comparison. Model coefficients describe predictive acoustic associations.

Formulae are recorded in [config/model_registry.csv](../config/model_registry.csv). Supplementary Data 9–11 provide the study comparisons. See [code coverage](analysis_coverage.md) for the subset run by the public scripts.

