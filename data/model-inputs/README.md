# Model-ready study inputs

Actual numerical inputs used by retained analyses, with private IDs replaced. These are not simulated data.

| Files | Content |
|---|---|
| `survey_history.csv`, `daily_counts.csv` | Recording effort, four group responses and Koel positive-minute counts |
| `calendar.csv`, `fitting_weeks.csv` | Survey dates and 68 study-week keys |
| `folds.csv` | Fixed whole-station validation folds |
| `station_predictors.csv`, `full_scaling.csv` | Seven environmental predictors and training scales |
| `occupancy/*.json.gz` | Full/fivefold host/H0/H4 arrays and standardised covariates |
| `daily/` | Retained HEQZ/S1 Stan inputs, design columns and row keys |
| `hourly_counts.csv`, `hourly/D1.json.gz` | Recorded positive-day hours and retained D1 design |
| `city_predictors.csv` | Predictors/reporting context for 13,714 anonymous cells |
| `planning_weights.csv` | Supported-cell POI counts or urban-function areas |
| Monitoring candidates, conflicts and settings | Priorities, spacing exclusions and selection settings |

The [manifest](manifest.csv) records file hashes and source basenames. [Running instructions](../../docs/reproduce.md) · [Field notes](../../docs/data_dictionary.md)

## Encoding

Occupancy arrays use `{dim, values}` in R column-major order: `array(values, dim=dim)`. JSON `null` is missing, not zero. `R/study_inputs.R` preserves station/week/day alignment. Stan JSON uses ordinary matrix rows.

The full array has 31 × 68 × 7 slots: 9,912 observed days and 4,844 missing slots; 2,682 Koel-positive days. Training/test files have disjoint station codes and the same week/day axes.

Identities and precise coordinates are withheld. Real dates/predictors make these de-identified rather than guaranteed unidentifiable. OSM-derived planning weights are ODbL 1.0; other project-owned processed inputs are CC BY 4.0. [Licences](../LICENSE.md)
